import SwiftUI

struct BannerView: View {
    @State private var isAnimating = false
    @State private var cameraRotation = 0.0
    
    var body: some View {
        ZStack {
            // Animated background
            ZStack {
                // Film strip background
                ForEach(0..<3) { index in
                    FilmStrip()
                        .offset(x: isAnimating ? -400 : 400)
                        .offset(y: CGFloat(index * 100) - 100)
                        .opacity(0.3)
                        .animation(
                            Animation.linear(duration: 20)
                                .repeatForever(autoreverses: false)
                                .delay(Double(index) * 2),
                            value: isAnimating
                        )
                }
                
                // Camera icon
                Image(systemName: "video.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.brandTeal)
                    .rotationEffect(.degrees(cameraRotation))
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: cameraRotation
                    )
            }
            
            // Banner content
            VStack(spacing: 12) {
                Text("Professional Video Production")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 2, x: 0, y: 2)
                
                Text("Elevating Stories Through Cinematic Excellence")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black, radius: 2, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Glass effect background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                    
                    // Gradient overlay
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .brandTeal.opacity(0.4),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.6),
                                    .brandTeal.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            isAnimating = true
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                cameraRotation = 15
            }
        }
    }
}

struct FilmStrip: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<10) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.brandTeal.opacity(0.3))
                    .frame(width: 30, height: 20)
            }
        }
    }
}

#Preview {
    BannerView()
        .background(Color.gray)
} 