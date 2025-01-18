import Foundation

struct ActivityItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let date: Date
    let icon: String
    let type: ActivityType
    
    enum ActivityType: String, Codable {
        case invoiceCreated = "INVOICE_CREATED"
        case invoiceDeleted = "INVOICE_DELETED"
        case profileUpdated = "PROFILE_UPDATED"
        case contactForm = "CONTACT_FORM"
        case displayNameChanged = "DISPLAY_NAME_CHANGED"
    }
    
    var formattedDate: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            return "\(minutes)m ago"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours)h ago"
        } else if let days = components.day {
            return "\(days)d ago"
        }
        return "Just now"
    }
}

@MainActor
class ActivityManager: ObservableObject {
    @Published private(set) var activities: [ActivityItem] = []
    static let shared = ActivityManager()
    private let maxActivities = 50
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadActivities()
    }
    
    private func loadActivities() {
        guard let userId = AuthenticationManager.shared.userProfile?.id else { return }
        let key = "user_activities_\(userId)"
        
        if let data = userDefaults.data(forKey: key),
           let decodedActivities = try? JSONDecoder().decode([ActivityItem].self, from: data) {
            activities = decodedActivities
        }
    }
    
    private func saveActivities() {
        guard let userId = AuthenticationManager.shared.userProfile?.id else { return }
        let key = "user_activities_\(userId)"
        
        if let encoded = try? JSONEncoder().encode(activities) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func addActivity(title: String, description: String, type: ActivityItem.ActivityType, icon: String) {
        let newActivity = ActivityItem(
            id: UUID(),
            title: title,
            description: description,
            date: Date(),
            icon: icon,
            type: type
        )
        
        activities.insert(newActivity, at: 0)
        if activities.count > maxActivities {
            activities = Array(activities.prefix(maxActivities))
        }
        
        saveActivities()
    }
    
    func clearActivities() {
        activities.removeAll()
        saveActivities()
    }
    
    func logInvoiceCreated(title: String, amount: Double) {
        addActivity(
            title: "Invoice Created",
            description: "\(title) ($\(String(format: "%.2f", amount)))",
            type: .invoiceCreated,
            icon: "doc.text.fill"
        )
    }
    
    func logInvoiceDeleted(title: String, amount: Double) {
        addActivity(
            title: "Invoice Deleted",
            description: "\(title) ($\(String(format: "%.2f", amount)))",
            type: .invoiceDeleted,
            icon: "trash.fill"
        )
    }
    
    func logProfileUpdate(description: String) {
        addActivity(
            title: "Profile Updated",
            description: description,
            type: .profileUpdated,
            icon: "person.crop.circle.fill"
        )
    }
    
    func logContactForm(description: String) {
        addActivity(
            title: "Contact Form",
            description: description,
            type: .contactForm,
            icon: "envelope.fill"
        )
    }
    
    func logDisplayNameChanged(oldName: String, newName: String) {
        addActivity(
            title: "Display Name Changed",
            description: "Changed from '\(oldName)' to '\(newName)'",
            type: .displayNameChanged,
            icon: "pencil.circle.fill"
        )
    }
    
    func logTaskAdded(projectTitle: String, taskTitle: String) {
        addActivity(
            title: "Task Added",
            description: "Added task '\(taskTitle)' to project '\(projectTitle)'",
            type: .profileUpdated,
            icon: "checklist"
        )
    }
    
    func logTaskCompleted(projectTitle: String, taskTitle: String) {
        addActivity(
            title: "Task Completed",
            description: "Completed task '\(taskTitle)' in project '\(projectTitle)'",
            type: .profileUpdated,
            icon: "checkmark.circle.fill"
        )
    }
    
    func logTaskUncompleted(projectTitle: String, taskTitle: String) {
        addActivity(
            title: "Task Reopened",
            description: "Reopened task '\(taskTitle)' in project '\(projectTitle)'",
            type: .profileUpdated,
            icon: "arrow.counterclockwise"
        )
    }
    
    func logProjectUpdate(title: String, description: String) {
        addActivity(
            title: "Project Update",
            description: description,
            type: .profileUpdated,
            icon: "folder.fill"
        )
    }
} 