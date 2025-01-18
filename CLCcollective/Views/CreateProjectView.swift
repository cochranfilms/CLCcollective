import SwiftUI
import Auth0

struct CreateProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var clientName = ""
    @State private var clientEmail = ""
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    
    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Title", text: $title)
                    TextEditor(text: $description)
                        .frame(height: 100)
                }
                
                Section("Client Information") {
                    TextField("Client Name", text: $clientName)
                    TextField("Client Email", text: $clientEmail)
                        .keyboardType(.emailAddress)
                }
                
                Section("Due Date") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Create Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                // Auto-fill user information if logged in
                if let email = AuthenticationManager.shared.userProfile?.email {
                    clientEmail = email
                    if !AuthenticationManager.shared.localUsername.isEmpty {
                        clientName = AuthenticationManager.shared.localUsername
                    } else if let name = AuthenticationManager.shared.userProfile?.name, !name.contains("@") {
                        clientName = name
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !clientName.isEmpty &&
        !clientEmail.isEmpty
    }
    
    private func createProject() {
        viewModel.createEmptyProject(
            title: title,
            description: description,
            clientName: clientName,
            clientEmail: clientEmail,
            dueDate: dueDate
        )
        
        dismiss()
    }
} 