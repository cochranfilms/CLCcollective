import SwiftUI

struct CompletedTasksView: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var isAppearing = false
    @Environment(\.dismiss) private var dismiss
    private let brandGold = Color(hex: "#dca54e")
    
    var completedTasks: [(task: ProjectTask, projectTitle: String)] {
        projectViewModel.projects.flatMap { project in
            project.tasks
                .filter { $0.isCompleted }
                .map { ($0, project.title) }
        }
        .sorted { ($0.task.completedAt ?? Date.distantPast) > ($1.task.completedAt ?? Date.distantPast) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Completed Tasks")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(brandGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 60)
                        .padding(.horizontal)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                    
                    if completedTasks.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(brandGold.opacity(0.5))
                            
                            Text("No completed tasks yet")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(brandGold.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(completedTasks.enumerated()), id: \.element.task.id) { index, taskInfo in
                                CompletedTaskRow(task: taskInfo.task, projectTitle: taskInfo.projectTitle)
                                    .opacity(isAppearing ? 1 : 0)
                                    .offset(y: isAppearing ? 0 : 20)
                                    .animation(.easeOut.delay(Double(index) * 0.1), value: isAppearing)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(
                Image("background_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(Color.black.opacity(0.85))
                    .ignoresSafeArea()
            )
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    CustomBackButton(title: "Profile", action: { dismiss() })
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
        }
        .task {
            await projectViewModel.fetchProjects()
        }
    }
}

struct CompletedTaskRow: View {
    let task: ProjectTask
    let projectTitle: String
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(brandGold)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if let completedAt = task.completedAt {
                    Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.caption)
                    .foregroundColor(brandGold.opacity(0.8))
                
                Text(projectTitle)
                    .font(.caption)
                    .foregroundColor(brandGold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(brandGold.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(brandGold.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        CompletedTasksView()
            .environmentObject(ProjectViewModel())
    }
} 