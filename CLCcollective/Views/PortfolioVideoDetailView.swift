import SwiftUI
import AVKit

struct PortfolioVideoDetailView: View {
    let video: PortfolioVideo
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoPlayerViewModel()
    @State private var isPlaying = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Video Player
                if let videoURL = video.videoURL {
                    if video.isLocalVideo {
                        CustomVideoPlayer(videoId: videoURL, isLocalVideo: true)
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                    } else {
                        VideoPlayerControllerRepresentable(player: viewModel.player ?? AVPlayer())
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .onAppear {
                                if let url = URL(string: videoURL) {
                                    let player = AVPlayer(url: url)
                                    player.allowsExternalPlayback = true
                                    player.preventsDisplaySleepDuringVideoPlayback = true
                                    viewModel.player = player
                                    viewModel.player?.play()
                                }
                            }
                    }
                } else {
                    // Thumbnail as fallback
                    if let thumbnailURL = video.thumbnailURL {
                        Image(thumbnailURL)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                    }
                }
                
                // Title and Description
                VStack(alignment: .leading, spacing: 16) {
                    Text(video.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let description = video.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.black)
        .overlay(
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(),
            alignment: .topTrailing
        )
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

#Preview {
    PortfolioVideoDetailView(
        video: PortfolioVideo(
            id: "1",
            title: "Sample Video",
            description: "This is a sample video description that shows the full text without any truncation. It can be multiple lines long and will show all the details about the video content.",
            thumbnailURL: "sample_thumbnail",
            videoURL: "sample_video",
            isLocalVideo: true
        )
    )
} 