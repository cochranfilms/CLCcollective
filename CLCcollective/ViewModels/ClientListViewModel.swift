import Foundation
import Auth0

@MainActor
class ClientListViewModel: ObservableObject {
    @Published var clients: [Auth0User] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let domain = "dev-wme4o66iit5msiia.us.auth0.com"
    private let clientId = "wjUqrMgvtmdEd6EBoYG3VWUjBe9QbulC"
    private let clientSecret = "9q5h5r7L4TMG28eZQ2MS93Sve1-I5J2grXunv1heIAAmMdNsMSIGWZpllB2pb3NN"
    
    func fetchClients() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let token = try await getManagementToken()
            let query = "NOT email:'info@cochranfilms.com'"
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let endpoint = "https://\(domain)/api/v2/users?q=\(encodedQuery)&search_engine=v3&include_fields=true&fields=user_id,email,name,identities&per_page=100"
            
            var request = URLRequest(url: URL(string: endpoint)!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let users = try JSONDecoder().decode([Auth0User].self, from: data)
            clients = users
            print("Fetched \(clients.count) clients")
        } catch {
            self.error = error
            print("Error fetching clients: \(error)")
        }
    }
    
    func removeClient(withId userId: String) {
        clients.removeAll { $0.id == userId }
    }
    
    func createUser(email: String, password: String) async {
        // Validate email and password
        guard !email.isEmpty, email.contains("@"), email.contains(".") else {
            self.error = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please enter a valid email address"])
            return
        }
        
        guard !password.isEmpty, password.count >= 8 else {
            self.error = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters long"])
            return
        }
        
        do {
            let token = try await getManagementToken()
            let endpoint = "https://\(domain)/api/v2/users"
            
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Create username from email (remove @ and domain part)
            let username = email.split(separator: "@").first?.lowercased() ?? ""
            
            let body: [String: Any] = [
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
                "password": password,
                "connection": "Username-Password-Authentication",
                "email_verified": true,
                "username": username,
                "name": email.split(separator: "@").first?.lowercased() ?? ""
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 201 {
                    let newUser = try JSONDecoder().decode(Auth0User.self, from: data)
                    clients.append(newUser)
                    // Refresh the client list to ensure we have the latest data
                    await fetchClients()
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message ?? "Failed to create user"])
                    } else {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])
                    }
                }
            }
        } catch {
            self.error = error
            print("Error creating user: \(error)")
        }
    }
    
    private func getManagementToken() async throws -> String {
        let tokenEndpoint = "https://\(domain)/oauth/token"
        var request = URLRequest(url: URL(string: tokenEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "client_id": clientId,
            "client_secret": clientSecret,
            "audience": "https://\(domain)/api/v2/",
            "grant_type": "client_credentials",
            "scope": "read:users create:users delete:users update:users"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.accessToken
    }
}

private struct TokenResponse: Codable {
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

private struct ErrorResponse: Codable {
    let message: String?
    let error: String?
    let error_description: String?
} 