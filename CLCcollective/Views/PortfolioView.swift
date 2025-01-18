import SwiftUI
import SafariServices

private enum Layout {
    static let maxWidth: CGFloat = 500
    static let cardPadding: CGFloat = 24
    static let contentSpacing: CGFloat = 20
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 50
    static let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
}

struct PortfolioView: View {
    private let cardSpacing: CGFloat = 24
    private let cardHeight: CGFloat = 350
    
    @State private var selectedCategory: PortfolioCategory?
    @State private var scrollOffset: CGFloat = 0
    @State private var isAppearing = false
    @State private var showingContactForm = false
    @Namespace private var animation
    @Binding var selectedTab: Int
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    SharedHeroBanner(selectedTab: $selectedTab)
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 50)
                    
                    // Main Content
                    VStack(spacing: 40) {
                        // Categories Grid
                        categoriesSection
                            .padding(.top, 20)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                        
                        // Portfolio Videos
                        portfolioSection
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 30)
                            
                        // Copyright
                        Text("© CLC Collective 2025")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
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
                // Set initial category to Event
                selectedCategory = PortfolioCategory.allCategories.first
            }
        }
        .onDisappear {
            isAppearing = false
        }
    }
    
    private var categoriesSection: some View {
        VStack(spacing: 24) {
            sectionHeader("Our Portfolio")
                .padding(.bottom, 16)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(PortfolioCategory.allCategories) { category in
                    CategoryCard(
                        title: category.title,
                        icon: category.icon,
                        isSelected: selectedCategory?.title == category.title
                    ) {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    private var portfolioSection: some View {
        VStack(spacing: 32) {
            // Show all videos if no category is selected, otherwise show selected category videos
            if let category = selectedCategory {
                VStack(spacing: 8) {
                    Text(category.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text(getCategoryDescription(for: category.title))
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#dca54e"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Videos for Selected Category
                VStack(spacing: 24) {
                    ForEach(category.videos) { video in
                        VideoGridItem(video: video)
                            .frame(width: Layout.cardWidth)
                    }
                }
            } else {
                // Show all videos when no category is selected
                VStack(spacing: 24) {
                    ForEach(PortfolioCategory.allCategories.flatMap(\.videos)) { video in
                        VideoGridItem(video: video)
                            .frame(width: Layout.cardWidth)
                    }
                }
            }
        }
    }
    
    private func getCategoryDescription(for category: String) -> String {
        switch category {
        case "Event":
            return "Professional event coverage and highlight reels"
        case "Commercial":
            return "High-quality commercial and promotional content"
        case "Podcast":
            return "Professional podcast production and interviews"
        case "Corporate":
            return "Corporate videos and business presentations"
        case "Live Broadcast":
            return "Live streaming and broadcast productions"
        case "CCA":
            return "Course Creator Academy educational content"
        default:
            return ""
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(Color(hex: "#dca54e"))
            .multilineTextAlignment(.center)
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .black : AppStyle.Colors.brandYellow)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .black : .white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(
                ZStack {
                    if isSelected {
                        Color(hex: "#dca54e")
                    } else {
                        GeometryReader { geo in
                            Image("Categories_BG")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                                .opacity(0.3)
                                .overlay(Color.black.opacity(0.3))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppStyle.Colors.brandYellow, lineWidth: 2)
            )
        }
    }
}

#Preview {
    PortfolioView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
} 