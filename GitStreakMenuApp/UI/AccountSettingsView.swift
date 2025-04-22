import SwiftUI

struct AccountSettingsView: View {
    @Binding var username: String
    @Binding var token: String
    var onSave: () -> Void
    
    var body: some View {
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
                        
                    Link("Go to GitHub tokens page", destination: URL(string: "https://github.com/settings/tokens")!)
                        .font(.caption)
                        .padding(.top, 2)
                }
                .padding()
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Save") {
                    onSave()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
} 