import Foundation

extension Notification.Name {
    // Authentication notifications
    static let userAuthenticated = Notification.Name("userAuthenticated")
    
    // Navigation notifications
    static let switchToBillingTab = Notification.Name("switchToBillingTab")
    
    // Refresh notifications
    static let refreshInvoices = Notification.Name("refreshInvoices")
    static let refreshDashboard = Notification.Name("refreshDashboard")
    static let invoicesRefreshed = Notification.Name("invoicesRefreshed")
    
    // Invoice state notifications
    static let invoiceCreated = Notification.Name("invoiceCreated")
    static let invoiceDeleted = Notification.Name("invoiceDeleted")
    
    // Project state notifications
    static let projectUpdated = Notification.Name("projectUpdated")
    static let projectsRefreshed = Notification.Name("projectsRefreshed")
} 