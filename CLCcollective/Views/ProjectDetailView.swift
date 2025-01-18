import SwiftUI

struct ProjectDetailView: View {
    @StateObject private var projectService = ProjectService()
    @State private var project: Project
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var editedDescription = ""
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ProjectViewModel
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case title
        case description
    }
    
    init(project: Project) {
        self._project = State(wrappedValue: project)
        self._editedDescription = State(wrappedValue: project.description)
    }
    
    private var projectActions: some View {
        VStack {
            if isEditing {
                Button("Save Changes") {
                    saveProject()
                }
            } else {
                Button("Edit Project") {
                    startEditing()
                }
            }
            
            Button("Archive Project", role: .destructive) {
                project.isArchived = true
                viewModel.updateProject(project)
                dismiss()
            }
        }
    }
    
    private var projectDetails: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                TextField("Title", text: $project.title)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: focusedField) { oldValue, newValue in
                        if oldValue == .title && newValue == nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                focusedField = .description
                            }
                        }
                    }
                
                if viewModel.isAdmin {
                    Picker("Status", selection: $project.status) {
                        ForEach(Project.ProjectStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized)
                                .tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Text("Status: \(project.status.rawValue.capitalized)")
                        .foregroundColor(.secondary)
                }
            } else {
                Text(project.title)
                    .font(.headline)
                Text(project.status.rawValue.capitalized)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var descriptionSection: some View {
        Section {
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    if editedDescription.isEmpty {
                        Text("Enter project description...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    TextEditor(text: $editedDescription)
                        .frame(minHeight: 150)
                        .focused($focusedField, equals: .description)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                }
                .padding(8)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(8)
            } else {
                Text(project.description)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } header: {
            Text("Description")
        }
    }
    
    private func saveProject() {
        let canUpdate = viewModel.isAdmin || 
            viewModel.projects.first(where: { $0.id == project.id })?.status == project.status
        
        if canUpdate {
            withAnimation {
                project.description = editedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                viewModel.updateProject(project)
                isEditing = false
                focusedField = nil
            }
        }
    }
    
    private func startEditing() {
        withAnimation {
            editedDescription = project.description
            isEditing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .title
            }
        }
    }
    
    var body: some View {
        Form {
            Section("Project Details") {
                projectDetails
            }
            
            descriptionSection
            
            Section("Actions") {
                projectActions
            }
            
            if viewModel.isAdmin {
                Section {
                    Button("Delete Project", role: .destructive) {
                        showingDeleteAlert = true
                    }
                }
            }
        }
        .navigationTitle("Project Details")
        .interactiveDismissDisabled(isEditing)
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteProject(project.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this project? This action cannot be undone.")
        }
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            saveProject()
                        }
                    }
                }
            }
        }
        .onDisappear {
            if isEditing {
                saveProject()
            }
        }
    }
}

#Preview {
    NavigationView {
        ProjectDetailView(project: Project(
            id: "preview",
            title: "Sample Project",
            description: "This is a sample project",
            status: .notStarted,
            clientName: "John Doe",
            clientEmail: "john@example.com",
            amount: 1000.0,
            invoiceId: nil,
            clientId: "client123",
            isArchived: false,
            createdAt: Date(),
            updatedAt: Date(),
            dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            progress: 0.0,
            tasks: []
        ))
    }
} 