import SwiftUI
import UIKit

struct ChatBubble: View {
    let content: String
    let isUser: Bool
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    let businessContext: AIAssistantViewModel.BusinessContext
    private let brandGold = Color(hex: "#dca54e")
    private let avatarSize: CGFloat = 32
    private let bubbleSpacing: CGFloat = 8
    private let maxWidth: CGFloat = UIScreen.main.bounds.width * 0.75
    
    var body: some View {
        HStack(alignment: .top, spacing: bubbleSpacing) {
            if !isUser {
                avatarView(systemName: "video.fill")
            }
            
            // Message Bubble
            VStack {
                HStack(spacing: bubbleSpacing) {
                    if content == "Writing your story... 🎬" {
                        Text(content)
                            .fixedSize(horizontal: false, vertical: true)
                        TypingIndicator()
                            .layoutPriority(1)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(content)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Add action buttons based on content
                            if !isUser {
                                actionButtonsForContent(content)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .foregroundColor(isUser ? .black : .white)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isUser ? brandGold : Color.black.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(brandGold.opacity(0.3), lineWidth: 1)
                )
            }
            .frame(maxWidth: maxWidth, alignment: isUser ? .trailing : .leading)
            
            if isUser {
                avatarView(systemName: "person.circle.fill")
            }
        }
        .padding(.horizontal)
    }
    
    private func actionButtonsForContent(_ content: String) -> some View {
        VStack(spacing: 8) {
            // Email button - always show at the top if content contains contact/support/email keywords
            if content.lowercased().contains("contact") || content.lowercased().contains("support") || content.lowercased().contains("email") {
                Link(destination: URL(string: "mailto:\(businessContext.contactEmail)")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Send Email")
                    }
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(brandGold)
                    .cornerRadius(16)
                }
            }
            
            // Other action buttons
            if content.lowercased().contains("package") || content.lowercased().contains("pricing") {
                actionButton("View Packages", icon: "cube.fill", tab: 2)
                actionButton("View Pricing", icon: "dollarsign.circle.fill", tab: 3)
            }
            if content.lowercased().contains("portfolio") || content.lowercased().contains("work") {
                actionButton("View Portfolio", icon: "photo.fill", tab: 1)
            }
            if content.lowercased().contains("billing") || content.lowercased().contains("invoice") {
                actionButton("View Billing", icon: "creditcard.fill", tab: 4)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func actionButton(_ text: String, icon: String, tab: Int) -> some View {
        Button(action: {
            dismiss()
            selectedTab = tab
        }) {
            HStack {
                Image(systemName: icon)
                Text(text)
            }
            .font(.subheadline)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(brandGold)
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private func avatarView(systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20))
            .foregroundColor(brandGold)
            .frame(width: avatarSize, height: avatarSize)
            .background(Color.black.opacity(0.3))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(brandGold.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatBubble(
            content: "Hello! How can I help you today?",
            isUser: false,
            selectedTab: .constant(0),
            businessContext: .cochranFilms
        )
        
        ChatBubble(
            content: "I'd like to know about your packages",
            isUser: true,
            selectedTab: .constant(0),
            businessContext: .cochranFilms
        )
        
        ChatBubble(
            content: "Writing your story... 🎬",
            isUser: false,
            selectedTab: .constant(0),
            businessContext: .cochranFilms
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
} 