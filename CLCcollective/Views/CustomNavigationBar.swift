import SwiftUI

struct CustomNavigationBar: View {
    let title: String
    var showBackButton: Bool = true
    var trailingContent: AnyView? = nil
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background with 3D effect
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            
            // Content
            HStack(spacing: 16) {
                if showBackButton {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .shadow(color: Color.white.opacity(0.1), radius: 2, x: 0, y: -1)
                                    .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                            )
                    }
                }
                
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .threeDStyle(startColor: .white, endColor: .white.opacity(0.7))
                
                Spacer()
                
                if let trailingContent = trailingContent {
                    trailingContent
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 60)
    }
}

struct CustomNavigationBarModifier: ViewModifier {
    let title: String
    var showBackButton: Bool = true
    var trailingContent: AnyView? = nil
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            CustomNavigationBar(
                title: title,
                showBackButton: showBackButton,
                trailingContent: trailingContent
            )
            
            content
        }
        .navigationBarHidden(true)
    }
}

extension View {
    func customNavigationBar(
        title: String,
        showBackButton: Bool = true,
        trailingContent: AnyView? = nil
    ) -> some View {
        modifier(
            CustomNavigationBarModifier(
                title: title,
                showBackButton: showBackButton,
                trailingContent: trailingContent
            )
        )
    }
} 