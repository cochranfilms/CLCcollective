import Foundation

enum TaskPriority: String, Codable, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

struct ProjectTask: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var description: String
    var isCompleted: Bool
    var completedAt: Date?
    var priority: TaskPriority
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String = "",
         isCompleted: Bool = false,
         completedAt: Date? = nil,
         priority: TaskPriority = .medium) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.priority = priority
    }
} 