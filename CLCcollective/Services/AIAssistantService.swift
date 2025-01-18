import Foundation

class AIAssistantService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 1.0
    
    init() throws {
        if let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            self.apiKey = apiKey
        } else {
            if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
               let config = NSDictionary(contentsOfFile: path),
               let key = config["OPENAI_API_KEY"] as? String {
                self.apiKey = key
            } else {
                throw AIError.missingAPIKey
            }
        }
    }
    
    func getAssistantResponse(userInput: String) async throws -> String {
        if let lastRequest = lastRequestTime, 
           Date().timeIntervalSince(lastRequest) < minimumRequestInterval {
            try await Task.sleep(nanoseconds: UInt64(minimumRequestInterval * 1_000_000_000))
        }
        
        let cleanedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedInput.isEmpty else {
            throw AIError.invalidInput
        }
        
        let systemPrompt = """
        You are an AI assistant for the CLCcollective app. Your role is to:
        1. Help users navigate and understand the app's features and interface
        2. Answer questions about video production, editing, and creative services
        3. Provide information about the app's pricing, packages, and services
        4. Assist with project management and scheduling queries
        5. Help with technical questions about video formats, equipment, and best practices
        
        Email Handling Guidelines:
        - For Cochran Films inquiries, always use info@cochranfilms.com as the contact email
        - For Course Creator Academy inquiries, always use coursecreatoracademy24@gmail.com as the contact email
        - When suggesting email contact, provide the appropriate email based on the context of the user's question
        - If unclear whether the inquiry is for Cochran Films or Course Creator Academy, ask for clarification
        
        General Guidelines:
        - Keep responses clear, concise, and professional
        - If you don't understand a question, ask for clarification
        - If a question is outside your knowledge scope, say so directly
        - For technical questions, provide practical, actionable advice
        - For app-specific questions, focus on available features and functionality
        
        Remember: You are representing CLCcollective, a professional video production company.
        """
        
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": cleanedInput]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.7,
            "presence_penalty": 0.6,
            "frequency_penalty": 0.5,
            "stream": false,
            "top_p": 0.9
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw AIError.invalidRequestData(error)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("OpenAI Response: \(responseString)")
            }
            #endif
            
            switch httpResponse.statusCode {
            case 200:
                guard let openAIResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data),
                      let content = openAIResponse.choices.first?.message.content,
                      !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw AIError.invalidResponseFormat
                }
                lastRequestTime = Date()
                return content
                
            case 401:
                throw AIError.authenticationError
                
            case 429:
                if let errorData = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data),
                   errorData.error.code == "insufficient_quota" {
                    throw AIError.insufficientQuota
                }
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return try await getAssistantResponse(userInput: cleanedInput)
                
            case 500...599:
                throw AIError.serverError(statusCode: httpResponse.statusCode)
                
            default:
                if let errorData = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    if errorData.error.code == "insufficient_quota" {
                        throw AIError.insufficientQuota
                    }
                    throw AIError.apiError(message: errorData.error.message)
                }
                throw AIError.unexpectedStatusCode(httpResponse.statusCode)
            }
        } catch let error as AIError {
            throw error
        } catch {
            throw AIError.networkError(error)
        }
    }
}

struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
    
    struct OpenAIError: Codable {
        let message: String
        let type: String?
        let code: String?
    }
}

enum AIError: LocalizedError {
    case missingAPIKey
    case invalidInput
    case invalidURL
    case invalidRequestData(Error)
    case invalidResponse
    case invalidResponseFormat
    case authenticationError
    case serverError(statusCode: Int)
    case networkError(Error)
    case apiError(message: String)
    case unexpectedStatusCode(Int)
    case insufficientQuota
    
    var errorDescription: String? {
        switch self {
        case .apiError(let message):
            return "OpenAI API Error: \(message)"
        case .missingAPIKey:
            return "OpenAI API key not found. Please check your configuration."
        case .invalidInput:
            return "Please provide a valid question."
        case .invalidURL:
            return "Invalid API URL configuration."
        case .invalidRequestData(let error):
            return "Failed to prepare request data: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received invalid response from server."
        case .invalidResponseFormat:
            return "The response format was invalid or empty."
        case .authenticationError:
            return "Authentication failed. Please check your API key."
        case .serverError(let statusCode):
            return "Server error occurred (Status: \(statusCode))."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unexpectedStatusCode(let code):
            return "Unexpected response status code: \(code)"
        case .insufficientQuota:
            return "The AI assistant is temporarily unavailable. Please contact the app administrator to restore service."
        }
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
} 