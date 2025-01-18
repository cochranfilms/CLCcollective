import SwiftUI

struct TypingIndicator: View {
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    private let brandGold = Color(hex: "#dca54e")
    private let dotSize: CGFloat = 6
    private let spacing: CGFloat = 4
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(brandGold)
                    .frame(width: dotSize, height: dotSize)
                    .opacity(dotCount >= index + 1 ? 1 : 0.3)
            }
        }
        .frame(height: dotSize)
        .fixedSize()
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

#Preview {
    TypingIndicator()
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
} 