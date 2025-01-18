import SwiftUI

struct SmoothTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .animation(.easeInOut(duration: 0.3), value: UUID())
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

extension View {
    func smoothTransition() -> some View {
        modifier(SmoothTransitionModifier())
    }
} 