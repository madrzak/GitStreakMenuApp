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
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your GitHub settings have been saved and your streak will now be updated.")
        }
    }
    
    private func saveSettings() {
        gitHubManager?.setCredentials(username: username, token: token.isEmpty ? nil : token)
        
        // Trigger a refresh of the streak data
        (NSApplication.shared.delegate as? AppDelegate)?.refreshData()
        
        showingSuccessAlert = true
    }
}

#Preview {
    SettingsView()
} 