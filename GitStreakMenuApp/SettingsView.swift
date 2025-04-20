//
//  SettingsView.swift
//  GitStreakMenuApp
//
//  Created by Lukasz Madrzak on 20/04/2025.
//

import SwiftUI

struct SettingsView: View {
    @State private var username: String = ""
    @State private var token: String = ""
    @State private var showingSuccessAlert: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    private let gitHubManager = (NSApplication.shared.delegate as? AppDelegate)?.gitHubManager
    
    init() {
        // Load existing values from UserDefaults
        _username = State(initialValue: UserDefaults.standard.string(forKey: "GitHubUsername") ?? "")
        _token = State(initialValue: UserDefaults.standard.string(forKey: "GitHubToken") ?? "")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("GitHub Streak Settings")
                .font(.title)
                .padding(.bottom, 10)
            
            Text("Enter your GitHub username and personal access token to fetch your commit streak. The token is only needed for private repositories or if you hit API rate limits.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("GitHub Username:")
                            .frame(width: 120, alignment: .leading)
                        TextField("username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        Text("Personal Token:")
                            .frame(width: 120, alignment: .leading)
                        SecureField("token (optional)", text: $token)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Text("The token only needs 'read:user' scope.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("How to create a token", destination: URL(string: "https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token")!)
                        .font(.caption)
                }
                .padding()
            }
            
            HStack {
                Spacer()
                Button("Save") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 350)
        .alert("Settings Saved", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {
                closeWindow()
            }
        } message: {
            Text("Your GitHub settings have been saved and your streak will now be updated.")
        }
    }
    
    private func saveSettings() {
        // Force UserDefaults to sync immediately
        UserDefaults.standard.set(username, forKey: "GitHubUsername")
        if !token.isEmpty {
            UserDefaults.standard.set(token, forKey: "GitHubToken")
        } else {
            UserDefaults.standard.removeObject(forKey: "GitHubToken")
        }
        UserDefaults.standard.synchronize()
        
        // Now update the GitHubManager
        gitHubManager?.setCredentials(username: username, token: token.isEmpty ? nil : token)
        
        showingSuccessAlert = true
    }
    
    private func closeWindow() {
        // Close the window
        if let window = NSApplication.shared.windows.first(where: { $0.title == "GitHub Streak Settings" }) {
            window.close()
        }
        
        // Trigger a refresh of the streak data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            (NSApplication.shared.delegate as? AppDelegate)?.refreshData()
        }
    }
}

#Preview {
    SettingsView()
} 