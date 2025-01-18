import SwiftUI

struct CustomTextEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}

extension View {
    func customTextEditorStyle() -> some View {
        modifier(CustomTextEditorStyle())
    }
} 