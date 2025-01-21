import Foundation
import Auth0
import SwiftUI
import UIKit

extension Notification.Name {
    static let userLoggedOut = Notification.Name("userLoggedOut")
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userProfile: UserProfile?
    @Published var error: Error?
    @Published var isLoading = false
    @Published var profileImage: Image?
    @Published var localUsername: String = ""
    
    private var credentials: Credentials?
    private var credentialsManager = CredentialsManager(authentication: Auth0.authentication())
    private var currentAuth: Auth0.WebAuth?
    private var retryCount = 0
    private let maxRetries = 2
    private(set) var accessToken: String?
    
    static let shared = AuthenticationManager()
    private let auth0Domain = "clc-collective.us.auth0.com"
    private let auth0ClientId = "0Z9IJiMLgoJIKfP7XreZDZsmTmsxBQ2H"
    
    #if DEBUG
    static let preview: AuthenticationManager = {
        let manager = AuthenticationManager()
        manager.isAuthenticated = false
        return manager
    }()
    #endif
    
    private init() {}
    
    func login() {
        isLoading = true
        let webAuth = Auth0
            .webAuth()
            .scope("openid profile email")
            .audience("https://\(auth0Domain)/api/v2/")
            .useEphemeralSession()
            .parameters([
                "prompt": "login"
            ])
        
        currentAuth = webAuth
        
        webAuth.start { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.handleAuthenticationResult(result)
            }
        }
    }
    
    func logout() {
        // Save user data before clearing anything
        if let currentUserId = userProfile?.id {
            // Save profile image if it exists
            if let profileImage = profileImage {
                let controller = UIHostingController(rootView: profileImage)
                let view = controller.view
                let renderer = UIGraphicsImageRenderer(size: view?.bounds.size ?? CGSize(width: 100, height: 100))
                let image = renderer.image { _ in
                    view?.drawHierarchy(in: view?.bounds ?? .zero, afterScreenUpdates: true)
                }
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    print("Saving profile image for user: \(currentUserId)")
                    UserDefaults.standard.set(imageData, forKey: "profileImage_\(currentUserId)")
                }
            }
            
            // Save user data
            let userData: [String: Any] = [
                "userId": currentUserId,
                "email": userProfile?.email ?? "",
                "name": userProfile?.name ?? "",
                "pictureURL": userProfile?.picture?.absoluteString ?? "",
                "localUsername": localUsername,
                "lastLoginDate": Date().timeIntervalSince1970
            ]
            print("Saving user data for user: \(currentUserId)")
            UserDefaults.standard.set(userData, forKey: "savedUserData_\(currentUserId)")
            UserDefaults.standard.synchronize()
        }
        
        // Clear credentials and state
        _ = credentialsManager.clear()
        isAuthenticated = false
        credentials = nil
        userProfile = nil
        profileImage = nil
        localUsername = ""
        
        NotificationCenter.default.post(name: .userLoggedOut, object: nil)
    }
    
    private func fetchUserProfile() {
        guard let credentials = credentials else { return }
        
        Auth0
            .authentication(clientId: auth0ClientId, domain: auth0Domain)
            .userInfo(withAccessToken: credentials.accessToken)
            .start { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let profile):
                        self.userProfile = UserProfile(
                            id: profile.sub,
                            email: profile.email,
                            name: profile.name,
                            picture: profile.picture
                        )
                        
                        // Load saved user data first
                        self.loadUserData()
                        
                        // Then save any updates
                        self.saveUserData()
                        
                        // Load profile image if not already loaded by loadUserData
                        if self.profileImage == nil {
                            Task {
                                await self.loadProfileImage()
                            }
                        }
                        
                    case .failure(let error):
                        print("Failed to load profile: \(error.localizedDescription)")
                        self.error = error
                        self.isAuthenticated = false
                        self.userProfile = nil
                    }
                }
            }
    }
    
    @MainActor
    private func loadProfileImage() async {
        guard let userId = userProfile?.id else { return }
        
        // First try to load from cache
        if let imageData = UserDefaults.standard.data(forKey: "profileImage_\(userId)"),
           let uiImage = UIImage(data: imageData) {
            print("Loading profile image from cache for user: \(userId)")
            withAnimation(.easeInOut(duration: 0.3)) {
                self.profileImage = Image(uiImage: uiImage)
            }
            return
        }
        
        // If not in cache, try to load from Auth0 profile URL
        guard let profileURL = userProfile?.picture?.absoluteString,
              let url = URL(string: profileURL) else {
            print("No profile URL available for user: \(userId)")
            return
        }
        
        do {
            print("Fetching profile image from URL: \(profileURL)")
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let uiImage = UIImage(data: data) else {
                print("Failed to create UIImage from downloaded data")
                return
            }
            
            // Optimize image before caching
            let optimizedImage: UIImage
            if uiImage.size.width > 500 || uiImage.size.height > 500 {
                let size = CGSize(width: 500, height: 500)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                
                let renderer = UIGraphicsImageRenderer(size: size, format: format)
                optimizedImage = renderer.image { context in
                    uiImage.draw(in: CGRect(origin: .zero, size: size))
                }
            } else {
                optimizedImage = uiImage
            }
            
            // Convert to compressed JPEG data
            guard let optimizedData = optimizedImage.jpegData(compressionQuality: 0.7) else {
                print("Failed to compress image data")
                return
            }
            
            // Save to cache
            print("Saving profile image to cache for user: \(userId)")
            UserDefaults.standard.set(optimizedData, forKey: "profileImage_\(userId)")
            UserDefaults.standard.synchronize()
            
            // Update UI with smooth transition
            withAnimation(.easeInOut(duration: 0.3)) {
                self.profileImage = Image(uiImage: optimizedImage)
            }
            print("Successfully loaded and cached profile image")
            
        } catch {
            print("Failed to load profile image: \(error.localizedDescription)")
        }
    }
    
    func handleAuthenticationResult(_ result: WebAuthResult<Credentials>) {
        switch result {
        case .success(let credentials):
            self.credentials = credentials
            self.isAuthenticated = true
            self.error = nil
            
            // Fetch user profile
            _ = credentialsManager.store(credentials: credentials)
            fetchUserProfile()
            
            // Post notification for user authentication
            NotificationCenter.default.post(name: .userAuthenticated, object: nil)
            
        case .failure(let error):
            self.error = error
            self.isAuthenticated = false
            print("Login failed: \(error)")
        }
    }
    
    private func loadUserData() {
        guard let userId = userProfile?.id else { return }
        print("Loading user data for user: \(userId)")
        
        if let userData = UserDefaults.standard.dictionary(forKey: "savedUserData_\(userId)") {
            if let savedUsername = userData["localUsername"] as? String {
                print("Found saved username: \(savedUsername)")
                self.localUsername = savedUsername
            }
            
            // Load profile image
            if let imageData = UserDefaults.standard.data(forKey: "profileImage_\(userId)"),
               let uiImage = UIImage(data: imageData) {
                print("Found saved profile image")
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.profileImage = Image(uiImage: uiImage)
                }
            } else {
                print("No saved profile image found, loading from URL")
                Task {
                    await loadProfileImage()
                }
            }
        } else {
            print("No saved user data found for user: \(userId)")
        }
    }
    
    private func saveUserData() {
        guard let userProfile = userProfile else { return }
        print("Saving user data for user: \(userProfile.id)")
        
        let userData: [String: Any] = [
            "userId": userProfile.id,
            "email": userProfile.email ?? "",
            "name": userProfile.name ?? "",
            "pictureURL": userProfile.picture?.absoluteString ?? "",
            "localUsername": localUsername,
            "lastLoginDate": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(userData, forKey: "savedUserData_\(userProfile.id)")
        
        // Save current profile image if it exists
        if let profileImage = profileImage {
            let controller = UIHostingController(rootView: profileImage)
            let view = controller.view
            let renderer = UIGraphicsImageRenderer(size: view?.bounds.size ?? CGSize(width: 100, height: 100))
            let image = renderer.image { _ in
                view?.drawHierarchy(in: view?.bounds ?? .zero, afterScreenUpdates: true)
            }
            if let imageData = image.jpegData(compressionQuality: 0.7) {
                print("Saving profile image")
                UserDefaults.standard.set(imageData, forKey: "profileImage_\(userProfile.id)")
            }
        }
        
        UserDefaults.standard.synchronize()
    }
}

// Make UserProfile Sendable
struct UserProfile: Sendable {
    let id: String
    let email: String?
    let name: String?
    let picture: URL?
}

// Add extension to convert SwiftUI Image to UIImage
extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
} 