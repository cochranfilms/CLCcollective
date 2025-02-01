import Foundation

enum AIChatError: Error {
    case invalidResponse
    case serverError(String)
    case networkError(Error)
}

class AIChatService {
    static let shared = AIChatService()
    
    func sendMessage(_ message: String) async throws -> String {
        let endpoint = Config.Services.openAIEndpoint
        print("DEBUG: Attempting to connect to endpoint:", endpoint)
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "message": message
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIChatError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIChatError.serverError(errorMessage)
            }
            
            let responseDict = try JSONDecoder().decode([String: String].self, from: data)
            return responseDict["response"] ?? ""
            
        } catch let error as AIChatError {
            throw error
        } catch {
            throw AIChatError.networkError(error)
        }
    }
} 