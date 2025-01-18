import SwiftUI
import AVKit

class SmoothVideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    
    func setupPlayer(url: URL) {
        player = AVPlayer(url: url)
        player?.play()
    }
    
    func cleanup() {
        player?.pause()
        player = nil
    }
    
    deinit {
        cleanup()
    }
}

struct SmoothVideoPlayer: View {
    let videoURL: URL
    @StateObject private var viewModel = SmoothVideoPlayerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if let player = viewModel.player {
                    VideoPlayer(player: player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(maxWidth: geometry.size.width)
                }
            }
        }
        .onAppear {
            viewModel.setupPlayer(url: videoURL)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

#Preview {
    SmoothVideoPlayer(videoURL: URL(string: "https://example.com/video.mp4")!)
        .preferredColorScheme(.dark)
} 