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
    
    // Display format options
    enum DisplayFormat: String, CaseIterable, Identifiable {
        case emoji = "🔥 %d"
        case days = "%d days"
        case justNumber = "%d"
        case fire = "🔥%d"
        case streak = "Streak: %d"
        case custom = ""
        
        var id: String { self.rawValue }
        
        var description: String {
            switch self {
            case .emoji: return "🔥 3"
            case .days: return "3 days"
            case .justNumber: return "3"
            case .fire: return "🔥3"
            case .streak: return "Streak: 3"
            case .custom: return "Custom..."
            }
        }
        
        static func fromRawValue(_ rawValue: String) -> DisplayFormat {
            return self.allCases.first(where: { $0.rawValue == rawValue }) ?? .emoji
        }
    }
    
    var displayFormat: DisplayFormat = .emoji
    var customFormat: String = ""
    
    // Add properties to store total commits and longest streak
    private var totalCommits: Int = 0
    private var longestStreak: Int = 0
    private var currentStreak: Int = 0
    
    enum GitHubError: Error {
        case noUsernameSet
        case networkError
        case parsingError
        case authenticationError
        case rateLimitExceeded
        case userNotFound
        case unknownError
        
        var localizedDescription: String {
            switch self {
            case .noUsernameSet:
                return "No GitHub username set. Please set a username in Settings."
            case .networkError:
                return "Network connection error. If you're seeing this after a fresh install, you may need to restart the app to apply network permissions."
            case .parsingError:
                return "Error processing GitHub data. Please check your username and try again."
            case .authenticationError:
                return "Authentication error. Check your GitHub token."
            case .rateLimitExceeded:
                return "GitHub API rate limit exceeded. Try again later."
            case .userNotFound:
                return "GitHub username not found. Please check the username in Settings."
            case .unknownError:
                return "An unknown error occurred."
            }
        }
    }
    
    init() {
        // Load credentials directly from UserDefaults
        loadCredentials()
        loadDisplaySettings()
    }
    
    private func loadCredentials() {
        self.username = UserDefaults.standard.string(forKey: "GitHubUsername")
        self.token = UserDefaults.standard.string(forKey: "GitHubToken")
        
        print("Loaded credentials - Username: \(self.username ?? "none"), Token: \(self.token != nil ? "exists" : "none")")
    }
    
    private func loadDisplaySettings() {
        if let formatString = UserDefaults.standard.string(forKey: "DisplayFormat") {
            self.displayFormat = DisplayFormat.fromRawValue(formatString)
        }
        
        self.customFormat = UserDefaults.standard.string(forKey: "CustomFormat") ?? ""
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
        UserDefaults.standard.synchronize()
        
        print("Saved credentials - Username: \(username), Token: \(token != nil ? "exists" : "none")")
    }
    
    func setDisplayFormat(_ format: DisplayFormat, customFormat: String = "") {
        self.displayFormat = format
        
        // Only update custom format if it's not empty or if we're using custom format
        if !customFormat.isEmpty || format == .custom {
            self.customFormat = customFormat
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(format.rawValue, forKey: "DisplayFormat")
        UserDefaults.standard.set(self.customFormat, forKey: "CustomFormat")
        UserDefaults.standard.synchronize()
    }
    
    func formatStreak(_ count: Int) -> String {
        // Store current streak for later use
        self.currentStreak = count
        
        if displayFormat == .custom && !customFormat.isEmpty {
            // For custom format, replace all placeholders
            var formattedString = customFormat
            formattedString = formattedString.replacingOccurrences(of: "%d", with: "\(currentStreak)")
            formattedString = formattedString.replacingOccurrences(of: "%l", with: "\(longestStreak)")
            formattedString = formattedString.replacingOccurrences(of: "%t", with: "\(totalCommits)")
            return formattedString
        } else {
            // For predefined formats, use the raw value format string
            return String(format: displayFormat.rawValue, count)
        }
    }
    
    func fetchCurrentStreak(completion: @escaping (Int?, Error?) -> Void) {
        // Reload credentials to ensure we have the latest
        loadCredentials()
        
        guard let username = self.username, !username.isEmpty else {
            completion(nil, GitHubError.noUsernameSet)
            return
        }
        
        print("Fetching streak for user: \(username)")
        
        // For this demo, we'll use the GitHub GraphQL API to fetch contributions
        let url = URL(string: "https://api.github.com/graphql")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add token if available
        if let token = self.token, !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("Using token for authentication")
        }
        
        // Set content type
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Define the GraphQL query to fetch user's contribution data
        // The proper format requires escaping quotes in the query string
        let query = """
        query {
          user(login: "\(username)") {
            contributionsCollection {
              contributionCalendar {
                weeks {
                  contributionDays {
                    date
                    contributionCount
                  }
                }
              }
            }
          }
        }
        """
        
        let jsonBody: [String: Any] = ["query": query]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
            request.httpBody = jsonData
            
            // Print the actual JSON being sent for debugging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Sending GraphQL request: \(jsonString)")
            }
            
            // Create data task
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    completion(nil, GitHubError.networkError)
                    print("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(nil, GitHubError.networkError)
                    return
                }
                
                print("GitHub API response: \(httpResponse.statusCode)")
                
                // Check response status code
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data else {
                        completion(nil, GitHubError.parsingError)
                        return
                    }
                    
                    // Debug: Print JSON response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("GitHub API response data: \(jsonString)")
                    }
                    
                    do {
                        // Parse the JSON response
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            // Check for errors in the response
                            if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
                                if let message = errors[0]["message"] as? String {
                                    if message.contains("Could not resolve to a User") {
                                        completion(nil, GitHubError.userNotFound)
                                    } else {
                                        completion(nil, GitHubError.parsingError)
                                    }
                                    print("GraphQL error: \(message)")
                                } else {
                                    completion(nil, GitHubError.parsingError)
                                }
                                return
                            }
                            
                            if let data = json["data"] as? [String: Any],
                               let user = data["user"] as? [String: Any],
                               let contributionsCollection = user["contributionsCollection"] as? [String: Any],
                               let contributionCalendar = contributionsCollection["contributionCalendar"] as? [String: Any],
                               let weeks = contributionCalendar["weeks"] as? [[String: Any]] {
                                
                                // Calculate current streak, longest streak, and total commits
                                let (streak, longest, total) = self.calculateStreakStats(from: weeks)
                                self.currentStreak = streak
                                self.longestStreak = longest
                                self.totalCommits = total
                                
                                print("Calculated stats - Current streak: \(streak), Longest streak: \(longest), Total commits: \(total)")
                                completion(streak, nil)
                            } else {
                                // User data might be nil if the user doesn't exist
                                if let data = json["data"] as? [String: Any], data["user"] == nil {
                                    completion(nil, GitHubError.userNotFound)
                                } else {
                                    completion(nil, GitHubError.parsingError)
                                }
                            }
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
                       let message = json["message"] as? String {
                        if message.contains("rate limit") {
                            completion(nil, GitHubError.rateLimitExceeded)
                        } else {
                            completion(nil, GitHubError.authenticationError)
                        }
                        print("GitHub API error (403): \(message)")
                    } else {
                        completion(nil, GitHubError.authenticationError)
                    }
                    
                case 400:
                    if let data = data, let str = String(data: data, encoding: .utf8) {
                        print("Bad request (400): \(str)")
                    }
                    completion(nil, GitHubError.parsingError)
                    
                default:
                    completion(nil, GitHubError.unknownError)
                    if let data = data, let str = String(data: data, encoding: .utf8) {
                        print("Unexpected response: \(httpResponse.statusCode), Body: \(str)")
                    }
                }
            }
            
            task.resume()
        } catch {
            print("Error creating request: \(error.localizedDescription)")
            completion(nil, GitHubError.parsingError)
        }
    }
    
    private func calculateStreakStats(from weeks: [[String: Any]]) -> (currentStreak: Int, longestStreak: Int, totalCommits: Int) {
        var currentStreak = 0
        var longestStreak = 0
        var totalCommits = 0
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
                        totalCommits += count
                    }
                }
            }
        }
        
        // Sort days from newest to oldest
        allDays.sort { $0.date > $1.date }
        
        // Step 2: Calculate current streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Get the most recent day with data
        guard let firstDay = allDays.first else {
            return (0, 0, 0)
        }
        
        let dayDifference = calendar.dateComponents([.day], from: calendar.startOfDay(for: firstDay.date), to: today).day ?? 0
        
        // If the most recent day is more than 2 days ago, there's no streak
        // This allows for 0 days (today) or 1 day (yesterday) difference
        if dayDifference > 1 {
            // No current streak, but still calculate longest streak
            longestStreak = calculateLongestStreak(from: allDays)
            return (0, longestStreak, totalCommits)
        }
        
        // Check if today has a contribution
        let todayHasContribution = allDays.first?.date == today && allDays.first?.count ?? 0 > 0
        
        // If today has a contribution, start counting from today
        // If not, and yesterday had a contribution, start counting from yesterday (skipping today)
        var startIndex = 0
        if !todayHasContribution && dayDifference == 0 {
            // Today is in the data but has no contribution, skip it
            startIndex = 1
        }
        
        // Count consecutive days with contributions
        for i in startIndex..<allDays.count {
            let day = allDays[i]
            
            if day.count > 0 {
                currentStreak += 1
                
                // If we're checking days other than today, make sure they're consecutive
                if i > 0 {
                    let previousDay = allDays[i-1]
                    let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: day.date), to: calendar.startOfDay(for: previousDay.date)).day ?? 0
                    
                    // If there's a gap of more than 1 day, break the streak
                    if daysBetween > 1 {
                        break
                    }
                }
            } else {
                break
            }
        }
        
        // Calculate longest streak
        longestStreak = calculateLongestStreak(from: allDays)
        longestStreak = max(longestStreak, currentStreak)
        
        return (currentStreak, longestStreak, totalCommits)
    }
    
    private func calculateLongestStreak(from days: [(date: Date, count: Int)]) -> Int {
        var longestStreak = 0
        var currentStreak = 0
        let calendar = Calendar.current
        
        // We need to reverse the array to go from oldest to newest when calculating longest
        let sortedDays = days.sorted { $0.date < $1.date }
        
        for i in 0..<sortedDays.count {
            let day = sortedDays[i]
            
            if day.count > 0 {
                if i > 0 {
                    let previousDay = sortedDays[i-1]
                    let daysBetween = calendar.dateComponents([.day], from: calendar.startOfDay(for: previousDay.date), to: calendar.startOfDay(for: day.date)).day ?? 0
                    
                    if daysBetween == 1 {
                        // Consecutive day
                        currentStreak += 1
                    } else {
                        // Non-consecutive, reset streak
                        currentStreak = 1
                    }
                } else {
                    // First day with contribution
                    currentStreak = 1
                }
                
                // Update longest streak if needed
                longestStreak = max(longestStreak, currentStreak)
            } else {
                // No contribution on this day, reset streak
                currentStreak = 0
            }
        }
        
        return longestStreak
    }
} 