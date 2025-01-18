import SwiftUI

struct TabItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let url: String
    let destination: AnyView
    
    static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func createHomeTab(selectedCompany: Binding<Company?>, selectedTab: Binding<Int>) -> TabItem {
        TabItem(
            title: "Home",
            icon: "house.fill",
            color: .brandTeal,
            url: "https://example.com/home",
            destination: AnyView(HomeView(selectedCompany: selectedCompany, selectedTab: selectedTab))
        )
    }
    
    static func createPortfolioTab(selectedTab: Binding<Int>) -> TabItem {
        TabItem(
            title: "Portfolio",
            icon: "photo.fill",
            color: .brandTeal,
            url: "https://example.com/portfolio",
            destination: AnyView(WixPortfolioView(selectedTab: selectedTab))
        )
    }
    
    static func createPackagesTab(selectedTab: Binding<Int>) -> TabItem {
        TabItem(
            title: "Packages",
            icon: "cube.fill",
            color: .brandTeal,
            url: "https://example.com/packages",
            destination: AnyView(PackagesView(selectedTab: selectedTab))
        )
    }
    
    static func createPricingTab(selectedTab: Binding<Int>) -> TabItem {
        TabItem(
            title: "Pricing",
            icon: "dollarsign.circle.fill",
            color: .brandTeal,
            url: "https://example.com/pricing",
            destination: AnyView(PricingView(selectedTab: selectedTab))
        )
    }
    
    static func createSocialTab(selectedTab: Binding<Int>) -> TabItem {
        TabItem(
            title: "Billing",
            icon: "creditcard.fill",
            color: .brandTeal,
            url: "https://example.com/billing",
            destination: AnyView(InvoicesView(selectedTab: selectedTab))
        )
    }
    
    static func createAllTabs(selectedCompany: Binding<Company?>, selectedTab: Binding<Int>) -> [TabItem] {
        [
            createHomeTab(selectedCompany: selectedCompany, selectedTab: selectedTab),
            createPortfolioTab(selectedTab: selectedTab),
            createPackagesTab(selectedTab: selectedTab),
            createPricingTab(selectedTab: selectedTab),
            createSocialTab(selectedTab: selectedTab)
        ]
    }
} 