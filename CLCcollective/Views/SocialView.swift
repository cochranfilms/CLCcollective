import SwiftUI

private enum Layout {
    static let maxWidth: CGFloat = 500
    static let cardPadding: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 50
    static let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
}

struct SocialView: View {
    @State private var isAppearing = false
    @State private var showingContactForm = false
    @Binding var selectedTab: Int
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    SharedHeroBanner(selectedTab: $selectedTab)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 50)
                    
                    // Main Content
                    VStack(spacing: Layout.contentSpacing) {
                        // Social Media Links Section
                        LazyVStack(spacing: Layout.contentSpacing * 1.5) {
                            // YouTube
                            SocialCard(
                                title: "YouTube",
                                icon: "play.rectangle.fill",
                                description: "Watch our latest productions and video content",
                                nativeURL: "youtube://www.youtube.com/@cochranfilmsllc",
                                webURL: "https://www.youtube.com/@cochranfilmsllc"
                            )
                            
                            // Instagram
                            SocialCard(
                                title: "Instagram",
                                icon: "camera.fill",
                                description: "Follow us for behind-the-scenes content and latest updates",
                                nativeURL: "instagram://user?username=cochran.films",
                                webURL: "https://www.instagram.com/cochran.films"
                            )
                            
                            // Facebook
                            SocialCard(
                                title: "Facebook",
                                icon: "person.2.fill",
                                description: "Join our community and stay connected",
                                nativeURL: "fb://profile/cochranfilmsllc",
                                webURL: "https://www.facebook.com/cochranfilmsllc"
                            )
                            
                            // LinkedIn
                            SocialCard(
                                title: "LinkedIn",
                                icon: "network",
                                description: "Connect with our professional network",
                                nativeURL: "linkedin://company/cochranfilms",
                                webURL: "https://www.linkedin.com/company/cochranfilms"
                            )
                            
                            // Twitter/X
                            SocialCard(
                                title: "Twitter/X",
                                icon: "message.fill",
                                description: "Stay updated with our latest news and announcements",
                                nativeURL: "twitter://user?screen_name=cochranfilms",
                                webURL: "https://x.com/cochranfilms"
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // Copyright
                        Text("© CLC Collective 2025")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                    }
                    .padding(.vertical, Layout.cardPadding)
                }
            }
            .background(
                Image("background_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(Color.black.opacity(0.7))
                    .edgesIgnoringSafeArea(.all)
            )
            .ignoresSafeArea(.container, edges: .top)
            .sheet(isPresented: $showingContactForm) {
                ContactView()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
        }
    }
    
    private var socialLinks: some View {
        HStack(spacing: 40) {
            SocialLink(imageName: "facebook", url: "https://www.facebook.com/cochranfilmsllc")
            SocialLink(imageName: "instagram", url: "https://www.instagram.com/cochran.films")
            SocialLink(imageName: "linkedin", url: "https://www.linkedin.com/company/cochranfilms")
        }
    }
}

struct SocialCard: View {
    let title: String
    let icon: String
    let description: String
    let nativeURL: String
    let webURL: String
    @State private var showingSafariView = false
    
    var body: some View {
        Button(action: {
            if let nativeURL = URL(string: nativeURL),
               UIApplication.shared.canOpenURL(nativeURL) {
                UIApplication.shared.open(nativeURL)
            } else {
                showingSafariView = true
            }
        }) {
            VStack(alignment: .leading, spacing: Layout.contentSpacing) {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(AppStyle.Colors.brandYellow)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .shadow(color: Color.white.opacity(0.1), radius: 2, x: 0, y: -1)
                                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .threeDStyle(startColor: .white, endColor: .white)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppStyle.Colors.brandYellow)
                }
            }
            .padding(Layout.cardPadding)
            .background(Color.black.opacity(0.3))
            .cornerRadius(Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .strokeBorder(AppStyle.Colors.brandYellow.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .sheet(isPresented: $showingSafariView) {
            if let url = URL(string: webURL) {
                SafariView(url: url)
            }
        }
    }
}

#Preview {
    SocialView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
} 