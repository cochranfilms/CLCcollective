import SwiftUI

struct AdminUserDetailView: View {
    @State private var user: Auth0User
    var onUserDeleted: ((String) -> Void)?
    @StateObject private var viewModel: AdminUserDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var showingEmailChange = false
    @State private var showingPasswordChange = false
    @State private var newEmail = ""
    @State private var newPassword = ""
    
    private let brandGold = Color(hex: "#dca54e")
    
    init(user: Auth0User, onUserDeleted: ((String) -> Void)? = nil) {
        _user = State(initialValue: user)
        self.onUserDeleted = onUserDeleted
        _viewModel = StateObject(wrappedValue: AdminUserDetailViewModel(user: user))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                userInfoSection
                actionButtonsSection
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("User Details")
        .alert("Change Email", isPresented: $showingEmailChange) {
            emailChangeAlert
        }
        .alert("Change Password", isPresented: $showingPasswordChange) {
            passwordChangeAlert
        }
        .alert("Delete User", isPresented: $showingDeleteConfirmation) {
            deleteConfirmationAlert
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            successAlert
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            errorAlert
        }
    }
    
    private var userInfoSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(brandGold)
            
            VStack(spacing: 8) {
                Text(user.name ?? "No Name")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(user.email ?? "No Email")
                    .font(.headline)
                    .foregroundColor(brandGold)
                
                Text("User ID: \(user.id)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandGold, lineWidth: 1)
        )
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            ActionButton(title: "Change Email", icon: "envelope.fill") {
                newEmail = user.email ?? ""
                showingEmailChange = true
            }
            
            ActionButton(title: "Change Password", icon: "lock.fill") {
                showingPasswordChange = true
            }
            
            ActionButton(title: "Delete User", icon: "trash.fill", color: .red) {
                showingDeleteConfirmation = true
            }
        }
    }
    
    private var emailChangeAlert: some View {
        Group {
            TextField("New Email", text: $newEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
            Button("Cancel", role: .cancel) {
                newEmail = ""
            }
            Button("Update") {
                Task {
                    await viewModel.updateEmail(for: user.id, to: newEmail)
                    if viewModel.error == nil {
                        user.email = newEmail
                    }
                }
            }
        }
    }
    
    private var passwordChangeAlert: some View {
        Group {
            SecureField("New Password", text: $newPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Button("Cancel", role: .cancel) {
                newPassword = ""
            }
            Button("Update") {
                Task {
                    await viewModel.updatePassword(for: user.id, to: newPassword)
                    newPassword = ""
                }
            }
        }
    }
    
    private var deleteConfirmationAlert: some View {
        Group {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteUser(user.id)
                    if viewModel.error == nil {
                        onUserDeleted?(user.id)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var successAlert: some View {
        Group {
            Button("OK") {
                viewModel.successMessage = nil
            }
        }
    }
    
    private var errorAlert: some View {
        Group {
            Button("OK") {
                viewModel.error = nil
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    var color: Color = Color(hex: "#dca54e")
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(10)
        }
    }
} 