import SwiftUI

struct SmokeParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var scale: CGFloat
    var opacity: Double
    var rotation: Double
}

struct SmokeEffect: View {
    @State private var particles: [SmokeParticle] = []
    @State private var timer: Timer?
    let particleCount = 15
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .scaleEffect(particle.scale)
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .blur(radius: 20)
                }
            }
            .onAppear {
                setupParticles(in: geometry.size)
                startAnimation(in: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func setupParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            createParticle(in: size)
        }
    }
    
    private func createParticle(in size: CGSize) -> SmokeParticle {
        let randomX = CGFloat.random(in: 0...size.width)
        let randomY = CGFloat.random(in: 0...size.height)
        return SmokeParticle(
            position: CGPoint(x: randomX, y: randomY),
            scale: CGFloat.random(in: 0.8...2.0),
            opacity: Double.random(in: 0.2...0.4),
            rotation: Double.random(in: 0...360)
        )
    }
    
    private func startAnimation(in size: CGSize) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 3.0)) {
                for index in particles.indices {
                    particles[index].position.y -= 0.8
                    particles[index].rotation += 0.5
                    
                    if particles[index].position.y < -100 {
                        particles[index] = createParticle(in: size)
                        particles[index].position.y = size.height + 100
                    }
                }
            }
        }
    }
} 