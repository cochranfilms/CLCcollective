import SwiftUI
import AVKit

struct InlineVideoPlayer: View {
    let videoURL: String
    let isLocalVideo: Bool
    @Binding var isPlaying: Bool
    
    var body: some View {
        CustomVideoPlayer(videoId: videoURL, isLocalVideo: isLocalVideo)
            .aspectRatio(16/9, contentMode: .fit)
    }
}

#Preview {
    InlineVideoPlayer(
        videoURL: "sample_video",
        isLocalVideo: true,
        isPlaying: .constant(true)
    )
    .frame(height: 300)
    .preferredColorScheme(.dark)
} 