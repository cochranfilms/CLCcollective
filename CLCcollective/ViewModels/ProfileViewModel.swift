import Foundation
import Auth0

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userCount: Int = 0
    @Published var invoiceCount: Int = 0
    @Published var error: Error?
    @Published var isAdmin: Bool = false
    @Published var isLoading = false
    @Published var successMessage: String?
    
    private let domain = "dev-wme4o66iit5msiia.us.auth0.com"
    private let clientId = "wjUqrMgvtmdEd6EBoYG3VWUjBe9QbulC"
    private let clientSecret = "9q5h5r7L4TMG28eZQ2MS93Sve1-I5J2grXunv1heIAAmMdNsMSIGWZpllB2pb3NN"
    private let authManager = AuthenticationManager.shared
    private let defaults = UserDefaults.standard
    private var refreshTask: Task<Void, Never>?
    
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        refreshTask?.cancel()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInvoiceCreated),
            name: .invoiceCreated,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInvoiceDeleted),
            name: .invoiceDeleted,
            object: nil
        )
    }
    
    @objc private func handleInvoiceCreated() {
        Task { await refreshStatistics() }
    }
    
    @objc private func handleInvoiceDeleted() {
        Task { await refreshStatistics() }
    }
    
    @objc private func handleUserAuthenticated() {
        // Wait for auth profile to be available
        guard let userProfile = authManager.userProfile else {
            print("User profile not yet available")
            return
        }
        
        Task {
            await MainActor.run {
                self.isAdmin = userProfile.email?.lowercased() == "info@cochranfilms.com"
            }
            await refreshStatistics()
        }
    }
    
    func startPeriodicRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await refreshStatistics()
                try? await Task.sleep(nanoseconds: 30 * 1_000_000_000) // 30 seconds
            }
        }
    }
    
    func stopPeriodicRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    func refreshStatistics() async {
        guard authManager.isAuthenticated else {
            print("Cannot refresh statistics - user not properly authenticated")
            return
        }
        
        if isAdmin {
            await fetchUserCount()
        }
        await fetchInvoiceCount()
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
            "scope": "read:users update:users"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        return tokenResponse.accessToken
    }
    
    func updatePassword(to newPassword: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = authManager.userProfile?.id else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
            }
            
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
    
    func fetchUserCount() async {
        do {
            let token = try await getManagementToken()
            let query = "NOT email:'info@cochranfilms.com'"
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            let endpoint = "https://\(domain)/api/v2/users?q=\(encodedQuery)&include_totals=true&per_page=100&search_engine=v3"
            
            var request = URLRequest(url: URL(string: endpoint)!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            struct UserListResponse: Codable {
                let total: Int
                let users: [Auth0User]
            }
            
            let usersResponse = try JSONDecoder().decode(UserListResponse.self, from: data)
            userCount = usersResponse.total
            print("Updated user count to: \(userCount) total users")
        } catch {
            self.error = error
            print("Error fetching user count: \(error)")
        }
    }
    
    private func fetchInvoiceCount() async {
        guard authManager.isAuthenticated else { return }
        
        do {
            let userEmail = authManager.userProfile?.email?.lowercased()
            let allInvoices = try await WaveService.shared.fetchInvoices(forUserEmail: userEmail)
            invoiceCount = allInvoices.count
        } catch {
            print("Error fetching invoice count: \(error)")
            invoiceCount = 0
        }
    }
    
    @MainActor
    func resetPassword(email: String) async {
        isLoading = true
        defer { isLoading = false }
        
        print("Initiating password reset for email: \(email)")
        
        let auth = Auth0.authentication()
        let request = auth.resetPassword(
            email: email,
            connection: "Username-Password-Authentication"
        )
        
        request.start { result in
            Task { @MainActor in
                switch result {
                case .success:
                    print("Password reset email sent successfully to: \(email)")
                    self.successMessage = "Password reset email sent successfully"
                    ActivityManager.shared.logProfileUpdate(description: "Password reset email requested")
                    
                case .failure(let error):
                    print("Error resetting password: \(error)")
                    let errorMessage = "Failed to send reset email. Please try again later."
                    self.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                }
            }
        }
    }
    
    @MainActor
    func updateDisplayName(to newName: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let userId = authManager.userProfile?.id else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
            }
            
            let token = try await getManagementToken()
            let endpoint = "https://\(domain)/api/v2/users/\(userId)"
            var request = URLRequest(url: URL(string: endpoint)!)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["name": newName]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    successMessage = "Display name updated successfully"
                    ActivityManager.shared.logProfileUpdate(description: "Display name updated to \(newName)")
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorResponse.message ?? "Failed to update display name"])
                    } else {
                        throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to update display name"])
                    }
                }
            }
        } catch {
            self.error = error
            print("Error updating display name: \(error)")
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

private struct UsersResponse: Codable {
    let start: Int
    let limit: Int
    let length: Int
    let total: Int
    let users: [Auth0UserResponse]
}

private struct Auth0UserResponse: Codable {
    let email: String?
    let email_verified: Bool?
    let user_id: String?
    let name: String?
} 