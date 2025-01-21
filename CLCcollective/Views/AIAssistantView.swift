import SwiftUI
import UIKit
import Combine

struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var messageText = ""
    @State private var isAppearing = false
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    private let brandGold = Color(hex: "#dca54e")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with dismiss button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(brandGold)
                }
                .padding(.leading)
                
                Spacer()
                
                Text("Cochran Films AI Assistant")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Balance the layout
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.clear)
                    .padding(.trailing)
            }
            .padding(.top)
            .opacity(isAppearing ? 1 : 0)
            .offset(y: isAppearing ? 0 : -20)
            
            chatAreaView
            
            if viewModel.isServiceAvailable {
                inputAreaView
            } else {
                serviceUnavailableView
            }
        }
        .background(backgroundView)
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
            viewModel.checkAndClearOldConversation()
        }
        .onTapGesture {
            if isFocused {
                isFocused = false
            }
        }
    }
    
    private var chatAreaView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages.indices, id: \.self) { index in
                        let message = viewModel.messages[index]
                        ChatBubble(
                            content: message.content,
                            isUser: message.isUser,
                            selectedTab: $selectedTab,
                            businessContext: viewModel.currentBusinessContext
                        )
                            .id(index)
                            .transition(.opacity)
                    }
                    
                    if viewModel.isTyping {
                        ChatBubble(
                            content: "Writing your story... 🎬",
                            isUser: false,
                            selectedTab: $selectedTab,
                            businessContext: viewModel.currentBusinessContext
                        )
                            .opacity(0.7)
                            .transition(.opacity)
                            .id("typing")
                    }
                }
                .padding()
                .animation(.easeOut, value: viewModel.messages.count)
                .animation(.easeOut, value: viewModel.isTyping)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(viewModel.messages.count - 1, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isTyping) { _, isTyping in
                if isTyping {
                    withAnimation {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.2))
    }
    
    private var inputAreaView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(brandGold)
            
            HStack(spacing: 12) {
                messageInputField
                sendButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.black.opacity(0.5))
    }
    
    private var serviceUnavailableView: some View {
        VStack(spacing: 16) {
            Divider()
                .background(brandGold)
            
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(brandGold)
                
                Text("Service Temporarily Unavailable")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Please contact the app administrator to restore the AI assistant service.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Link("Contact Support", destination: URL(string: "mailto:support@cochranfilms.com")!)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(brandGold)
                    .cornerRadius(20)
                    .padding(.top, 8)
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.subheadline)
                        .foregroundColor(brandGold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(brandGold.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(Color.black.opacity(0.5))
    }
    
    private var messageInputField: some View {
        ZStack(alignment: .leading) {
            if messageText.isEmpty {
                Text("Ask Cochran Films...")
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .allowsHitTesting(false)
            }
            
            TextEditor(text: $messageText)
                .frame(height: 35)
                .frame(maxHeight: 60)
                .customTextEditorStyle()
                .focused($isFocused)
                .submitLabel(.return)
                .onSubmit {
                    Task {
                        await sendMessage()
                    }
                }
                .transaction { transaction in
                    transaction.animation = nil
                }
                .onChange(of: messageText) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                    }
                }
        }
        .padding(.horizontal, 4)
    }
    
    private var sendButton: some View {
        Button(action: {
            Task {
                await sendMessage()
            }
        }) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(messageText.isEmpty ? .gray : brandGold)
                .background(Color.black.opacity(0.3))
                .clipShape(Circle())
        }
        .disabled(messageText.isEmpty || viewModel.isTyping)
        .frame(width: 40, height: 40)
    }
    
    private var backgroundView: some View {
        Image("background_image")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .overlay(Color.black.opacity(0.85))
            .ignoresSafeArea()
    }
    
    private func sendMessage() async {
        guard !messageText.isEmpty && !viewModel.isTyping else { return }
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        isFocused = false
        await viewModel.sendMessage(message)
    }
}

#Preview {
    AIAssistantView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
} 