import Foundation
import SwiftUI

class ProjectService: ObservableObject {
    @Published var projects: [Project] = []
    
    // Load projects from UserDefaults
    init() {
        if let data = UserDefaults.standard.data(forKey: "projects"),
           let savedProjects = try? JSONDecoder().decode([Project].self, from: data) {
            self.projects = savedProjects
        }
    }
    
    private func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "projects")
        }
    }
    
    func createProject(
        title: String,
        description: String,
        clientName: String,
        clientEmail: String,
        amount: Double,
        clientId: String,
        invoiceId: String? = nil,
        dueDate: Date? = nil
    ) -> Project {
        let project = Project(
            id: UUID().uuidString,
            title: title,
            description: description,
            status: .notStarted,
            clientName: clientName,
            clientEmail: clientEmail,
            amount: amount,
            invoiceId: invoiceId,
            clientId: clientId,
            isArchived: false,
            createdAt: Date(),
            updatedAt: Date(),
            dueDate: dueDate ?? Date().addingTimeInterval(7 * 24 * 60 * 60), // Default to 7 days from now
            progress: 0.0,
            tasks: []
        )
        
        projects.append(project)
        saveProjects()
        return project
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveProjects()
        }
    }
    
    func archiveProject(_ projectId: String) {
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            var project = projects[index]
            project.isArchived = true
            project.updatedAt = Date()
            projects[index] = project
            saveProjects()
        }
    }
    
    func deleteProject(_ projectId: String) {
        projects.removeAll(where: { $0.id == projectId })
        saveProjects()
    }
    
    func fetchProjects(for userId: String?, includeArchived: Bool = false) -> [Project] {
        if let userId = userId {
            // Regular user - fetch only their projects
            return projects.filter { project in
                project.clientId == userId && (includeArchived || !project.isArchived)
            }
        } else {
            // Admin - fetch all projects
            return includeArchived ? projects : projects.filter { !$0.isArchived }
        }
    }
} 