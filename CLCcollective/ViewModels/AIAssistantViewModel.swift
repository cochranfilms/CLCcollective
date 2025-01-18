import Foundation
import SwiftUI

// Structure to hold a single message
private struct Message: Codable {
    let isUser: Bool
    let content: String
}

// Structure to hold conversation data for persistence
private struct ConversationData: Codable {
    let messages: [Message]
    let timestamp: Date
    
    init(messages: [(isUser: Bool, content: String)], timestamp: Date) {
        self.messages = messages.map { Message(isUser: $0.isUser, content: $0.content) }
        self.timestamp = timestamp
    }
}

@MainActor
class AIAssistantViewModel: ObservableObject {
    @Published var messages: [(isUser: Bool, content: String)] = []
    @Published var error: String?
    @Published var isServiceAvailable = true
    @Published var isTyping = false
    @Published var currentBusinessContext: BusinessContext = .cochranFilms
    private let service: AIAssistantService?
    private var lastInteractionTime: Date?
    
    enum BusinessContext {
        case cochranFilms
        case courseCreatorAcademy
        
        var contactEmail: String {
            switch self {
            case .cochranFilms:
                return "info@cochranfilms.com"
            case .courseCreatorAcademy:
                return "coursecreatoracademy24@gmail.com"
            }
        }
    }
    
    init() {
        do {
            self.service = try AIAssistantService()
            
            // Try to restore recent conversation
            if let savedConversation = restoreConversation(), isConversationRecent {
                self.messages = savedConversation.messages.map { ($0.isUser, $0.content) }
                self.lastInteractionTime = savedConversation.timestamp
                print("Restored recent conversation from \(savedConversation.timestamp)")
            } else {
                messages.append((
                    isUser: false,
                    content: "Hey there! I'm Cochran, your film guide through the CLC Collective App. How can I help you tell your story?"
                ))
                lastInteractionTime = Date()
            }
        } catch {
            self.service = nil
            self.error = error.localizedDescription
            self.isServiceAvailable = false
        }
    }
    
    func sendMessage(_ message: String) async {
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let service = service else {
            self.error = "AI Assistant is not properly configured"
            return
        }
        
        // Update business context based on message content
        if message.lowercased().contains("course creator") || message.lowercased().contains("academy") {
            currentBusinessContext = .courseCreatorAcademy
        } else if message.lowercased().contains("cochran films") || message.lowercased().contains("video") {
            currentBusinessContext = .cochranFilms
        }
        
        // Add user message
        messages.append((isUser: true, content: message))
        
        // Start typing indicator
        isTyping = true
        lastInteractionTime = Date()
        
        // Save conversation state
        saveConversation()
        
        do {
            // Get AI response
            let response = try await service.getAssistantResponse(userInput: message)
            
            await MainActor.run {
                isTyping = false
                messages.append((isUser: false, content: response))
                lastInteractionTime = Date()
                // Save conversation after AI response
                saveConversation()
            }
        } catch let error as AIError {
            await MainActor.run {
                isTyping = false
                self.error = error.localizedDescription
                
                // Handle quota error specifically
                if case .insufficientQuota = error {
                    isServiceAvailable = false
                    messages.append((
                        isUser: false,
                        content: "I apologize, but I'm currently unavailable due to high demand. Please try again later or contact support for assistance."
                    ))
                }
                // Save conversation even if there's an error
                saveConversation()
            }
        } catch {
            await MainActor.run {
                isTyping = false
                self.error = error.localizedDescription
                // Save conversation even if there's an error
                saveConversation()
            }
        }
    }
    
    // Check if the conversation is still recent (within 1 minute)
    var isConversationRecent: Bool {
        guard let lastTime = lastInteractionTime else { return false }
        return Date().timeIntervalSince(lastTime) < 60 // 60 seconds = 1 minute
    }
    
    // Clear conversation if it's older than 1 minute
    func checkAndClearOldConversation() {
        if !isConversationRecent {
            messages = [(
                isUser: false,
                content: "Hey there! I'm Cochran, your film guide through the CLC Collective App. How can I help you tell your story?"
            )]
            lastInteractionTime = Date()
            // Clear saved conversation
            UserDefaults.standard.removeObject(forKey: "AIAssistantConversation")
        }
    }
    
    // Save conversation state to UserDefaults
    private func saveConversation() {
        guard let lastTime = lastInteractionTime else { return }
        let conversationData = ConversationData(messages: messages, timestamp: lastTime)
        if let encoded = try? JSONEncoder().encode(conversationData) {
            UserDefaults.standard.set(encoded, forKey: "AIAssistantConversation")
            print("Saved conversation at \(lastTime)")
        }
    }
    
    // Restore conversation state from UserDefaults
    private func restoreConversation() -> ConversationData? {
        guard let data = UserDefaults.standard.data(forKey: "AIAssistantConversation"),
              let conversationData = try? JSONDecoder().decode(ConversationData.self, from: data) else {
            return nil
        }
        return conversationData
    }
} 