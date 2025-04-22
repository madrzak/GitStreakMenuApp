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
    
    private let gitHubManager = AppDelegate.shared?.gitHubManager
    
    init() {
        // Load existing values from UserDefaults
        _username = State(initialValue: UserDefaults.standard.string(forKey: "GitHubUsername") ?? "")
        _token = State(initialValue: UserDefaults.standard.string(forKey: "GitHubToken") ?? "")
        
        // Load display format settings
        if let manager = AppDelegate.shared?.gitHubManager {
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
            AccountSettingsView(
                username: $username,
                token: $token,
                onSave: saveAccountSettings
            )
            .tabItem {
                Label("Account", systemImage: "person.fill")
            }
            .tag(0)
            
            // Display Settings Tab
            DisplaySettingsView(
                selectedDisplayFormat: $selectedDisplayFormat,
                customFormat: $customFormat,
                onSave: saveDisplaySettings
            )
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
        // Ensure at least one placeholder exists
        if selectedDisplayFormat == .custom && 
           !customFormat.contains("%d") && !customFormat.contains("%l") && 
           !customFormat.contains("%t") && !customFormat.isEmpty {
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
            print("Accessing AppDelegate.shared")
            if let appDelegate = AppDelegate.shared {
                print("Found AppDelegate.shared")
                // Use the existing updateStatusItemDisplay() method
                appDelegate.updateStatusItemDisplay()
                print("Updated display format")
            } else {
                print("AppDelegate.shared is nil")
            }
        }
        
        showingSuccessAlert = true
    }
    
    private func closeWindow() {
        // Close the window
        if let window = NSApplication.shared.windows.first(where: { $0.title == "GitHub Streak Settings" }) {
            window.close()
        }
        
        // Trigger a refresh of the streak data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            AppDelegate.shared?.refreshData()
        }
    }
}

#Preview {
    SettingsView()
} 
