import Foundation

enum AnalyticsEvent: String {
    case appLaunch = "app_launch"
    case videoPlay = "video_play"
    case videoStop = "video_stop"
    case videoError = "video_error"
    case portfolioView = "portfolio_view"
    case categorySelect = "category_select"
    case portfolioError = "portfolio_error"
}

struct AnalyticsProperties {
    var properties: [String: Any]
    
    init(_ properties: [String: Any] = [:]) {
        self.properties = properties
    }
    
    mutating func add(_ key: String, value: Any) {
        properties[key] = value
    }
}

final class Analytics {
    static let shared = Analytics()
    private let logger = AppLogger.shared
    
    private init() {}
    
    func track(_ event: AnalyticsEvent, properties: AnalyticsProperties = AnalyticsProperties()) {
        var finalProperties = properties
        finalProperties.add("timestamp", value: Date())
        finalProperties.add("platform", value: "iOS")
        
        // Log the event
        logger.info("Analytics Event: \(event.rawValue)", category: .userInterface)
        
        // Here you would typically send to your analytics service
        // For now, we'll just log it
        #if DEBUG
        print("Analytics Event: \(event.rawValue)")
        print("Properties: \(finalProperties.properties)")
        #endif
    }
    
    func trackError(_ error: Error, context: String) {
        var properties = AnalyticsProperties()
        properties.add("error_description", value: error.localizedDescription)
        properties.add("error_context", value: context)
        
        track(.portfolioError, properties: properties)
        logger.error("Error: \(error.localizedDescription) in context: \(context)", category: .error)
    }
} 