import Foundation

public struct WixCreatedDate: Codable {
    public let date: String
    
    enum CodingKeys: String, CodingKey {
        case date = "$date"
    }
    
    public init(date: String) {
        self.date = date
    }
} 