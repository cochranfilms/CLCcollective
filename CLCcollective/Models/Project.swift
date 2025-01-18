import Foundation

struct Project: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var status: ProjectStatus
    var clientName: String
    var clientEmail: String
    var amount: Double
    var invoiceId: String?
    var clientId: String
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    var dueDate: Date
    var progress: Double
    var tasks: [ProjectTask]
    
    enum ProjectStatus: String, Codable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
        case onHold = "On Hold"
        case cancelled = "Cancelled"
    }
} 