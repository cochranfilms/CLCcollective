import SwiftUI

struct EditTasksView: View {
    @Binding var isPresented: Bool
    let project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @State private var tasks: [ProjectTask]
    @State private var editingTask: ProjectTask?
    @State private var showingTaskEditor = false
    @State private var newTask = ProjectTask(id: UUID().uuidString, title: "", description: "", isCompleted: false, priority: .medium)
    @State private var isAddingNewTask = false
    
    init(isPresented: Binding<Bool>, project: Project, viewModel: ProjectViewModel) {
        self._isPresented = isPresented
        self.project = project
        self.viewModel = viewModel
        self._tasks = State(initialValue: project.tasks)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Add New Task Button
                    Button(action: {
                        editingTask = newTask
                        isAddingNewTask = true
                        showingTaskEditor = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "#dca54e"))
                            Text("New Task")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    
                    // Tasks List
                    List {
                        ForEach(tasks) { task in
                            Button(action: {
                                isAddingNewTask = false
                                editingTask = task
                                showingTaskEditor = true
                            }) {
                                EditableTaskRow(task: task)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .onMove { from, to in
                            tasks.move(fromOffsets: from, toOffset: to)
                            updateProject()
                        }
                        .onDelete { indexSet in
                            tasks.remove(atOffsets: indexSet)
                            updateProject()
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Edit Tasks")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(Color(hex: "#dca54e")),
                trailing: Button("Done") {
                    updateProject()
                    isPresented = false
                }
                .foregroundColor(Color(hex: "#dca54e"))
            )
        }
        .sheet(item: $editingTask) { task in
            TaskEditorView(
                task: task,
                isNewTask: isAddingNewTask
            ) { updatedTask in
                if isAddingNewTask {
                    tasks.append(updatedTask)
                } else if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    tasks[index] = updatedTask
                }
                updateProject()
            }
        }
    }
    
    private func updateProject() {
        var updatedProject = project
        updatedProject.tasks = tasks
        viewModel.updateProject(updatedProject)
    }
}

private struct EditableTaskRow: View {
    let task: ProjectTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    priorityIcon
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "#dca54e"))
                    }
                }
            }
            
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    private var priorityIcon: some View {
        let iconName: String
        let color: Color
        
        switch task.priority {
        case .low:
            iconName = "arrow.down.circle.fill"
            color = .blue
        case .medium:
            iconName = "circle.fill"
            color = .orange
        case .high:
            iconName = "exclamationmark.circle.fill"
            color = .red
        }
        
        return Image(systemName: iconName)
            .foregroundColor(color)
    }
}

private struct TaskEditorView: View {
    let task: ProjectTask
    let isNewTask: Bool
    let onSave: (ProjectTask) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var isCompleted: Bool
    @State private var priority: TaskPriority
    
    init(task: ProjectTask, isNewTask: Bool = false, onSave: @escaping (ProjectTask) -> Void) {
        self.task = task
        self.isNewTask = isNewTask
        self.onSave = onSave
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._isCompleted = State(initialValue: task.isCompleted)
        self._priority = State(initialValue: task.priority)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Title", text: $title)
                            .font(.headline)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Description", text: $description, axis: .vertical)
                            .font(.subheadline)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(height: 100)
                        
                        Picker("Priority", selection: $priority) {
                            ForEach(TaskPriority.allCases, id: \.rawValue) { priority in
                                HStack {
                                    Image(systemName: priorityIcon(for: priority))
                                        .foregroundColor(priorityColor(for: priority))
                                    Text(priority.rawValue)
                                }
                                .tag(priority)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(priorityColor(for: priority))
                        
                        Toggle(isOn: $isCompleted) {
                            HStack {
                                Text("Mark as Completed")
                                    .foregroundColor(.primary)
                                if isCompleted {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "#dca54e"))
                                }
                            }
                        }
                        .tint(Color(hex: "#dca54e"))
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(isNewTask ? "New Task" : "Edit Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(Color(hex: "#dca54e")),
                trailing: Button("Save") {
                    let updatedTask = ProjectTask(
                        id: task.id,
                        title: title,
                        description: description,
                        isCompleted: isCompleted,
                        completedAt: isCompleted ? (task.completedAt ?? Date()) : nil,
                        priority: priority
                    )
                    onSave(updatedTask)
                    dismiss()
                }
                .disabled(title.isEmpty)
                .foregroundColor(title.isEmpty ? .gray : Color(hex: "#dca54e"))
            )
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    private func priorityIcon(for priority: TaskPriority) -> String {
        switch priority {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "circle.fill"
        case .high: return "exclamationmark.circle.fill"
        }
    }
    
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }
} 