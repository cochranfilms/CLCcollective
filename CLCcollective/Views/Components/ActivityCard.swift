import SwiftUI

struct ActivityCard: View {
    let title: String
    let description: String
    let date: String
    let icon: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(accentColor.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .frame(height: 120)
        .frame(width: 300)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor, lineWidth: 1)
        )
    }
}

#Preview {
    ActivityCard(
        title: "Project Update",
        description: "Project status changed to completed",
        date: "Today, 2:30 PM",
        icon: "checkmark.circle.fill",
        accentColor: Color(hex: "#dca54e")
    )
    .padding()
    .background(Color.black)
} 