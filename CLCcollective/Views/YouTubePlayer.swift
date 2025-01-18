import SwiftUI
import WebKit

struct YouTubePlayer: View {
    let videoId: String
    @StateObject private var viewModel = YouTubeViewModel()
    
    var body: some View {
        ZStack {
            CustomWebView(urlString: "https://www.youtube.com/embed/\(videoId)", isLoading: $viewModel.isLoading)
                .frame(height: 300)
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandTeal))
                    .scaleEffect(1.5)
            }
        }
    }
}

class YouTubeViewModel: ObservableObject {
    @Published var isLoading = true
}

struct YouTubePlayer_Previews: PreviewProvider {
    static var previews: some View {
        YouTubePlayer(videoId: "dQw4w9WgXcQ")
    }
} 