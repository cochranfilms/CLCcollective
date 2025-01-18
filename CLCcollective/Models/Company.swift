import Foundation

struct Company: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let imageName: String
    let videoURL: String?
    
    static let allCompanies: [Company] = [
        Company(
            name: "CLC Collective",
            description: "Professional video production and creative services",
            imageName: "clc_logo",
            videoURL: nil
        )
    ]
}
