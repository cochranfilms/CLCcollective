import SwiftUI
import AVKit

struct VideoGridItem: View {
    let video: PortfolioVideo
    @State private var isPlaying = false
    @StateObject private var viewModel = VideoPlayerViewModel()
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            // Video Container
            ZStack {
                if isPlaying {
                    CustomVideoPlayer(videoId: video.videoURL ?? "", isLocalVideo: video.isLocalVideo)
                        .aspectRatio(16/9, contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Thumbnail
                    if let thumbnailURL = video.thumbnailURL {
                        Image(thumbnailURL)
                            .resizable()
                            .aspectRatio(16/9, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                Button(action: {
                                    isPlaying = true
                                }) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.white)
                                        .frame(width: 100, height: 100)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                            )
                    }
                }
            }
            .frame(height: (UIScreen.main.bounds.width - 64) * 9/16)
            
            VStack(alignment: .center, spacing: 12) {
                Text(video.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                if let description = video.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    showingDetail = true
                }) {
                    Text("Read More")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(AppStyle.Colors.brandYellow)
                        .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppStyle.Colors.brandYellow, lineWidth: 2)
        )
        .sheet(isPresented: $showingDetail) {
            PortfolioVideoDetailView(video: video)
        }
        .onDisappear {
            isPlaying = false
            viewModel.cleanup()
        }
    }
}

#Preview {
    VideoGridItem(
        video: PortfolioVideo(
            id: "1",
            title: "Sample Video",
            description: "This is a sample video description that spans multiple lines to test the layout.",
            thumbnailURL: "sample_thumbnail",
            videoURL: "sample_video",
            isLocalVideo: true
        )
    )
    .preferredColorScheme(.dark)
    .padding()
    .background(Color.black)
} 