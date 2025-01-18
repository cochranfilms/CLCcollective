import SwiftUI

struct GradientBackgroundStyle: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // Base background image
            Image("background_image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.all)
            
            // Dark gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.85),
                    Color(red: 0, green: 0.2, blue: 0.2).opacity(0.9),
                    Color(red: 0, green: 0.3, blue: 0.3).opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            // Content
            content
        }
    }
}

struct GradientCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Category background image
                    Image("Categories_BG")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .overlay(Color.black.opacity(0.5))
                    
                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.5),
                            Color(red: 0, green: 0.15, blue: 0.15).opacity(0.6)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            )
            // Glowing border
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.brandTeal,
                                Color.brandTeal.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            )
            // Outer glow
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.brandTeal.opacity(0.6), lineWidth: 1)
                    .blur(radius: 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// Special style for non-category cards
struct StandardCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.7),
                        Color(red: 0, green: 0.15, blue: 0.15).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.brandTeal,
                                Color.brandTeal.opacity(0.3)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func withGradientBackground() -> some View {
        self.modifier(GradientBackgroundStyle())
    }
    
    func withGradientCard() -> some View {
        self.modifier(GradientCardStyle())
    }
    
    func withStandardCard() -> some View {
        self.modifier(StandardCardStyle())
    }
} 