import SwiftUI
import SafariServices

struct SocialLink: View {
    let imageName: String
    let url: String
    var iconSize: CGFloat = 48 // Default size if not specified
    @State private var showingSafariView = false
    @State private var isShaking = false
    
    private var nativeAppURL: URL? {
        switch imageName {
        case "facebook":
            return URL(string: "fb://profile/cochranfilmsllc")
        case "instagram":
            return URL(string: "instagram://user?username=cochran.films")
        case "linkedin":
            return URL(string: "linkedin://company/cochranfilms")
        default:
            return nil
        }
    }
    
    var body: some View {
        Button(action: {
            if let nativeURL = nativeAppURL,
               UIApplication.shared.canOpenURL(nativeURL) {
                UIApplication.shared.open(nativeURL)
            } else {
                showingSafariView = true
            }
        }) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .padding(16)
                .background(
                    Circle()
                        .stroke(Color(hex: "#dca54e"), lineWidth: 2.5)
                )
                .rotationEffect(.degrees(isShaking ? 5 : -5))
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isShaking
                )
        }
        .onAppear {
            isShaking = true
        }
        .sheet(isPresented: $showingSafariView) {
            if let webURL = URL(string: url) {
                SafariView(url: webURL)
            }
        }
    }
}

#Preview {
    HStack {
        SocialLink(imageName: "facebook", url: "https://www.facebook.com")
        SocialLink(imageName: "instagram", url: "https://www.instagram.com")
    }
    .preferredColorScheme(.dark)
    .padding()
    .background(Color.black)
} 