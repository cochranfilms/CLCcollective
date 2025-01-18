import Foundation

struct Invoice: Identifiable, Codable {
    let id: String
    let title: String
    let viewUrl: String
    let createdAt: Date
    let dueDate: Date?
    let amount: Double
    let status: String
    let customerName: String
    let customerEmail: String
    let customerId: String?
    let currency: String
    let memo: String?
    let footer: String?
    let lastSentAt: Date?
    let lastViewedAt: Date?
    let lastSentVia: String?
    private var storedDisplayTitle: String?
    
    struct LineItem: Codable {
        let productName: String
        let quantity: Int
        let unitPrice: Double
        let total: Double
    }
    
    let items: [LineItem]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case viewUrl
        case createdAt
        case dueDate
        case amount
        case status
        case customerName
        case customerEmail
        case customerId
        case currency
        case memo
        case footer
        case lastSentAt
        case lastViewedAt
        case lastSentVia
        case items
        case storedDisplayTitle
    }
    
    init(id: String, title: String, viewUrl: String, createdAt: Date, amount: Double, status: String, customerName: String, customerEmail: String, dueDate: Date? = nil, customerId: String? = nil, currency: String = "USD", memo: String? = nil, footer: String? = nil, lastSentAt: Date? = nil, lastViewedAt: Date? = nil, lastSentVia: String? = nil, items: [LineItem]? = nil) {
        self.id = id
        self.title = title
        self.viewUrl = viewUrl
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.amount = amount
        self.status = status
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.customerId = customerId
        self.currency = currency
        self.memo = memo
        self.footer = footer
        self.lastSentAt = lastSentAt
        self.lastViewedAt = lastViewedAt
        self.lastSentVia = lastSentVia
        self.items = items
        self.storedDisplayTitle = UserDefaults.standard.string(forKey: "invoice_display_title_\(id)")
    }
    
    var uniqueId: String {
        "\(id)_\(createdAt.timeIntervalSince1970)"  // Combine id with timestamp for uniqueness
    }
    
    // Display title that can be customized by the user
    var displayTitle: String {
        get {
            storedDisplayTitle ?? title
        }
        set {
            storedDisplayTitle = newValue
            UserDefaults.standard.set(newValue, forKey: "invoice_display_title_\(id)")
        }
    }
    
    // Helper method to create a new instance with updated display title
    func withUpdatedDisplayTitle(_ newTitle: String) -> Invoice {
        var updated = self
        updated.storedDisplayTitle = newTitle
        UserDefaults.standard.set(newTitle, forKey: "invoice_display_title_\(id)")
        return updated
    }
} 