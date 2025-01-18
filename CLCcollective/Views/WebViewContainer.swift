import SwiftUI
import WebKit

struct WebViewContainer: View {
    let url: String
    @StateObject private var viewModel = WebViewModel()
    
    var body: some View {
        ZStack {
            CustomWebView(urlString: url, isLoading: $viewModel.isLoading)
                .frame(height: 400)
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brandTeal))
                    .scaleEffect(1.5)
            }
        }
    }
}

class WebViewModel: ObservableObject {
    @Published var isLoading = true
}

struct WebViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        WebViewContainer(url: "https://example.com")
    }
}

struct CustomWebView: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CustomWebView
        
        init(_ parent: CustomWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
} 