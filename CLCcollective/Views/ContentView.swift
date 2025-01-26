import SwiftUI

struct ContentView: View {
    @StateObject private var projectViewModel = ProjectViewModel.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedCompany: Company?
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabItem.createAllTabs(
                selectedCompany: $selectedCompany,
                selectedTab: $selectedTab
            )) { tab in
                tab.destination
                    .smoothTransition()
                    .tabItem {
                        Image(systemName: tab.icon)
                        Text(tab.title)
                    }
                    .tag(tab.id)
            }
        }
        .environmentObject(authManager)
        .environmentObject(projectViewModel)
        .accentColor(Color(hex: "#dca54e"))
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .onAppear {
            setupTabBarAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userLoggedOut)) { _ in
            selectedTab = 0 // Switch to home tab
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToBillingTab)) { _ in
            selectedTab = 4 // Switch to billing tab
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#dca54e"))
        
        // Add shadow to tab bar
        appearance.shadowColor = .black
        appearance.shadowImage = UIImage()
        
        // Customize the unselected item color with spring animation
        appearance.stackedLayoutAppearance.normal.iconColor = .black
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        // Customize the selected item color with spring animation
        appearance.stackedLayoutAppearance.selected.iconColor = .white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold)
        ]
        
        // Apply smooth transitions
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            UITabBar.appearance().isTranslucent = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationManager.shared)
    }
} 
