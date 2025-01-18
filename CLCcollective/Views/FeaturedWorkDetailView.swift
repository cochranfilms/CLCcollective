import SwiftUI
import AVKit

struct FeaturedWorkDetailView: View {
    let item: FeaturedItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Video Player
                if let playbackUrl = item.playbackUrl, let url = URL(string: playbackUrl) {
                    VideoPlayerControllerRepresentable(player: viewModel.player ?? AVPlayer())
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .onAppear {
                            let player = AVPlayer(url: url)
                            player.allowsExternalPlayback = true
                            player.preventsDisplaySleepDuringVideoPlayback = true
                            viewModel.player = player
                            viewModel.player?.play()
                        }
                } else {
                    // Thumbnail as fallback
                    if let thumbnailUrl = item.thumbnailUrl ?? item.thumbnailImage,
                       let url = URL(string: thumbnailUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(16/9, contentMode: .fit)
                            case .failure:
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                    }
                }
                
                // Title and Description
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let description = item.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    
                    if let category = item.category {
                        Text(category)
                            .font(.subheadline)
                            .foregroundColor(AppStyle.Colors.brandYellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppStyle.Colors.brandYellow.opacity(0.2))
                            )
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
    FeaturedWorkDetailView(
        item: .preview(
            title: "Sample Video",
            description: "This is a sample video description that shows the full text without any truncation. It can be multiple lines long and will show all the details about the video content.",
            thumbnailImage: "sample_thumbnail",
            playbackUrl: "sample_video"
        )
    )
} 