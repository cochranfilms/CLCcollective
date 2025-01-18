import SwiftUI
import AVKit

struct PortfolioVideoPlayer: View {
    let videoURL: String
    let isLocalVideo: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Close button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                )
                        }
                        .padding()
                        
                        Spacer()
                    }
                    
                    // Video Player
                    CustomVideoPlayer(videoId: videoURL, isLocalVideo: isLocalVideo)
                        .aspectRatio(16/9, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.3), radius: 10)
                    
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    PortfolioVideoPlayer(
        videoURL: "sample_video",
        isLocalVideo: true
    )
} 