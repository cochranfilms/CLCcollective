import SwiftUI
import AVKit

struct FeaturedWorkCard: View {
    let item: FeaturedItem
    @State private var isPlaying = false
    @State private var showError = false
    @StateObject private var viewModel = VideoPlayerViewModel()
    @State private var showingDetail = false
    
    private let cardWidth: CGFloat = UIScreen.main.bounds.width * 0.85
    private let aspectRatio: CGFloat = 16/9
    
    private func getWixImageUrl(_ url: String) -> URL? {
        print("[Debug] Original thumbnail URL:", url)
        // Handle both formats of Wix image URLs
        if url.hasPrefix("wix:image://v1/") {
            // Remove the metadata part after #
            let components = url.components(separatedBy: "#")
            if let baseUrlPart = components.first {
                // Remove the wix:image://v1/ prefix
                let cleanPath = baseUrlPart.replacingOccurrences(of: "wix:image://v1/", with: "")
                // Convert to proper URL format
                let baseUrl = "https://static.wixstatic.com/media/"
                
                // For Wix URLs, we need to handle the path differently
                // The path should not include additional segments after the image ID
                let pathComponents = cleanPath.components(separatedBy: "/")
                let imageId = pathComponents.first ?? cleanPath
                
                // Create the final URL with proper encoding
                let finalUrl = baseUrl + imageId
                print("[Debug] Encoded Wix URL:", finalUrl)
                return URL(string: finalUrl)
            }
        } else if url.hasPrefix("https://static.wixstatic.com/") {
            print("[Debug] Direct Wix URL:", url)
            return URL(string: url)
        }
        print("[Debug] Failed to process URL")
        return nil
    }
    
    private func getThumbnailUrl() -> URL? {
        if let thumbnailUrl = item.thumbnailUrl {
            return getWixImageUrl(thumbnailUrl)
        }
        if let thumbnailImage = item.thumbnailImage {
            return getWixImageUrl(thumbnailImage)
        }
        return nil
    }
    
    var body: some View {
        let cardWidth = min(max(UIScreen.main.bounds.width - 32, 300), 600) // Set minimum and maximum width
        let aspectRatio: CGFloat = 16/9 // Fixed aspect ratio
        
        VStack(spacing: 16) {
            ZStack {
                if let thumbnailUrl = item.thumbnailUrl,
                   let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.black.opacity(0.3))
                                .aspectRatio(aspectRatio, contentMode: .fit)
                                .frame(width: cardWidth)
                                .cornerRadius(12)
                                .overlay(
                                    ProgressView()
                                        .tint(.white)
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(aspectRatio, contentMode: .fit)
                                .frame(width: cardWidth)
                                .cornerRadius(12)
                                .overlay(
                                    Button(action: {
                                        if item.playbackUrl != nil {
                                            isPlaying = true
                                        }
                                    }) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                            .frame(width: 100, height: 100)
                                            .background(Circle().fill(Color.black.opacity(0.6)))
                                    }
                                )
                        case .failure:
                            errorView
                        @unknown default:
                            errorView
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .frame(width: cardWidth)
                        .cornerRadius(12)
                        .overlay(
                            Text("No thumbnail available")
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(width: cardWidth, height: cardWidth / aspectRatio)
            
            VStack(alignment: .center, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                
                if let description = item.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                }
                
                if let category = item.category {
                    Text(category)
                        .font(.caption)
                        .foregroundColor(AppStyle.Colors.brandYellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(AppStyle.Colors.brandYellow.opacity(0.2))
                        )
                }
                
                Button(action: {
                    showingDetail = true
                }) {
                    Text("Read More")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppStyle.Colors.brandYellow)
                        .cornerRadius(8)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: cardWidth)
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppStyle.Colors.brandYellow, lineWidth: 2)
        )
        .sheet(isPresented: $showingDetail) {
            FeaturedWorkDetailView(item: item)
        }
    }
    
    private var errorView: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(.white)
            Text("Video not available")
                .font(.caption)
                .foregroundColor(.white)
        }
        .frame(width: cardWidth, height: cardWidth / aspectRatio)
        .background(Color.black.opacity(0.5))
        .cornerRadius(12)
    }
}

#if DEBUG
struct FeaturedWorkCard_Previews: PreviewProvider {
    static var previews: some View {
        FeaturedWorkCard(item: .preview())
            .previewLayout(.sizeThatFits)
            .background(Color.black)
    }
}
#endif

#Preview {
    FeaturedWorkCard(
        item: .preview(
            title: "Sample Video",
            description: "This is a sample video description that spans multiple lines to test the layout.",
            thumbnailImage: "sample_thumbnail",
            playbackUrl: "sample_video"
        )
    )
    .preferredColorScheme(.dark)
    .padding()
    .background(Color.black)
} 