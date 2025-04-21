//
//  GitStreakMenuAppApp.swift
//  GitStreakMenuApp
//
//  Created by Lukasz Madrzak on 20/04/2025.
//

import SwiftUI
import AppKit

@main
struct GitStreakMenuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var gitHubManager: GitHubManager!
    private var settingsWindow: NSWindow?
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 3600 // Refresh every hour
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set app to run as a menu bar app without dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize GitHub Manager
        gitHubManager = GitHubManager()
        
        // Create a status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Configure the status item button
        if let button = statusItem.button {
            updateStatusItemDisplay()
            button.toolTip = "GitHub Streak"
        }
        
        // Create and set the menu
        let menu = createMenu()
        statusItem.menu = menu
        
        // Check if username is already set
        if let username = UserDefaults.standard.string(forKey: "GitHubUsername"), !username.isEmpty {
            print("Username found in UserDefaults: \(username)")
            // Initial fetch of streak data
            fetchStreakData()
            
            // Set up timer to refresh data periodically
            setupRefreshTimer()
        } else {
            print("No username found in UserDefaults, showing settings")
            // Show settings if no username is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.openSettings()
            }
        }
    }
    
    func setupRefreshTimer() {
        // Invalidate any existing timer
        refreshTimer?.invalidate()
        
        // Create a new timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.fetchStreakData()
        }
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Fetching streak data...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshData), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Test Connection", action: #selector(testConnection), keyEquivalent: "t"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        return menu
    }
    
    @objc func refreshData() {
        print("Manual refresh triggered")
        fetchStreakData()
    }
    
    @objc func testConnection() {
        print("Testing network connection...")
        
        if let menu = statusItem.menu, menu.items.count > 0 {
            menu.removeItem(at: 0)
            menu.insertItem(NSMenuItem(title: "Testing connection...", action: nil, keyEquivalent: ""), at: 0)
        }
        
        let url = URL(string: "https://api.github.com")!
        let task = URLSession.shared.dataTask(with: url) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Connection test failed: \(error.localizedDescription)")
                    
                    if let menu = self?.statusItem.menu, menu.items.count > 0 {
                        menu.removeItem(at: 0)
                        menu.insertItem(NSMenuItem(title: "Connection test failed: \(error.localizedDescription)", action: nil, keyEquivalent: ""), at: 0)
                    }
                    
                    self?.updateStatusItemDisplay(error: true)
                    
                    // Show an alert with instructions
                    let alert = NSAlert()
                    alert.messageText = "Network Connection Failed"
                    alert.informativeText = "The app cannot connect to GitHub. This is likely because it needs network permissions.\n\n1. Quit the app\n2. Restart the app\n3. If that doesn't work, check your internet connection and try again"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Connection test succeeded: Status \(httpResponse.statusCode)")
                    
                    if let menu = self?.statusItem.menu, menu.items.count > 0 {
                        menu.removeItem(at: 0)
                        menu.insertItem(NSMenuItem(title: "Connection successful! Status: \(httpResponse.statusCode)", action: nil, keyEquivalent: ""), at: 0)
                    }
                    
                    // If connection is successful, try to fetch data again
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self?.refreshData()
                    }
                }
            }
        }
        
        task.resume()
    }
    
    @objc func openSettings() {
        print("Opening settings window")
        // Close the existing window if it's already open
        settingsWindow?.close()
        
        // Create a new settings window
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "GitHub Streak Settings"
        window.center()
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        
        settingsWindow = window
        
        // Show the window and bring it to front
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func fetchStreakData() {
        print("Fetching streak data...")
        updateStatusItemDisplay() // Show loading indicator
        
        gitHubManager.fetchCurrentStreak { [weak self] streakCount, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching streak: \(error.localizedDescription)")
                    self?.updateMenuWithError(error)
                } else if let streakCount = streakCount {
                    print("Streak fetched successfully: \(streakCount)")
                    self?.updateMenuWithStreak(streakCount)
                }
            }
        }
    }
    
    func updateMenuWithStreak(_ streakCount: Int) {
        if let menu = statusItem.menu {
            if menu.items.count > 0 {
                menu.removeItem(at: 0)
                menu.insertItem(NSMenuItem(title: "Current streak: \(streakCount) days", action: nil, keyEquivalent: ""), at: 0)
            }
        }
        updateStatusItemDisplay(streakCount: streakCount)
    }
    
    func updateMenuWithError(_ error: Error) {
        if let menu = statusItem.menu {
            if menu.items.count > 0 {
                menu.removeItem(at: 0)
                menu.insertItem(NSMenuItem(title: "Error: \(error.localizedDescription)", action: nil, keyEquivalent: ""), at: 0)
            }
        }
        updateStatusItemDisplay(error: true)
    }
    
    func updateStatusItemDisplay(streakCount: Int? = nil, error: Bool = false) {
        if let button = statusItem.button {
            if error {
                button.title = "⚠️"
            } else if let count = streakCount {
                button.title = gitHubManager.formatStreak(count)
            } else {
                button.title = "🔄"
            }
        }
    }
    
    // Force refresh of display format without fetching data
    func updateStatusItemDisplay() {
        // Get last known streak if available
        if let menu = statusItem.menu, 
           menu.items.count > 0 {
            
            let title = menu.items[0].title
            
            if title.contains("Current streak:") {
                // Extract the number from "Current streak: X days"
                let components = title.components(separatedBy: "Current streak: ")
                if components.count > 1 {
                    let numString = components[1].replacingOccurrences(of: " days", with: "")
                    if let count = Int(numString) {
                        // Update the display only, DO NOT call refreshData
                        if let button = statusItem.button {
                            button.title = gitHubManager.formatStreak(count)
                        }
                        return
                    }
                }
            }
        }
        
        // If we couldn't extract the streak, refresh the data
        // But we'll avoid doing this to prevent infinite loops
        print("Could not extract streak count from menu item title")
    }
}
