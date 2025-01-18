import Foundation

struct PricingCategory: Identifiable {
    let id = UUID()
    let title: String
    let items: [PricingItem]
    let note: String?
}

struct PricingItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let price: Double
    
    var priceString: String {
        String(format: "$%.2f", price)
    }
    
    init(title: String, price: Double, description: String? = nil) {
        self.title = title
        self.price = price
        self.description = description
    }
    
    init(title: String, priceString: String, description: String? = nil) {
        self.title = title
        self.description = description
        
        // Convert price string to double
        let cleanedPrice = priceString.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        if cleanedPrice.contains("/Hour") {
            self.price = Double(cleanedPrice.replacingOccurrences(of: "/Hour", with: "")) ?? 0.0
        } else {
            self.price = Double(cleanedPrice) ?? 0.0
        }
    }
}

struct PricingService {
    static let additionalServices = [
        PricingItem(title: "Raw Files", price: 300, description: "All Files As They Were Shot"),
        PricingItem(title: "Shooting", price: 250, description: "Per Hour")
    ]
    
    static let courseCreatorCategory = PricingCategory(
        title: "Course Creator Academy",
        items: [
            PricingItem(title: "Job Shadow", price: 175, description: "Monthly Shadow + Creative Projects"),
            PricingItem(title: "Curious Learner", price: 175, description: "1-Month Access + 2 Classes/Month"),
            PricingItem(title: "3-Month Access", price: 575, description: "3-Month Access + 2 Classes/Month"),
            PricingItem(title: "6-Month Access", price: 1050, description: "6-Month Access + 2 Classes/Month"),
            PricingItem(title: "Full Year Access", price: 2000, description: "365-Day Access + 6 Free Shadows")
        ],
        note: "2-Hour Classes, In-Person & Online"
    )
    
    static let categories: [PricingCategory] = [
        courseCreatorCategory,  // Course Creator Academy first
        PricingCategory(
            title: "Events",
            items: [
                PricingItem(title: "2 Hours", price: 500, description: "Includes 60-Second Recap"),
                PricingItem(title: "3 Hours", price: 750, description: "Includes 60-Second Recap"),
                PricingItem(title: "5 Hours", price: 1250, description: "Includes 60-90 Second Recap"),
                PricingItem(title: "8 Hours", price: 2000, description: "No Edits"),
                PricingItem(title: "8 Hours with Recap", price: 2200, description: "Includes 60-Second Recap")
            ],
            note: nil
        ),
        PricingCategory(
            title: "Live Production",
            items: [
                PricingItem(title: "3 Hours", price: 2000, description: "Up to 3 Cameras + Production Edit"),
                PricingItem(title: "5 Hours", price: 3000, description: "Up to 3 Cameras + Production Edit"),
                PricingItem(title: "8 Hours", price: 4000, description: "Up to 3 Cameras + Production Edit")
            ],
            note: "Up to 3 Cameras"
        ),
        PricingCategory(
            title: "Green Screen",
            items: [
                PricingItem(title: "Studio Rental Only", price: 40, description: "Per Hour"),
                PricingItem(title: "30 Min - 1 Hour Session", price: 300, description: "Includes Edits"),
                PricingItem(title: "2-3 Hour Session", price: 650, description: "Includes Edits"),
                PricingItem(title: "4 Hour Session", price: 1000, description: "No Edits"),
                PricingItem(title: "4 Hour Session with Edits", price: 1300, description: "Includes Edits")
            ],
            note: nil
        ),
        PricingCategory(
            title: "Podcast",
            items: [
                PricingItem(title: "1 Hour Podcast", price: 750, description: "2 Cameras + Edits"),
                PricingItem(title: "2 Hour Podcast", price: 1000, description: "2 Cameras + Edits"),
                PricingItem(title: "3 Hour Podcast", price: 1500, description: "2 Cameras + Edits"),
                PricingItem(title: "Shoot Only", price: 250, description: "Per Hour")
            ],
            note: "Extra Camera - $100/Hour"
        )
    ]
} 
