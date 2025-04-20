//
//  GitStreakMenuAppApp.swift
//  GitStreakMenuApp
//
//  Created by Lukasz Madrzak on 20/04/2025.
//

import SwiftUI
import AppKit

@main
struct GitStreakMenuAppApp: App {
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        if UserDefaults.standard.string(forKey: "GitHubUsername") != nil {
            // Initial fetch of streak data
            fetchStreakData()
        } else {
            // Show settings if no username is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.openSettings()
            }
        }
    }
    
    func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Fetching streak data...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Refresh", action: #selector(refreshData), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        return menu
    }
    
    @objc func refreshData() {
        fetchStreakData()
    }
    
    @objc func openSettings() {
        // Create settings window if it doesn't exist
        if settingsWindow == nil {
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
            window.makeKey()
            
            settingsWindow = window
        }
        
        // Show the window and bring it to front
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func fetchStreakData() {
        gitHubManager.fetchCurrentStreak { [weak self] streakCount, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.updateMenuWithError(error)
                } else if let streakCount = streakCount {
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
                button.title = "🔥 \(count)"
            } else {
                button.title = "🔄"
            }
        }
    }
}
