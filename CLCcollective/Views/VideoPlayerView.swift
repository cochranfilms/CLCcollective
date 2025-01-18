import SwiftUI
import WebKit
import AVKit

struct VideoPlayerView: View {
    let videoId: String
    let isLocalVideo: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if isLocalVideo {
            localVideoPlayer
        } else {
            youtubePlayer
        }
    }
    
    private var localVideoPlayer: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let _ = Bundle.main.url(forResource: videoId, withExtension: nil) {
                CustomVideoPlayer(videoId: videoId, isLocalVideo: true)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
    
    private var youtubePlayer: some View {
        ZStack {
            VideoWebView(url: youtubeEmbedURL)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
    
    private var youtubeEmbedURL: URL {
        URL(string: "https://www.youtube.com/embed/\(videoId)")!
    }
}

struct VideoWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

#Preview {
    VideoPlayerView(videoId: "Wgv1y8bE8EU", isLocalVideo: false)
} 