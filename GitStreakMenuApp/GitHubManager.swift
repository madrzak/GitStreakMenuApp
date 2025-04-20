//
//  GitHubManager.swift
//  GitStreakMenuApp
//
//  Created by Lukasz Madrzak on 20/04/2025.
//

import Foundation

class GitHubManager {
    private var username: String?
    private var token: String?
    
    enum GitHubError: Error {
        case noUsernameSet
        case networkError
        case parsingError
        case authenticationError
        case rateLimitExceeded
        case unknownError
        
        var localizedDescription: String {
            switch self {
            case .noUsernameSet:
                return "No GitHub username set. Please set a username in Settings."
            case .networkError:
                return "Could not connect to GitHub. Check your internet connection."
            case .parsingError:
                return "Error parsing GitHub data."
            case .authenticationError:
                return "Authentication error. Check your GitHub token."
            case .rateLimitExceeded:
                return "GitHub API rate limit exceeded. Try again later."
            case .unknownError:
                return "An unknown error occurred."
            }
        }
    }
    
    init() {
        // Try to load credentials from UserDefaults
        self.username = UserDefaults.standard.string(forKey: "GitHubUsername")
        self.token = UserDefaults.standard.string(forKey: "GitHubToken")
    }
    
    func setCredentials(username: String, token: String?) {
        self.username = username
        self.token = token
        
        // Save credentials to UserDefaults
        UserDefaults.standard.set(username, forKey: "GitHubUsername")
        if let token = token {
            UserDefaults.standard.set(token, forKey: "GitHubToken")
        } else {
            UserDefaults.standard.removeObject(forKey: "GitHubToken")
        }
    }
    
    func fetchCurrentStreak(completion: @escaping (Int?, Error?) -> Void) {
        guard let username = self.username else {
            completion(nil, GitHubError.noUsernameSet)
            return
        }
        
        // For this demo, we'll use the GitHub GraphQL API to fetch contributions
        let url = URL(string: "https://api.github.com/graphql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add token if available
        if let token = self.token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Set content type
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Define the GraphQL query to fetch user's contribution data
        let graphQLQuery = """
        {
          "query": "query { user(login: \\"\\(username)\\") { contributionsCollection { contributionCalendar { weeks { contributionDays { date contributionCount } } } } } }"
        }
        """
        
        request.httpBody = graphQLQuery.data(using: .utf8)
        
        // Create data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, GitHubError.networkError)
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil, GitHubError.networkError)
                return
            }
            
            // Check response status code
            switch httpResponse.statusCode {
            case 200:
                guard let data = data else {
                    completion(nil, GitHubError.parsingError)
                    return
                }
                
                do {
                    // Parse the JSON response
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let data = json["data"] as? [String: Any],
                       let user = data["user"] as? [String: Any],
                       let contributionsCollection = user["contributionsCollection"] as? [String: Any],
                       let contributionCalendar = contributionsCollection["contributionCalendar"] as? [String: Any],
                       let weeks = contributionCalendar["weeks"] as? [[String: Any]] {
                        
                        let streak = self.calculateStreak(from: weeks)
                        completion(streak, nil)
                    } else {
                        completion(nil, GitHubError.parsingError)
                    }
                } catch {
                    completion(nil, GitHubError.parsingError)
                    print("JSON parsing error: \(error.localizedDescription)")
                }
                
            case 401:
                completion(nil, GitHubError.authenticationError)
                
            case 403:
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? String,
                   message.contains("rate limit") {
                    completion(nil, GitHubError.rateLimitExceeded)
                } else {
                    completion(nil, GitHubError.authenticationError)
                }
                
            default:
                completion(nil, GitHubError.unknownError)
                if let data = data, let str = String(data: data, encoding: .utf8) {
                    print("Unexpected response: \(httpResponse.statusCode), Body: \(str)")
                }
            }
        }
        
        task.resume()
    }
    
    private func calculateStreak(from weeks: [[String: Any]]) -> Int {
        var streak = 0
        var allDays: [(date: Date, count: Int)] = []
        
        // Step 1: Collect all contribution days and sort them by date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for week in weeks {
            if let days = week["contributionDays"] as? [[String: Any]] {
                for day in days {
                    if let dateString = day["date"] as? String,
                       let date = dateFormatter.date(from: dateString),
                       let count = day["contributionCount"] as? Int {
                        allDays.append((date: date, count: count))
                    }
                }
            }
        }
        
        // Sort days from newest to oldest
        allDays.sort { $0.date > $1.date }
        
        // Step 2: Calculate current streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if the first day is today or yesterday (to account for timezone differences)
        if let firstDay = allDays.first {
            let dayDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstDay.date), to: today).day ?? 0
            if dayDifference > 1 {
                // Check if the day is more than 1 day away from today, which means no recent contributions
                return 0
            }
        }
        
        // Count consecutive days with contributions
        for day in allDays {
            if day.count > 0 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
} 