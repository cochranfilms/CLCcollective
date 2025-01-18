import SwiftUI

struct AdminProjectView: View {
    let project: Project
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ProjectViewModel
    @State private var isAddingTask = false
    @State private var selectedStatus: Project.ProjectStatus
    @State private var progress: Double
    
    init(project: Project, viewModel: ProjectViewModel) {
        self.project = project
        self._selectedStatus = State(initialValue: project.status)
        self._progress = State(initialValue: project.progress)
        self._viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Project Header
                    VStack(alignment: .leading, spacing: 16) {
                        Text(project.title)
                            .font(.title)
                            .foregroundColor(.white)
                        
                        projectDetails(project)
                    }
                    
                    // Admin Controls
                    adminControls
                    
                    // Tasks Section
                    tasksSection(project)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Projects")
                        }
                        .foregroundColor(Color(hex: "#dca54e"))
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(
                    isPresented: $isAddingTask,
                    projectId: project.id,
                    viewModel: viewModel
                )
            }
            .onChange(of: isAddingTask) { _, newValue in
                if !newValue {
                    // No need to fetch all projects after adding a task
                    // The viewModel already updates the projects array
                }
            }
            .onChange(of: selectedStatus) { _, newStatus in
                Task {
                    await viewModel.updateProjectStatus(projectId: project.id, status: newStatus)
                    // No need to fetch all projects after status update
                }
            }
            .onChange(of: progress) { _, newProgress in
                Task {
                    viewModel.updateProjectProgress(projectId: project.id, progress: newProgress)
                    // No need to fetch all projects after progress update
                }
            }
            .task {
                await viewModel.fetchProjects()
            }
        }
    }
    
    private func projectDetails(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailRow(title: "Client", value: project.clientName)
            DetailRow(title: "Email", value: project.clientEmail)
            DetailRow(title: "Status", value: project.status.rawValue)
            DetailRow(title: "Due Date", value: project.dueDate.formatted(date: .long, time: .omitted))
            DetailRow(title: "Amount", value: String(format: "$%.2f", project.amount))
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private var adminControls: some View {
        VStack(spacing: 16) {
            Text("Admin Controls")
                .font(.headline)
                .foregroundColor(Color(hex: "#dca54e"))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Project Status")
                    .foregroundColor(.white)
                Picker("Status", selection: $selectedStatus) {
                    ForEach(Project.ProjectStatus.allCases, id: \.self) { status in
                        Text(status.rawValue)
                            .tag(status)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color(hex: "#dca54e"))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Project Progress")
                    .foregroundColor(.white)
                HStack {
                    Slider(value: $progress, in: 0...1, step: 0.05)
                        .accentColor(Color(hex: "#dca54e"))
                    Text("\(Int(progress * 100))%")
                        .foregroundColor(.white)
                        .frame(width: 50)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func tasksSection(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isAddingTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "#dca54e"))
                }
            }
            
            ForEach(project.tasks) { task in
                TaskRow(task: task, projectId: project.id, viewModel: viewModel)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

extension Project.ProjectStatus: CaseIterable {
    static var allCases: [Project.ProjectStatus] = [
        .notStarted,
        .inProgress,
        .completed,
        .onHold,
        .cancelled
    ]
} 