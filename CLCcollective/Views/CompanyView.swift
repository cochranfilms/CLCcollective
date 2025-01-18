import SwiftUI

struct CompanyView: View {
    @State private var selectedTab = 0
    @Namespace private var animation
    private let tabs = [
        ("Home", "house.fill"),
        ("Portfolio", "photo.fill"),
        ("Packages", "cube.fill"),
        ("Pricing", "dollarsign.circle.fill"),
        ("Billing", "creditcard.fill")
    ]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(selectedCompany: .constant(nil), selectedTab: $selectedTab)
                    .tag(0)
                    .transition(.opacity.combined(with: .slide))
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 88)
                    }
                
                WixPortfolioView(selectedTab: $selectedTab)
                    .tag(1)
                    .transition(.opacity.combined(with: .slide))
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 88)
                    }
                
                PackagesView(selectedTab: $selectedTab)
                    .tag(2)
                    .transition(.opacity.combined(with: .slide))
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 88)
                    }
                
                PricingView(selectedTab: $selectedTab)
                    .tag(3)
                    .transition(.opacity.combined(with: .slide))
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 88)
                    }
                
                InvoicesView(selectedTab: $selectedTab)
                    .tag(4)
                    .transition(.opacity.combined(with: .slide))
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 88)
                    }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: selectedTab)
            .ignoresSafeArea(.keyboard)
            .onReceive(NotificationCenter.default.publisher(for: .switchToBillingTab)) { _ in
                withAnimation {
                    selectedTab = 4 // Index of the Billing tab
                }
            }
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        TabButton(
                            title: tab.0,
                            icon: tab.1,
                            isSelected: selectedTab == index,
                            animation: animation
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                                selectedTab = index
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Color(hex: "#e6a33a")
                        .opacity(0.9)
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color(hex: "#e6a33a").opacity(0.5), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                .padding(.horizontal, 16)
            }
            .padding(.bottom, {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first
                else { return 0 }
                return window.safeAreaInsets.bottom
            }())
            .background(
                Color.clear
                    .ignoresSafeArea()
            )
            .zIndex(1)
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isSelected ? Color(hex: "#00a8a8") : .black)
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: 0.5, y: 0.5)
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: -0.5, y: -0.5)
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: 0.5, y: -0.5)
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: -0.5, y: 0.5)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#00a8a8") : .black)
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: 0.5, y: 0.5)
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: -0.5, y: -0.5)
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: 0.5, y: -0.5)
                    .shadow(color: isSelected ? .black : .clear, radius: 0, x: -0.5, y: 0.5)
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: "#00a8a8"))
                        .frame(width: 5, height: 5)
                        .matchedGeometryEffect(id: "TabIndicator", in: animation)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CompanyView()
        .environmentObject(AuthenticationManager.shared)
        .preferredColorScheme(.dark)
}
