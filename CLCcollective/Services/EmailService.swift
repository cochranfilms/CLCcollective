import Foundation

class EmailService {
    static let shared = EmailService()
    private let baseURL = "https://api.postmarkapp.com/email"
    private var postmarkTokenCF: String?
    private var postmarkTokenCCA: String?
    
    private init() {
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path) {
            postmarkTokenCF = config["POSTMARK_SERVER_TOKEN_CF"] as? String
            postmarkTokenCCA = config["POSTMARK_SERVER_TOKEN_CCA"] as? String
        }
    }
    
    func sendEmail(name: String, email: String, phone: String, subject: String, message: String, toEmail: String, isCCA: Bool) async throws -> Bool {
        let token = isCCA ? postmarkTokenCCA : postmarkTokenCF
        let fromEmail = isCCA ? "coursecreatoracademy24@gmail.com" : "noreply@cochranfilms.com"
        
        guard let token = token else {
            throw EmailError.configurationError
        }
        
        guard let url = URL(string: baseURL) else {
            throw EmailError.configurationError
        }
        
        let formattedMessage = """
        New Contact Form Submission
        
        From: \(name)
        Email: \(email)
        Phone: \(phone)
        
        Message:
        \(message)
        """
        
        let parameters: [String: Any] = [
            "From": fromEmail,
            "To": toEmail,
            "Subject": "Contact Form: \(subject)",
            "TextBody": formattedMessage,
            "ReplyTo": email,
            "MessageStream": "outbound"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "X-Postmark-Server-Token")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            throw EmailError.invalidRequestData
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw EmailError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                return true
            case 401:
                throw EmailError.unauthorized
            case 422:
                throw EmailError.badRequest
            case 429:
                throw EmailError.tooManyRequests
            default:
                throw EmailError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch let error as EmailError {
            throw error
        } catch {
            throw EmailError.networkError(error)
        }
    }
}

enum EmailError: LocalizedError {
    case configurationError
    case invalidRequestData
    case invalidResponse
    case badRequest
    case unauthorized
    case tooManyRequests
    case serverError(statusCode: Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .configurationError:
            return "Email service is not properly configured. Please check Postmark configuration."
        case .invalidRequestData:
            return "Failed to prepare email data"
        case .invalidResponse:
            return "Invalid response from email service"
        case .badRequest:
            return "Invalid email request"
        case .unauthorized:
            return "Unauthorized access to email service"
        case .tooManyRequests:
            return "Too many email requests. Please try again later"
        case .serverError(let statusCode):
            return "Server error occurred (Status: \(statusCode))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
} 