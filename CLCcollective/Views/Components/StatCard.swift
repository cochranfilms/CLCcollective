import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color
    
    init(
        title: String,
        value: String,
        icon: String,
        accentColor: Color = Color(hex: "#dca54e")
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.accentColor = accentColor
    }
    
    init(icon: String, value: String, label: String) {
        self.icon = icon
        self.value = value
        self.title = label
        self.accentColor = Color(hex: "#dca54e")
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentColor)
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(accentColor.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor, lineWidth: 1)
        )
    }
}

#Preview {
    StatCard(title: "Projects", value: "5", icon: "folder.fill")
        .frame(width: 200)
        .padding()
        .background(Color.black)
} 