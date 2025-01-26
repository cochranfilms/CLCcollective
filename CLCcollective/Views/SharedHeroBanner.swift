import SwiftUI
import Auth0

struct SharedHeroBanner: View {
    @State private var showingContactForm = false
    @State private var showingProfile = false
    @State private var showAIAssistant = false
    @EnvironmentObject private var authManager: AuthenticationManager
    @Binding var selectedTab: Int
    
    var body: some View {
        GeometryReader { geometry in
            let safeWidth = max(geometry.size.width, 300)
            let safeHeight = max(geometry.size.height, 200)
            
            ZStack {
                Image("Hero_Banner")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: safeWidth, height: safeHeight)
                    .blur(radius: 3)
                    .opacity(0.4)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.05),
                                Color.black.opacity(0.05),
                                Color.black.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        HStack {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.4),
                                    Color.black.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 30)
                            
                            Spacer()
                            
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0),
                                    Color.black.opacity(0.4)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 30)
                        }
                    )
                
                VStack(spacing: 16) {
                    Image("CLC_logo2")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: min(safeWidth * 0.8, 500))
                        .frame(minWidth: min(380, safeWidth * 0.9))
                        .padding(.top, UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?
                            .windows
                            .first?
                            .safeAreaInsets.top ?? 0)
                    
                    Text("Elevating stories & empowering creatives through videography, business, & film education.")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Button(action: {
                        showingContactForm = true
                    }) {
                        Text("Contact Us")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(AppStyle.Colors.brandYellow)
                            .cornerRadius(20)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 16)
                    
                    HStack(spacing: 40) {
                        SocialLink(imageName: "facebook", url: "https://www.facebook.com/cochranfilmsllc")
                        SocialLink(imageName: "instagram", url: "https://www.instagram.com/cochran.films")
                        SocialLink(imageName: "linkedin", url: "https://www.linkedin.com/company/cochranfilms")
                    }
                    .scaleEffect(0.7)
                    .padding(.top, 16)
                    
                    Text("© CLC Collective 2025")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if authManager.isAuthenticated {
                                authManager.logout()
                            } else {
                                authManager.login()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: authManager.isAuthenticated ? "rectangle.portrait.and.arrow.right" : "rectangle.portrait.and.arrow.forward")
                                    .font(.system(size: 16, weight: .medium))
                                Text(authManager.isAuthenticated ? "Sign Out" : "Sign In")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#dca54e"),
                                        Color(hex: "#dca54e").opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .shadow(color: Color(hex: "#dca54e").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(authManager.isLoading)
                        .opacity(authManager.isLoading ? 0.7 : 1.0)
                        
                        if authManager.isAuthenticated {
                            Button(action: { showingProfile = true }) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        if let profileImage = authManager.profileImage {
                                            profileImage
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .frame(width: 40, height: 40)
                                                .foregroundColor(Color(hex: "#dca54e"))
                                        }
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "#dca54e"), lineWidth: 2)
                                    )
                                    
                                    Text("Profile")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color(hex: "#dca54e"))
                                }
                            }
                        }
                        
                        // AI Assistant Button
                        Button(action: {
                            showAIAssistant.toggle()
                        }) {
                            VStack(spacing: 4) {
                                Image("Ai-logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .padding(0)
                                    .background(Color(hex: "#00B2B2"))
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "#dca54e"), lineWidth: 2)
                                    )
                                
                                Text("Ask Chat")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(hex: "#dca54e"))
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .frame(height: 600)
        .edgesIgnoringSafeArea(.top)
        .sheet(isPresented: $showingContactForm) {
            ContactView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showAIAssistant) {
            AIAssistantView(selectedTab: $selectedTab)
        }
    }
}

#if DEBUG
#Preview {
    SharedHeroBanner(selectedTab: .constant(0))
        .environmentObject(AuthenticationManager.preview)
        .environmentObject(ProjectViewModel.preview)
}
#endif 