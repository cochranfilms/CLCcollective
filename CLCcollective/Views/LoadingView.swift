import SwiftUI

struct LoadingView: View {
    @State private var cameraFrame = 0
    @State private var logoScale: CGFloat = 0.8
    
    // 8-bit camera frames with film reel
    private let cameraFrames = [
        """
        ┌───────────┐
        │ ▶ ┌───┐  │
        │   │ ○ │ □ │
        │   └───┘  │
        └───────────┘
        """,
        """
        ┌───────────┐
        │ ▶ ┌───┐  │
        │   │ ◎ │ ■ │
        │   └───┘  │
        └───────────┘
        """,
        """
        ┌───────────┐
        │ ▶ ┌───┐  │
        │   │ ● │ □ │
        │   └───┘  │
        └───────────┘
        """
    ]
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image("CLC_logo2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .scaleEffect(logoScale)
                
                Text(cameraFrames[cameraFrame])
                    .font(.custom("Menlo", size: 28))
                    .foregroundColor(.brandTeal)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            // Start the animation timer
            withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                logoScale = 1.0
            }
            
            // Animate camera frames
            Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                withAnimation {
                    cameraFrame = (cameraFrame + 1) % cameraFrames.count
                }
            }
        }
    }
}

#Preview {
    LoadingView()
}