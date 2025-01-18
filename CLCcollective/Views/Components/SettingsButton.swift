import SwiftUI

struct SettingsButton: View {
    let title: String
    let icon: String
    let action: (() -> Void)?
    private let brandGold = Color(hex: "#dca54e")
    
    init(title: String, icon: String, action: (() -> Void)? = nil) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    buttonContent
                }
            } else {
                buttonContent
            }
        }
    }
    
    private var buttonContent: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(brandGold)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(brandGold.opacity(0.8))
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(brandGold, lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        SettingsButton(title: "Change Display Name", icon: "person.text.rectangle", action: {})
        SettingsButton(title: "FAQ", icon: "questionmark.circle")
    }
    .padding()
    .background(Color.black)
} 