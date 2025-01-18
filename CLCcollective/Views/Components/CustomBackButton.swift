import SwiftUI

struct CustomBackButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14))
            }
            .foregroundColor(Color(hex: "#dca54e"))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
    }
} 