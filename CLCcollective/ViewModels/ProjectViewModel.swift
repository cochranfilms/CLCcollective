import Foundation
import Auth0
import SwiftUI

@MainActor
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var error: Error?
    @Published var isLoading = false
    @Published var isAdmin = false
    @Published var totalProjectCount = 0
    @Published var showInvoiceSelector = false
    
    private let projectService = ProjectService()
    private let authManager = AuthenticationManager.shared
    
    init() {
        isAdmin = authManager.userProfile?.email?.lowercased() == "info@cochranfilms.com"
        NotificationCenter.default.addObserver(self, selector: #selector(updateAdminStatus), name: .userAuthenticated, object: nil)
    }
    
    @objc private func updateAdminStatus() {
        isAdmin = authManager.userProfile?.email?.lowercased() == "info@cochranfilms.com"
        objectWillChange.send()
    }
    
    func addTask(projectId: String, task: ProjectTask) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var updatedProject = projects[projectIndex]
        updatedProject.tasks.append(task)
        
        projectService.updateProject(updatedProject)
        projects[projectIndex] = updatedProject
        objectWillChange.send()
    }
    
    func updateTask(projectId: String, task: ProjectTask) {
        // Only allow admin to mark tasks as complete
        if !isAdmin && task.isCompleted {
            return
        }
        
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var updatedProject = projects[projectIndex]
        
        if let taskIndex = updatedProject.tasks.firstIndex(where: { $0.id == task.id }) {
            if !isAdmin {
                var updatedTask = task
                if let existingTask = updatedProject.tasks.first(where: { $0.id == task.id }) {
                    updatedTask.isCompleted = existingTask.isCompleted
                }
                updatedProject.tasks[taskIndex] = updatedTask
            } else {
                updatedProject.tasks[taskIndex] = task
            }
            
            projectService.updateProject(updatedProject)
            projects[projectIndex] = updatedProject
        }
    }
    
    @MainActor
    func updateProjectStatus(projectId: String, status: Project.ProjectStatus) async {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var updatedProject = projects[projectIndex]
        let oldStatus = updatedProject.status
        updatedProject.status = status
        
        // Update progress based on status
        switch status {
        case .notStarted:
            updatedProject.progress = 0.0
        case .inProgress:
            updatedProject.progress = 0.5
        case .completed:
            updatedProject.progress = 1.0
            // Mark all tasks as completed when project is completed
            updatedProject.tasks = updatedProject.tasks.map { task in
                var updatedTask = task
                if !task.isCompleted {
                    updatedTask.isCompleted = true
                    updatedTask.completedAt = Date()
                }
                return updatedTask
            }
        case .onHold:
            updatedProject.progress = 0.25
        case .cancelled:
            updatedProject.progress = 0.0
        }
        
        projectService.updateProject(updatedProject)
        projects[projectIndex] = updatedProject
        
        // Log the status change
        ActivityManager.shared.logProjectUpdate(
            title: "Project Status Updated",
            description: "Project '\(updatedProject.title)' status changed from \(oldStatus.rawValue) to \(status.rawValue)"
        )
        
        // Post notification to refresh dashboard
        NotificationCenter.default.post(name: .refreshDashboard, object: nil)
    }
    
    func updateProjectProgress(projectId: String, progress: Double) {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var updatedProject = projects[projectIndex]
        updatedProject.progress = max(0, min(1, progress))
        
        projectService.updateProject(updatedProject)
        projects[projectIndex] = updatedProject
    }
    
    @MainActor
    func fetchProjects() async {
        isLoading = true
        guard let userId = authManager.userProfile?.id else { return }
        
        if isAdmin {
            // Admin sees all projects
            projects = projectService.fetchProjects(for: nil, includeArchived: true)
        } else {
            // Regular users only see their projects
            projects = projectService.fetchProjects(for: userId)
        }
        
        totalProjectCount = projects.count
        isLoading = false
    }
    
    @MainActor
    func createProject(from invoice: Invoice) async {
        guard let userId = authManager.userProfile?.id else { return }
        
        let project = projectService.createProject(
            title: invoice.title.isEmpty ? "Video Production Project" : invoice.title,
            description: invoice.memo ?? "Video production services",
            clientName: invoice.customerName,
            clientEmail: invoice.customerEmail,
            amount: invoice.amount,
            clientId: userId,
            invoiceId: invoice.id,
            dueDate: invoice.dueDate
        )
        
        // Update the local projects array
        if !projects.contains(where: { $0.invoiceId == project.invoiceId }) {
            projects.append(project)
            totalProjectCount = projects.count
        }
    }
    
    func deleteProject(withInvoiceId invoiceId: String) async throws {
        guard isAdmin || authManager.userProfile?.email?.lowercased() == "info@cochranfilms.com" else {
            throw NSError(domain: "ProjectViewModel", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Only admins can delete projects"])
        }
        
        // Find projects with this invoice ID
        let projectsToDelete = projects.filter { $0.invoiceId == invoiceId }
        
        for project in projectsToDelete {
            projectService.deleteProject(project.id)
        }
        
        if projectsToDelete.isEmpty {
            throw NSError(domain: "ProjectViewModel", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "No project found with the specified invoice ID"])
        }
        
        // Update local projects array
        withAnimation {
            projects.removeAll { $0.invoiceId == invoiceId }
            totalProjectCount = projects.count
        }
        
        NotificationCenter.default.post(name: .refreshDashboard, object: nil)
    }
    
    func deleteProject(_ projectId: String) {
        projectService.deleteProject(projectId)
        withAnimation {
            projects.removeAll { $0.id == projectId }
            totalProjectCount = projects.count
        }
        NotificationCenter.default.post(name: .refreshDashboard, object: nil)
    }
    
    @MainActor
    func createEmptyProject(
        title: String,
        description: String,
        clientName: String,
        clientEmail: String,
        dueDate: Date
    ) {
        let project = projectService.createProject(
            title: title,
            description: description,
            clientName: clientName,
            clientEmail: clientEmail,
            amount: 0, // Default amount until invoice is connected
            clientId: authManager.userProfile?.id ?? "",
            dueDate: dueDate
        )
        
        withAnimation {
            projects.append(project)
            totalProjectCount = projects.count
        }
    }
    
    var activeTasksCount: Int {
        projects.reduce(0) { count, project in
            count + project.tasks.filter { !$0.isCompleted }.count
        }
    }
    
    var completedTasksCount: Int {
        projects.reduce(0) { count, project in
            count + project.tasks.filter { $0.isCompleted }.count
        }
    }
    
    func connectInvoice(projectId: String, invoiceId: String) async {
        guard let projectIndex = projects.firstIndex(where: { $0.id == projectId }) else { return }
        var updatedProject = projects[projectIndex]
        
        // Fetch all invoices and find the one we want
        do {
            let allInvoices = try await WaveService.shared.fetchInvoices()
            guard let invoice = allInvoices.first(where: { $0.id == invoiceId }) else { return }
            
            updatedProject.invoiceId = invoiceId
            updatedProject.amount = invoice.amount
            
            projectService.updateProject(updatedProject)
            projects[projectIndex] = updatedProject
            
            // Log the activity
            ActivityManager.shared.logProjectUpdate(
                title: "Invoice Connected",
                description: "Connected invoice to project '\(updatedProject.title)'"
            )
            
            // Post notification to refresh dashboard
            NotificationCenter.default.post(name: .refreshDashboard, object: nil)
        } catch {
            print("Error connecting invoice: \(error)")
        }
    }
    
    @MainActor
    func disconnectInvoice(invoiceId: String) async {
        // Find any projects connected to this invoice
        for (index, project) in projects.enumerated() where project.invoiceId == invoiceId {
            var updatedProject = project
            updatedProject.invoiceId = nil
            updatedProject.amount = 0
            updatedProject.updatedAt = Date() // Add timestamp for the update
            
            // Update the project in storage and local array
            projectService.updateProject(updatedProject)
            projects[index] = updatedProject
            
            // Log the activity
            ActivityManager.shared.logProjectUpdate(
                title: "Invoice Disconnected",
                description: "Invoice was disconnected from project '\(updatedProject.title)'"
            )
            
            // Post notification for this specific project update
            NotificationCenter.default.post(
                name: .projectUpdated,
                object: nil,
                userInfo: ["projectId": updatedProject.id]
            )
        }
        
        // Force a refresh from storage to ensure consistency
        if let userId = authManager.userProfile?.id {
            // For regular users, fetch their projects
            projects = projectService.fetchProjects(for: userId)
        } else {
            // For admin, fetch all projects
            projects = projectService.fetchProjects(for: nil, includeArchived: true)
        }
        
        // Post notifications to refresh all views
        NotificationCenter.default.post(name: .refreshDashboard, object: nil)
        NotificationCenter.default.post(name: .projectsRefreshed, object: nil)
    }
    
    // Handle UI-initiated status updates
    func updateProjectStatusFromUI(projectId: String, status: Project.ProjectStatus) {
        // Update UI immediately
        if let index = projects.firstIndex(where: { $0.id == projectId }) {
            projects[index].status = status
        }
        
        // Trigger async update
        Task {
            await updateProjectStatus(projectId: projectId, status: status)
        }
    }
    
    @MainActor
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            projectService.updateProject(project)
            
            // Log the update
            ActivityManager.shared.logProjectUpdate(
                title: "Project Updated",
                description: "Project '\(project.title)' details were updated"
            )
        }
    }
} 