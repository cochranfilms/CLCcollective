import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .foregroundColor(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
    }
} 