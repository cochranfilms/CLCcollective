import SwiftUI

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
    }
}

struct TaskRow: View {
    let task: ProjectTask
    let projectId: String
    @ObservedObject var viewModel: ProjectViewModel
    @State private var isCompleted: Bool
    @State private var showingEditSheet = false
    
    init(task: ProjectTask, projectId: String, viewModel: ProjectViewModel) {
        self.task = task
        self.projectId = projectId
        self.viewModel = viewModel
        self._isCompleted = State(initialValue: task.isCompleted)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return Color(hex: "#dca54e")
        case .low: return .green
        }
    }
    
    private var priorityIcon: String {
        switch task.priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "flag.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }
    
    var body: some View {
        HStack {
            if viewModel.isAdmin {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isCompleted.toggle()
                    }
                    var updatedTask = task
                    updatedTask.isCompleted = isCompleted
                    if updatedTask.isCompleted {
                        updatedTask.completedAt = Date()
                        if let project = viewModel.projects.first(where: { $0.id == projectId }) {
                            ActivityManager.shared.logTaskCompleted(projectTitle: project.title, taskTitle: task.title)
                        }
                    } else {
                        updatedTask.completedAt = nil
                        if let project = viewModel.projects.first(where: { $0.id == projectId }) {
                            ActivityManager.shared.logTaskUncompleted(projectTitle: project.title, taskTitle: task.title)
                        }
                    }
                    viewModel.updateTask(projectId: projectId, task: updatedTask)
                }) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? Color(hex: "#dca54e") : .gray)
                        .font(.system(size: 24))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .strikethrough(task.isCompleted)
                    
                    if viewModel.isAdmin {
                        Button(action: { showingEditSheet = true }) {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(Color(hex: "#dca54e"))
                        }
                    }
                }
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .strikethrough(task.isCompleted)
                }
                
                HStack(spacing: 8) {
                    if let completedAt = task.completedAt {
                        Text("Completed: \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "#dca54e"))
                    }
                    
                    Text(task.priority.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor.opacity(0.2))
                        .foregroundColor(priorityColor)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .sheet(isPresented: $showingEditSheet) {
            EditTaskView(
                isPresented: $showingEditSheet,
                projectId: projectId,
                task: task,
                viewModel: viewModel
            )
        }
    }
}

struct AddTaskView: View {
    @Binding var isPresented: Bool
    let projectId: String
    @ObservedObject var viewModel: ProjectViewModel
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .medium
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                        .textInputAutocapitalization(.words)
                    TextField("Task Description", text: $description)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section {
                    Text("Priority")
                        .foregroundColor(Color(hex: "#dca54e"))
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: saveTask) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save Task")
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#dca54e"))
                        .cornerRadius(10)
                    }
                    .disabled(title.isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
    
    private func saveTask() {
        let task = ProjectTask(
            title: title,
            description: description,
            priority: priority
        )
        
        Task {
            // Add the task
            viewModel.addTask(projectId: projectId, task: task)
            
            // Immediately fetch updated projects
            await viewModel.fetchProjects()
            
            // Dismiss the sheet
            isPresented = false
        }
    }
}

struct EditTaskView: View {
    @Binding var isPresented: Bool
    let projectId: String
    let task: ProjectTask
    @ObservedObject var viewModel: ProjectViewModel
    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority
    
    init(isPresented: Binding<Bool>, projectId: String, task: ProjectTask, viewModel: ProjectViewModel) {
        self._isPresented = isPresented
        self.projectId = projectId
        self.task = task
        self.viewModel = viewModel
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._priority = State(initialValue: task.priority)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                        .textInputAutocapitalization(.words)
                    TextField("Task Description", text: $description)
                        .textInputAutocapitalization(.sentences)
                }
                
                Section {
                    Text("Priority")
                        .foregroundColor(Color(hex: "#dca54e"))
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue)
                                .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: saveTask) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save Changes")
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#dca54e"))
                        .cornerRadius(10)
                    }
                    .disabled(title.isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
        }
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.priority = priority
        
        Task {
            // Update the task
            viewModel.updateTask(projectId: projectId, task: updatedTask)
            
            // Log the activity
            if let project = viewModel.projects.first(where: { $0.id == projectId }) {
                ActivityManager.shared.logProjectUpdate(
                    title: "Task Updated",
                    description: "Updated task '\(title)' in project '\(project.title)'"
                )
            }
            
            // Immediately fetch updated projects
            await viewModel.fetchProjects()
            
            // Dismiss the sheet
            isPresented = false
        }
    }
} 