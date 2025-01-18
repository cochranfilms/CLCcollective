import Foundation

@MainActor
class AdminUserDetailViewModel: ObservableObject {
    @Published var error: Error?
    @Published var successMessage: String?
    @Published var isLoading = false
    let user: Auth0User
    
    private let domain = "dev-wme4o66iit5msiia.us.auth0.com"
    private let clientId = "wjUqrMgvtmdEd6EBoYG3VWUjBe9QbulC"
    private let clientSecret = "9q5h5r7L4TMG28eZQ2MS93Sve1-I5J2grXunv1heIAAmMdNsMSIGWZpllB2pb3NN"
    
    init(user: Auth0User) {
        self.user = user
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
            "scope": "read:users update:users delete:users"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.accessToken
    }
    
    func updateEmail(for userId: String, to newEmail: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let token = try await getManagementToken()
            let endpoint = "https://\(domain)/api/v2/users/\(userId)"
            
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["email": newEmail]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    successMessage = "Email updated successfully"
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message ?? "Failed to update email"])
                    } else {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to update email"])
                    }
                }
            }
        } catch {
            self.error = error
            print("Error updating email: \(error)")
        }
    }
    
    func updatePassword(for userId: String, to newPassword: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let token = try await getManagementToken()
            let endpoint = "https://\(domain)/api/v2/users/\(userId)"
            
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["password": newPassword]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    successMessage = "Password updated successfully"
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message ?? "Failed to update password"])
                    } else {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to update password"])
                    }
                }
            }
        } catch {
            self.error = error
            print("Error updating password: \(error)")
        }
    }
    
    func deleteUser(_ userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let token = try await getManagementToken()
            let endpoint = "https://\(domain)/api/v2/users/\(userId)"
            
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 204 {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message ?? "Failed to delete user"])
                    } else {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to delete user"])
                    }
                }
            }
        } catch {
            self.error = error
            print("Error deleting user: \(error)")
        }
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