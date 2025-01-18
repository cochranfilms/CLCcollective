import SwiftUI
import AVKit
import SafariServices
import WebKit

struct YouTubeSection: View {
    @State private var isPlaying = false
    @State private var isLoading = true
    private let videoTitle = "Cam Newton Talks Football, Youth Development, and the Future at Pylon 7v7 Tournament"
    private let videoDescription = "In this exclusive interview, Cam discusses his mission to inspire the next generation of athletes, the importance of mentorship, and how events like Pylon 7v7 shape the future of the game."
    private let videoId = "o1q-o-Mb3hc"
    
    var body: some View {
        VStack(spacing: 32) {
            // Section Header
            Text("Featured on YouTube")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#dca54e"))
                .frame(maxWidth: .infinity, alignment: .center)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            
            // Video Card
            VStack(spacing: 16) {
                ZStack {
                    if isPlaying {
                        ZStack {
                            AutoplayYouTubePlayer(videoId: videoId, isLoading: $isLoading)
                                .frame(maxWidth: .infinity)
                                .aspectRatio(16/9, contentMode: .fit)
                                .cornerRadius(12)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                            }
                        }
                        .overlay(
                            Button(action: {
                                isLoading = true
                                isPlaying = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8),
                            alignment: .topTrailing
                        )
                    } else {
                        Button(action: {
                            isLoading = true
                            isPlaying = true
                        }) {
                            ZStack {
                                AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/maxresdefault.jpg")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(16/9, contentMode: .fit)
                                } placeholder: {
                                    Rectangle()
                                        .foregroundColor(.black.opacity(0.3))
                                        .aspectRatio(16/9, contentMode: .fit)
                                }
                                .cornerRadius(12)
                                
                                Image(systemName: "play.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                    .frame(width: 100, height: 100)
                                    .background(Circle().fill(Color.red.opacity(0.8)))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                VStack(spacing: 12) {
                    Text(videoTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(videoDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .padding(.vertical, 16)
            .background(
                Color.black.opacity(0.3)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
}

struct AutoplayYouTubePlayer: UIViewRepresentable {
    let videoId: String
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let embedUrl = "https://www.youtube.com/embed/\(videoId)?playsinline=1&autoplay=1&rel=0"
        if let url = URL(string: embedUrl) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
        webView.configuration.userContentController.removeAllUserScripts()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: AutoplayYouTubePlayer
        
        init(_ parent: AutoplayYouTubePlayer) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

#Preview {
    YouTubeSection()
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
} 