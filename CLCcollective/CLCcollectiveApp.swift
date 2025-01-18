import SwiftUI

@main
struct CLCcollectiveApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
