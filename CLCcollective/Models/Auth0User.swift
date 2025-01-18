import Foundation

struct Auth0User: Identifiable, Codable {
    let id: String
    let name: String?
    var email: String?
    let identities: [UserIdentity]?
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name
        case email
        case identities
    }
}

struct UserIdentity: Codable {
    let provider: String
    let userId: String
    let connection: String
    
    enum CodingKeys: String, CodingKey {
        case provider
        case userId = "user_id"
        case connection
    }
} 