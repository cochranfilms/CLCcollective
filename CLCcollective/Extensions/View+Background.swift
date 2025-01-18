import SwiftUI

struct BackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Image("background_image")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                    
                    Color.black.opacity(0.7)  // Dark overlay
                        .edgesIgnoringSafeArea(.all)
                    
                    SmokeEffect()
                        .allowsHitTesting(false)  // Prevent smoke from interfering with interactions
                }
            )
    }
}

extension View {
    func withAppBackground() -> some View {
        self.modifier(BackgroundModifier())
    }
} 