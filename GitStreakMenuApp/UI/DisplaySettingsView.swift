import SwiftUI

struct DisplaySettingsView: View {
    @Binding var selectedDisplayFormat: GitHubManager.DisplayFormat
    @Binding var customFormat: String
    var onSave: () -> Void
    
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
    
    private func previewFormat(_ count: Int) -> String {
        if selectedDisplayFormat == .custom && !customFormat.isEmpty {
            // For custom format, replace %d with the count
            return customFormat.replacingOccurrences(of: "%d", with: "\(count)")
        } else {
            // For predefined formats, use the raw value format string
            return String(format: selectedDisplayFormat.rawValue, count)
        }
    }
} 