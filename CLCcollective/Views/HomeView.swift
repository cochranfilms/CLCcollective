import SwiftUI
import SafariServices
import AVKit

private enum Layout {
    static let maxWidth: CGFloat = 500
    static let cardPadding: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 50 // Minimum 44pt for touch targets
    static let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = UIColor(Color(hex: "#dca54e"))
        return safariVC
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct CameraAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: "camera.fill")
            .font(.system(size: 40))
            .foregroundColor(Color(hex: "#dca54e"))
            .rotationEffect(.degrees(isAnimating ? 10 : -10))
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct HomePageStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.zero)
            .edgesIgnoringSafeArea(.top)
            .background(Color.black)
            .preferredColorScheme(.dark)
            .ignoresSafeArea(.container, edges: .top)
    }
}

extension View {
    func homePageStyle() -> some View {
        modifier(HomePageStyleModifier())
    }
}

struct HomeView: View {
    @Binding var selectedCompany: Company?
    @State private var scrollOffset: CGFloat = 0
    @State private var showingContactForm = false
    @State private var isAppearing = false
    @State private var showingCochranFilms = false
    @State private var showingCourseCreator = false
    @State private var showingCostEstimator = false
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    
    // Pre-compute static content
    private let services = [
        ("video.fill", "Video Production", "Professional video content creation for all your needs"),
        ("mic.fill", "Live Production", "High-quality live event coverage and streaming"),
        ("film.fill", "Post Production", "Expert editing, color grading, and visual effects"),
        ("camera.fill", "Photography", "Professional event and commercial photography")
    ]
    
    private let educationServices = [
        ("person.2.fill", "In-Person", "Learn hands-on with industry professionals"),
        ("laptopcomputer", "Online Course", "Self-paced digital learning experience"),
        ("person.fill.viewfinder", "Job Shadow", "Real-world experience with professionals"),
        ("graduationcap.fill", "Film Education", "Expert instruction in film production")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    SharedHeroBanner(selectedTab: $selectedTab)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 50)
                    
                    // Main Content
                    LazyVStack(spacing: Layout.contentSpacing * 2) {
                        // Cochran Films Box
                        VStack(spacing: 16) {
                            sectionHeader("Cochran Films")
                            companyBox(
                                logo: "cochran_films_logo",
                                description: "We provide high-quality content in the form of photos and visual storytelling to promote and grow our client's business, brand, or personal endeavor.",
                                website: "https://www.cochranfilms.com"
                            )
                        }
                        .padding(.top, Layout.cardPadding)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 30)
                        
                        // Services Section
                        servicesSection
                            .padding(.top, 30)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // Stats Section
                        statsSection
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // YouTube Section
                        YouTubeSection()
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // Course Creator Academy Box
                        VStack(spacing: 16) {
                            sectionHeader("Course Creator Academy")
                            companyBox(
                                logo: "course_creator_logo",
                                description: "THE HUB FOR BEGINNER AND INTERMEDIATE CREATORS",
                                website: "https://www.coursecreatoracademy.org"
                            )
                        }
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 30)
                        
                        // Education Services Section
                        educationServicesSection
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // About Section
                        aboutSection
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // Contact Section
                        contactSection
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                            
                        // Featured On Section
                        FeaturedOnSection()
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                            
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
                    }
                    .padding(.vertical, Layout.cardPadding)
                    .padding(.horizontal, 16)
                }
            }
            .background(
                Image("background_image")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(Color.black.opacity(0.85))
                    .edgesIgnoringSafeArea(.all)
            )
            .ignoresSafeArea(.container, edges: .top)
            .sheet(isPresented: $showingContactForm) {
                ContactView()
            }
            .sheet(isPresented: $showingCostEstimator) {
                CostEstimatorView()
            }
        }
        .homePageStyle()
        .task {
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
        }
        .onDisappear {
            isAppearing = false
        }
    }
    
    private var servicesSection: some View {
        VStack(spacing: Layout.contentSpacing) {
            sectionHeader("Our Services")
                .padding(.bottom, 8)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(services, id: \.0) { service in
                    ServiceCard(
                        icon: service.0,
                        title: service.1,
                        description: service.2
                    )
                }
            }
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: Layout.contentSpacing) {
            // Stats
            HStack(spacing: 32) {
                StatItem(value: "200+", label: "Projects", icon: "folder.fill")
                StatItem(value: "50+", label: "Clients", icon: "person.2.fill")
                StatItem(value: "5+", label: "Years", icon: "clock.fill")
                StatItem(value: "BDC", label: "Degree", icon: "graduationcap.fill")
            }
            .padding(.vertical, 20)
            
            // Cost Estimator Button
            Button(action: {
                showingCostEstimator = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Build Custom Package")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.buttonHeight)
                .background(Color(hex: "#dca54e"))
                .cornerRadius(Layout.cornerRadius)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
        }
    }
    
    private var aboutSection: some View {
        VStack(spacing: Layout.contentSpacing) {
            sectionHeader("About Us")
            
            Text("CLC Collective is a dynamic media powerhouse dedicated to elevating stories and empowering creatives. With a focus on videography, business development, and film education, we bring a comprehensive approach to storytelling.")
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
    
    private var contactSection: some View {
        VStack(spacing: Layout.contentSpacing) {
            sectionHeader("Get in Touch")
            
            Button(action: {
                showingContactForm = true
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 20))
                    Text("Contact Us")
                        .font(.headline)
                }
                .foregroundColor(.black)
                .frame(width: 200, height: Layout.buttonHeight)
                .background(AppStyle.Colors.brandYellow)
                .cornerRadius(Layout.cornerRadius)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: title == "Course Creator Academy" ? 28 : 32, weight: .bold))
            .foregroundColor(Color(hex: "#dca54e"))
            .frame(maxWidth: .infinity, alignment: .center)
            .minimumScaleFactor(0.75)
            .lineLimit(1)
    }
    
    private func companyBox(logo: String, description: String, website: String) -> some View {
        VStack(spacing: 20) {
            Image(logo)
                .resizable()
                .scaledToFit()
                .frame(height: 80)
            
            Text(description)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if website.contains("cochranfilms") {
                    showingCochranFilms = true
                } else if website.contains("coursecreatoracademy") {
                    showingCourseCreator = true
                }
            }) {
                Text("Visit Website")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "#dca54e"))
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#dca54e"), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .sheet(isPresented: $showingCochranFilms) {
            if let url = URL(string: "https://www.cochranfilms.com") {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $showingCourseCreator) {
            if let url = URL(string: "https://www.coursecreatoracademy.org") {
                SafariView(url: url)
            }
        }
    }
    
    private var socialLinks: some View {
        HStack(spacing: 40) {
            SocialLink(imageName: "facebook", url: "https://www.facebook.com/cochranfilmsllc")
            SocialLink(imageName: "instagram", url: "https://www.instagram.com/cochran.films")
            SocialLink(imageName: "linkedin", url: "https://www.linkedin.com/company/cochranfilms")
        }
    }
    
    private var educationServicesSection: some View {
        VStack(spacing: Layout.contentSpacing) {
            sectionHeader("Our Services")
                .padding(.bottom, 8)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(educationServices, id: \.0) { service in
                    ServiceCard(
                        icon: service.0,
                        title: service.1,
                        description: service.2
                    )
                }
            }
        }
    }
}

struct ServiceCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(AppStyle.Colors.brandYellow)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .shadow(color: Color.white.opacity(0.1), radius: 2, x: 0, y: -1)
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 4)
                )
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 50)
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .background(Color.black.opacity(0.5))
        .cornerRadius(Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .strokeBorder(AppStyle.Colors.brandYellow.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppStyle.Colors.brandYellow)
                .frame(height: 30)
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppStyle.Colors.brandYellow)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.8))
        }
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

#Preview {
    HomeView(selectedCompany: .constant(nil), selectedTab: .constant(0))
        .preferredColorScheme(.dark)
} 
