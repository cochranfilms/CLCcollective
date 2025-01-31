import SwiftUI

struct AboutUsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isAppearing = false
    @Binding var selectedTab: Int
    
    private let headerHeight: CGFloat = 300
    private let maxWidth: CGFloat = 600
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Add SharedHeroBanner
                SharedHeroBanner(selectedTab: $selectedTab)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 50)
                
                // Add spacing here
                Spacer()
                    .frame(height: 32)  // Adjust this value to increase/decrease spacing
                
                // About Us Header with fixed height
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Image("about_header")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: headerHeight)
                            .clipped()
                            .overlay(Color.black.opacity(0.4))
                        
                        // Gradient Overlay
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0),
                                Color.black.opacity(0.9)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 200)
                        
                        // Title and Subtitle
                        VStack(spacing: 16) {
                            Text("About Cochran Films")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.brandGold)
                                .shadow(radius: 2)
                            
                            Text("Stories That Tell Themselves")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                                .opacity(0.9)
                        }
                        .padding(.bottom, 40)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 20)
                    }
                }
                .frame(height: headerHeight)
                
                // Content Sections
                VStack(spacing: 32) {
                    // Mission Statement
                    contentSection(title: "Our Mission") {
                        Text("At Cochran Films, our mission is to bring stories to life through the art of visual storytelling. We are dedicated to producing high-quality content that captures the essence of every moment—whether it's through film, photography, or videography. By combining creative vision and technical expertise, we aim to create emotionally resonant work that speaks to audiences and elevates brands.")
                    }
                    
                    // Company Story
                    contentSection(title: "Our Story") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Founded in Douglasville, GA, Cochran Films is a creative powerhouse built on a passion for storytelling and innovation. As part of the CLC Collective, we draw from years of industry experience to push the boundaries of media production. Our journey began with a commitment to excellence and a vision to craft stories that inspire, inform, and connect.")
                            
                            Text("Over the years, we've collaborated with businesses, artists, and professionals to create projects that leave lasting impressions.")
                        }
                    }
                    
                    // Vision & Values
                    contentSection(title: "Vision & Values") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Our vision is to redefine storytelling by merging authenticity with creativity. We believe that great stories tell themselves when honesty, passion, and artistry converge.")
                            
                            Text("Our core values are rooted in integrity, collaboration, and innovation. We prioritize creating a welcoming environment where creativity can flourish, and we strive to empower others by sharing our expertise through education and mentorship.")
                            
                            Text("At Cochran Films, we're not just creating content—we're building a legacy of impactful storytelling.")
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Team Section
                    contentSection(title: "Our Team") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("The talented professionals at Cochran Films bring diverse expertise to every project, ensuring a collaborative and seamless creative process. Led by Cody Cochrane, our team includes skilled filmmakers, videographers, editors, and producers who are dedicated to delivering top-tier results. We pride ourselves on our attention to detail and commitment to understanding our clients' vision, transforming ideas into cinematic works of art.")
                            
                            Text("Our team's passion for storytelling is what sets us apart, creating a production experience that is both engaging and rewarding.")
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Services Section
                    contentSection(title: "Our Services") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Cochran Films offers a comprehensive range of services designed to meet the unique needs of clients in various industries. We specialize in:")
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach([
                                    "Event Coverage: Capture important moments with expertly produced event videos, including highlights, recaps, and full-session recordings.",
                                    "Live Production: Multi-camera productions with professional edits to deliver dynamic and engaging live experiences.",
                                    "Green Screen Production: Studio rentals and custom green screen sessions for creative flexibility.",
                                    "Podcast Production: Full-service podcast recording with high-quality visuals and audio.",
                                    "Real Estate Packages: Monthly packages tailored to showcase properties with high-end video tours, drone footage, and social media content.",
                                    "Content Packages: Professional video and podcast production plans designed to provide brands with consistent, high-impact content over one to three months."
                                ], id: \.self) { service in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundColor(.brandGold)
                                        Text(service)
                                    }
                                }
                            }
                            .padding(.leading, 8)
                            
                            Text("With every project, we deliver polished results that reflect your story, vision, and brand identity. Let us bring your ideas to life with creativity and professionalism.")
                                .padding(.top, 8)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Copyright and Privacy Policy
                    VStack(spacing: 8) {
                        Text("© CLC Collective 2025")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: {
                            if let url = URL(string: "https://www.cochranfilms.com/privacy-policy") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Privacy Policy")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#dca54e"))
                                .underline()
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .padding(.bottom, UIApplication.shared.firstKeyWindow?.safeAreaInsets.bottom ?? 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 32)
            }
        }
        .background(
            Image("background_image")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.85))
        )
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.brandGold)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
        }
    }
    
    private func contentSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.brandGold)
            
            content()
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
        }
        .frame(maxWidth: maxWidth)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.brandGold.opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(isAppearing ? 1 : 0)
        .offset(y: isAppearing ? 0 : 20)
    }
}

struct AboutUsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutUsView(selectedTab: .constant(5))
    }
} 