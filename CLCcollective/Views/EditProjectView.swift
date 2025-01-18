import SwiftUI

struct EditProjectView: View {
    @Binding var isPresented: Bool
    let project: Project
    @ObservedObject var viewModel: ProjectViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var clientName: String
    @State private var clientEmail: String
    @State private var dueDate: Date
    @State private var status: Project.ProjectStatus
    
    init(isPresented: Binding<Bool>, project: Project, viewModel: ProjectViewModel) {
        self._isPresented = isPresented
        self.project = project
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        
        // Initialize state variables
        self._title = State(initialValue: project.title)
        self._description = State(initialValue: project.description)
        self._clientName = State(initialValue: project.clientName)
        self._clientEmail = State(initialValue: project.clientEmail)
        self._dueDate = State(initialValue: project.dueDate)
        self._status = State(initialValue: project.status)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Project Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Client Information")) {
                    TextField("Client Name", text: $clientName)
                    TextField("Client Email", text: $clientEmail)
                }
                
                if viewModel.isAdmin {
                    Section(header: Text("Project Status")) {
                        Picker("Status", selection: $status) {
                            ForEach(Project.ProjectStatus.allCases, id: \.self) { status in
                                Text(status.rawValue)
                                    .tag(status)
                            }
                        }
                    }
                }
                
                Section(header: Text("Due Date")) {
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    saveProject()
                    isPresented = false
                }
                .disabled(title.isEmpty || clientName.isEmpty || clientEmail.isEmpty)
            )
        }
    }
    
    private func saveProject() {
        var updatedProject = project
        updatedProject.title = title
        updatedProject.description = description
        updatedProject.clientName = clientName
        updatedProject.clientEmail = clientEmail
        updatedProject.dueDate = dueDate
        // Only update status if user is admin
        if viewModel.isAdmin {
            updatedProject.status = status
        }
        
        viewModel.updateProject(updatedProject)
    }
} 