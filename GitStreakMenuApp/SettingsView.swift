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
    @State private var selectedDisplayFormat: GitHubManager.DisplayFormat = .emoji
    @State private var customFormat: String = ""
    @State private var showingSuccessAlert: Bool = false
    @State private var selectedTab = 0
    @Environment(\.presentationMode) var presentationMode
    
    private let gitHubManager = (NSApplication.shared.delegate as? AppDelegate)?.gitHubManager
    
    init() {
        // Load existing values from UserDefaults
        _username = State(initialValue: UserDefaults.standard.string(forKey: "GitHubUsername") ?? "")
        _token = State(initialValue: UserDefaults.standard.string(forKey: "GitHubToken") ?? "")
        
        // Load display format settings
        if let manager = (NSApplication.shared.delegate as? AppDelegate)?.gitHubManager {
            _selectedDisplayFormat = State(initialValue: manager.displayFormat)
            _customFormat = State(initialValue: manager.customFormat)
        } else {
            let formatRawValue = UserDefaults.standard.string(forKey: "DisplayFormat") ?? GitHubManager.DisplayFormat.emoji.rawValue
            _selectedDisplayFormat = State(initialValue: GitHubManager.DisplayFormat.fromRawValue(formatRawValue))
            _customFormat = State(initialValue: UserDefaults.standard.string(forKey: "CustomFormat") ?? "")
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // GitHub Account Tab
            VStack(alignment: .leading, spacing: 20) {
                Text("GitHub Account")
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
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button("Save") {
                        saveAccountSettings()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .tabItem {
                Label("Account", systemImage: "person.fill")
            }
            .tag(0)
            
            // Display Settings Tab
            VStack(alignment: .leading, spacing: 20) {
                Text("Display Settings")
                    .font(.title)
                    .padding(.bottom, 10)
                
                Text("Customize how your GitHub streak is displayed in the menu bar.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                GroupBox {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Display Format:")
                            .font(.headline)
                            .padding(.bottom, 5)
                            
                        // Picker for predefined formats
                        Picker("", selection: $selectedDisplayFormat) {
                            ForEach(GitHubManager.DisplayFormat.allCases) { format in
                                Text(format.description).tag(format)
                            }
                        }
                        .pickerStyle(RadioGroupPickerStyle())
                        .padding(.bottom, 10)
                        .onChange(of: selectedDisplayFormat) { newValue in
                            // Clear custom format if not custom
                            if newValue != .custom && customFormat.isEmpty {
                                customFormat = "%d"
                            }
                        }
                        
                        // Custom format input
                        if selectedDisplayFormat == .custom {
                            HStack {
                                Text("Custom Format:")
                                    .frame(width: 120, alignment: .leading)
                                TextField("Use %d for the streak count", text: $customFormat)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: customFormat) { newValue in
                                        // Limit to 10 characters
                                        if newValue.count > 10 {
                                            customFormat = String(newValue.prefix(10))
                                        }
                                        
                                        // Ensure %d exists in the format
                                        if !newValue.contains("%d") && !newValue.isEmpty {
                                            customFormat = newValue + "%d"
                                        }
                                    }
                            }
                            
                            Text("Limited to 10 characters. Include %d to show the streak count.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // Live preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview:")
                                .font(.headline)
                            
                            HStack {
                                Text("In menu bar:")
                                    .frame(minWidth: 100, alignment: .leading)
                                
                                Text(previewFormat(3))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                            }
                            
                            HStack {
                                Text("Long streak:")
                                    .frame(minWidth: 100, alignment: .leading)
                                
                                Text(previewFormat(365))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button("Save") {
                        saveDisplaySettings()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .tabItem {
                Label("Display", systemImage: "eye.fill")
            }
            .tag(1)
        }
        .frame(width: 500, height: 400)
        .alert("Settings Saved", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) {
                closeWindow()
            }
        } message: {
            Text("Your settings have been saved and your streak will now be updated.")
        }
    }
    
    private func previewFormat(_ count: Int) -> String {
        if selectedDisplayFormat == .custom && !customFormat.isEmpty {
            // For custom format, replace %d with the count
            return customFormat.replacingOccurrences(of: "%d", with: "\(count)")
        } else {
            // For predefined formats, use the raw value format string
            return String(format: selectedDisplayFormat.rawValue, count)
        }
    }
    
    private func saveAccountSettings() {
        // Force UserDefaults to sync immediately
        UserDefaults.standard.set(username, forKey: "GitHubUsername")
        if !token.isEmpty {
            UserDefaults.standard.set(token, forKey: "GitHubToken")
        } else {
            UserDefaults.standard.removeObject(forKey: "GitHubToken")
        }
        UserDefaults.standard.synchronize()
        
        // Update GitHubManager
        gitHubManager?.setCredentials(username: username, token: token.isEmpty ? nil : token)
        
        showingSuccessAlert = true
    }
    
    private func saveDisplaySettings() {
        // Ensure custom format has %d
        if selectedDisplayFormat == .custom && !customFormat.contains("%d") && !customFormat.isEmpty {
            customFormat = customFormat + "%d"
        }
        
        // Save display format settings
        UserDefaults.standard.set(selectedDisplayFormat.rawValue, forKey: "DisplayFormat")
        UserDefaults.standard.set(customFormat, forKey: "CustomFormat")
        UserDefaults.standard.synchronize()
        
        // Update GitHubManager
        gitHubManager?.setDisplayFormat(selectedDisplayFormat, customFormat: customFormat)
        
        // Manually trigger a display refresh WITHOUT triggering data refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Access the current streak value from the app delegate
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
               let menu = appDelegate.statusItem.menu,
               menu.items.count > 0 {
                
                let title = menu.items[0].title
                
                if title.contains("Current streak:") {
                    // Extract streak value
                    let components = title.components(separatedBy: "Current streak: ")
                    if components.count > 1 {
                        let numString = components[1].replacingOccurrences(of: " days", with: "")
                        if let count = Int(numString),
                           let button = appDelegate.statusItem.button {
                            // Update display directly
                            button.title = appDelegate.gitHubManager.formatStreak(count)
                        }
                    }
                }
            }
        }
        
        showingSuccessAlert = true
    }
    
    private func saveSettings() {
        if selectedTab == 0 {
            saveAccountSettings()
        } else {
            saveDisplaySettings()
        }
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
