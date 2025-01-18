import SwiftUI

struct AdminTaskRow: View {
    let task: ProjectTask
    let projectId: String
    @ObservedObject var viewModel: ProjectViewModel
    @State private var showingEditSheet = false
    
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
        HStack(spacing: 16) {
            Button(action: {
                toggleTaskCompletion()
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? Color(hex: "#dca54e") : .gray)
                    .font(.system(size: 24))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .strikethrough(task.isCompleted)
                    
                    Button(action: { showingEditSheet = true }) {
                        Image(systemName: "pencil.circle.fill")
                            .foregroundColor(Color(hex: "#dca54e"))
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
    
    private func toggleTaskCompletion() {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.completedAt = updatedTask.isCompleted ? Date() : nil
        
        viewModel.updateTask(projectId: projectId, task: updatedTask)
    }
}

#Preview {
    AdminTaskRow(
        task: ProjectTask(
            title: "Sample Task",
            description: "This is a sample task",
            isCompleted: false,
            priority: .high
        ),
        projectId: "preview_id",
        viewModel: ProjectViewModel()
    )
    .padding()
    .background(Color.black)
} 