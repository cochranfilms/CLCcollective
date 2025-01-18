import SwiftUI
import Auth0

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @ObservedObject private var activityManager = ActivityManager.shared
    
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Reset Password")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(brandGold)
                        .padding(.top)
                    
                    Text("Enter your email address and we'll send you instructions to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(CustomTextFieldStyle())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.horizontal)
                    
                    Button(action: resetPassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(brandGold)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(email.isEmpty || isLoading)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(brandGold)
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {
                    if alertTitle == "Success" {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        
        Auth0
            .authentication()
            .resetPassword(email: email, connection: "Username-Password-Authentication")
            .start { result in
                isLoading = false
                
                switch result {
                case .success:
                    alertTitle = "Success"
                    alertMessage = "Password reset instructions have been sent to your email."
                    activityManager.addActivity(
                        title: "Password Reset Requested",
                        description: "Password reset email sent to \(email)",
                        type: .profileUpdated,
                        icon: "lock.rotation"
                    )
                case .failure(let error):
                    alertTitle = "Error"
                    alertMessage = error.localizedDescription
                }
                
                showingAlert = true
            }
    }
}

#Preview {
    PasswordResetView()
} 