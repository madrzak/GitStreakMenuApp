import SwiftUI

struct DisplaySettingsView: View {
    @Binding var selectedDisplayFormat: GitHubManager.DisplayFormat
    @Binding var customFormat: String
    var onSave: () -> Void
    
    // Sample values for preview
    private let sampleCurrentStreak = 3
    private let sampleLongestStreak = 42
    private let sampleTotalCommits = 1250
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Display Settings")
                .font(.title)
                .padding(.bottom, 10)
            
            Text("Customize how your GitHub streak is displayed in the menu bar.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            GroupBox {
                ScrollView {
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
                                TextField("Use placeholders for metrics", text: $customFormat)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: customFormat) { newValue in
                                        // Limit to 15 characters
                                        if newValue.count > 15 {
                                            customFormat = String(newValue.prefix(15))
                                        }
                                        
                                        // Ensure at least one placeholder exists
                                        if !newValue.contains("%d") && !newValue.contains("%t") && 
                                           !newValue.contains("%l") && !newValue.isEmpty {
                                            customFormat = newValue + "%d"
                                        }
                                    }
                            }
                            
                            Group {
                                Text("Limited to 15 characters. Use these placeholders:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5) {
                                    GridRow {
                                        Text("%d").bold()
                                        Text("Current streak")
                                    }
                                    GridRow {
                                        Text("%l").bold()
                                        Text("Longest streak")
                                    }
                                    GridRow {
                                        Text("%t").bold()
                                        Text("Total commits")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                                
                                Text("Example: \"🔥%d | ⭐%l | 👨‍💻%t\"")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        // Live preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview:")
                                .font(.headline)
                            
                            HStack {
                                Text("Current streak:")
                                    .frame(minWidth: 120, alignment: .leading)
                                
                                Text(previewFormat())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(5)
                            }
                            
                            if selectedDisplayFormat == .custom && 
                               (customFormat.contains("%l") || customFormat.contains("%t")) {
                                Text("Note: The menu bar will scroll if text is too long.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 5)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            HStack {
                Spacer()
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 10)
        }
        .padding()
    }
    
    private func previewFormat() -> String {
        if selectedDisplayFormat == .custom && !customFormat.isEmpty {
            // Replace all placeholders
            var preview = customFormat
            preview = preview.replacingOccurrences(of: "%d", with: "\(sampleCurrentStreak)")
            preview = preview.replacingOccurrences(of: "%l", with: "\(sampleLongestStreak)")
            preview = preview.replacingOccurrences(of: "%t", with: "\(sampleTotalCommits)")
            return preview
        } else {
            // For predefined formats, use the raw value format string
            return String(format: selectedDisplayFormat.rawValue, sampleCurrentStreak)
        }
    }
} 