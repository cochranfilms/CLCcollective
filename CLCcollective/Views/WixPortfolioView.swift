import SwiftUI
import AVKit
import UIKit
import WebKit
import AVFoundation

struct VideoPlayerControllerRepresentable: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspect
        
        // Configure Picture-in-Picture
        controller.allowsPictureInPicturePlayback = false  // Disable PiP to prevent CFMessagePort error
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        
        // Force controls to always be visible
        controller.requiresLinearPlayback = false
        controller.updatesNowPlayingInfoCenter = false
        
        // Add custom playback settings
        if let playerItem = player.currentItem {
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            let bufferDuration: TimeInterval = 5.0
            playerItem.preferredForwardBufferDuration = bufferDuration
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
        uiViewController.showsPlaybackControls = true
    }
}

// Move VideoPlayerViewModel to the top level
class WixVideoPlayerViewModel: NSObject, ObservableObject {
    @Published var isLoading = true
    @Published var error: Error?
    private var urlSession: URLSession?
    private var dataTask: URLSessionDataTask?
    private let logger = AppLogger.shared
    private var playerItemObserver: NSKeyValueObservation?
    private var playerBufferEmptyObserver: NSKeyValueObservation?
    
    @MainActor
    func loadVideo(url: URL) {
        // Cancel any existing data task
        dataTask?.cancel()
        
        Task {
            do {
                logger.info("Loading video from URL: \(url.absoluteString)", category: .video)
                isLoading = true
                error = nil
                
                // Create URLSession configuration with custom headers and longer timeout
                let config = URLSessionConfiguration.default
                let requestTimeout: TimeInterval = 30
                config.timeoutIntervalForRequest = requestTimeout
                let resourceTimeout: TimeInterval = 300
                config.timeoutIntervalForResource = resourceTimeout
                config.httpAdditionalHeaders = [
                    "wix-site-id": WixConfig.siteId,
                    "Accept": "video/mp4,video/*;q=0.9,*/*;q=0.8",
                    "Accept-Encoding": "gzip, deflate, br",
                    "Connection": "keep-alive",
                    "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                    "Referer": "https://www.cochranfilms.com/"
                ]
                
                urlSession = URLSession(configuration: config)
                
                guard let session = urlSession else {
                    let error = NSError(domain: "VideoPlayer", code: -1, 
                                      userInfo: [NSLocalizedDescriptionKey: LocalizationKey.Video.errorPermissions.localized])
                    throw error
                }
                
                // Create a new data task
                let (_, response): (Data, URLResponse) = try await withCheckedThrowingContinuation { continuation in
                    let task = session.dataTask(with: url) { _, response, error in
                        if let error = error {
                            if (error as NSError).code == NSURLErrorCancelled {
                                // Handle cancellation separately
                                continuation.resume(throwing: NSError(domain: "VideoPlayer", 
                                                                   code: NSURLErrorCancelled,
                                                                   userInfo: [NSLocalizedDescriptionKey: "Video loading was cancelled"]))
                            } else {
                                continuation.resume(throwing: error)
                            }
                            return
                        }
                        
                        guard let response = response else {
                            continuation.resume(throwing: NSError(domain: "VideoPlayer",
                                                               code: -1,
                                                               userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                            return
                        }
                        
                        continuation.resume(returning: (Data(), response))
                    }
                    self.dataTask = task
                    task.resume()
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let error = NSError(domain: "VideoPlayer",
                                      code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: LocalizationKey.Video.errorPermissions.localized])
                    throw error
                }
                
                logger.info("Successfully loaded video", category: .video)
                Analytics.shared.track(.videoPlay, properties: AnalyticsProperties(["url": url.absoluteString]))
                self.isLoading = false
            } catch {
                if (error as NSError).code == NSURLErrorCancelled {
                    logger.info("Video loading cancelled", category: .video)
                } else {
                    logger.error("Video loading error: \(error.localizedDescription)", category: .video)
                    CrashReporter.shared.reportError(error, severity: .medium, context: "Video loading")
                    Analytics.shared.trackError(error, context: "Video loading")
                    self.error = error
                }
                self.isLoading = false
            }
        }
    }
    
    func observePlayerItem(_ playerItem: AVPlayerItem) {
        // Remove any existing observers
        playerItemObserver?.invalidate()
        playerBufferEmptyObserver?.invalidate()
        
        // Observe playback buffer empty status
        playerBufferEmptyObserver = playerItem.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isLoading = item.isPlaybackBufferEmpty
            }
        }
        
        // Observe if playback is likely to keep up
        playerItemObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.isLoading = !item.isPlaybackLikelyToKeepUp
            }
        }
    }
    
    func cleanup() {
        logger.debug("Cleaning up video player resources", category: .video)
        playerItemObserver?.invalidate()
        playerBufferEmptyObserver?.invalidate()
        dataTask?.cancel()
        dataTask = nil
        urlSession?.invalidateAndCancel()
        urlSession = nil
    }
    
    deinit {
        cleanup()
    }
}

enum WixPortfolioLayout {
    static let contentSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 20
}

struct WixPortfolioView: View {
    @StateObject private var portfolioService = WixPortfolioService()
    @State private var selectedCategory: String?
    @State private var isAppearing = false
    @State private var showingVideoPlayer = false
    @State private var selectedVideoURL: URL?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var selectedTab: Int
    private let logger = AppLogger.shared
    
    private var gridColumns: [GridItem] {
        let isCompact = horizontalSizeClass == .compact
        return [
            GridItem(.adaptive(minimum: isCompact ? 300 : 400, maximum: isCompact ? 400 : 500), spacing: 20)
        ]
    }
    
    private var allCategories: [String] {
        let categories = portfolioService.portfolioItems.compactMap { $0.data.category }
        return Array(Set(categories)).sorted()
    }
    
    private var filteredItems: [WixPortfolioItem] {
        guard let category = selectedCategory else {
            return portfolioService.portfolioItems
        }
        return portfolioService.portfolioItems.filter { $0.data.category == category }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        SharedHeroBanner(selectedTab: $selectedTab)
                            .opacity(isAppearing ? 1 : 0)
                            .offset(y: isAppearing ? 0 : 50)
                        
                        VStack(spacing: WixPortfolioLayout.contentSpacing) {
                            if !allCategories.isEmpty {
                                categoryFilterView
                            }
                            
                            // BTS Preview Card
                            BTSPreviewCard()
                                .padding(.horizontal, WixPortfolioLayout.cardPadding)
                                .opacity(isAppearing ? 1 : 0)
                                .offset(y: isAppearing ? 0 : 20)
                            
                            contentView
                        }
                        .padding(.vertical, WixPortfolioLayout.cardPadding)
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(backgroundView(geometry: geometry))
                .ignoresSafeArea(.container, edges: .top)
                .refreshable {
                    await portfolioService.fetchPortfolio()
                }
                
                if showingVideoPlayer, let url = selectedVideoURL {
                    WixVideoPlayerView(url: url, isPresented: $showingVideoPlayer)
                        .transition(.opacity)
                        .animation(.easeInOut, value: showingVideoPlayer)
                }
            }
        }
        .task(id: portfolioService.portfolioItems.isEmpty) {
            if portfolioService.portfolioItems.isEmpty {
                logger.info("Loading portfolio items", category: .portfolio)
                Analytics.shared.track(.portfolioView)
                await portfolioService.fetchPortfolio()
            }
        }
        .onAppear {
            logger.info("WixPortfolioView appeared", category: .userInterface)
            withAnimation(.easeOut(duration: 0.8)) {
                isAppearing = true
            }
        }
        .onDisappear {
            logger.info("WixPortfolioView disappeared", category: .userInterface)
            // Only reset appearance animation
            withAnimation {
                isAppearing = false
            }
        }
    }
    
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                CategoryButton(
                    title: LocalizationKey.Portfolio.categoryAll.localized,
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation {
                        logger.info("Selected 'All' category", category: .userInterface)
                        Analytics.shared.track(.categorySelect, properties: AnalyticsProperties(["category": "all"]))
                        selectedCategory = nil
                    }
                }
                
                ForEach(allCategories, id: \.self) { category in
                    CategoryButton(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation {
                            logger.info("Selected category: \(category)", category: .userInterface)
                            Analytics.shared.track(.categorySelect, properties: AnalyticsProperties(["category": category]))
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    private var contentView: some View {
        Group {
            if portfolioService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#dca54e")))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let error = portfolioService.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 44))
                        .foregroundColor(.red)
                        .accessibilityHidden(true)
                    Text("Failed to load portfolio")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task {
                            await portfolioService.fetchPortfolio()
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(Color(hex: "#dca54e"))
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 44))
                        .foregroundColor(Color(hex: "#dca54e"))
                        .accessibilityHidden(true)
                    Text("No portfolio items found")
                        .font(.headline)
                        .foregroundColor(.white)
                    if selectedCategory != nil {
                        Text("Try selecting a different category")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(filteredItems) { item in
                        PortfolioItemCard(
                            title: item.data.title ?? "Untitled Project",
                            description: item.data.description ?? "",
                            thumbnailUrl: item.data.thumbnailUrl,
                            videoUrl: item.data.playbackUrl,
                            onVideoTap: { url in
                                selectedVideoURL = url
                                showingVideoPlayer = true
                            }
                        )
                        .opacity(isAppearing ? 1 : 0)
                        .offset(y: isAppearing ? 0 : 50)
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func backgroundView(geometry: GeometryProxy) -> some View {
        Image("background_image")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(Color.black.opacity(0.7))
            .edgesIgnoringSafeArea(.all)
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(hex: "#dca54e") : Color.black.opacity(0.3))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "#dca54e"), lineWidth: isSelected ? 0 : 1)
                )
        }
        .accessibilityLabel("\(title) category")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityHint(isSelected ? "Selected" : "Double tap to select category")
    }
}

struct PortfolioItemCard: View {
    let title: String
    let description: String
    let thumbnailUrl: String?
    let videoUrl: String?
    let onVideoTap: (URL) -> Void
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @FocusState private var isTextFieldFocused: Bool
    
    private let logger = AppLogger.shared
    
    private func getWixImageUrl(_ wixUrl: String?) -> URL? {
        guard let wixUrl = wixUrl else { return nil }
        
        if wixUrl.hasPrefix("wix:image://") {
            let components = wixUrl.components(separatedBy: "/")
            if components.count >= 4 {
                let imagePath = components[3].components(separatedBy: "#").first ?? components[3]
                return URL(string: "https://static.wixstatic.com/media/\(imagePath)")
            }
        }
        return URL(string: wixUrl)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail/Video Container
            if let videoUrl = videoUrl, let url = URL(string: videoUrl) {
                ZStack {
                    if isPlaying, let player = player {
                        VideoPlayerControllerRepresentable(player: player)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .onDisappear {
                                stopPlayback()
                            }
                    } else {
                        // Thumbnail View
                        if let thumbnailUrl = getWixImageUrl(thumbnailUrl) {
                            AsyncImage(url: thumbnailUrl) { phase in
                                switch phase {
                                case .empty:
                                    Color.black
                                        .overlay(ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#dca54e"))))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure(_):
                                    Color.black
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    Color.black
                                }
                            }
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Color.black
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        // Play Button Overlay
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                            .shadow(radius: 8)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isPlaying {
                        stopPlayback()
                    } else {
                        startPlayback(url: url)
                    }
                }
            }
            
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                
                if !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#dca54e").opacity(0.3), lineWidth: 1)
        )
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func startPlayback(url: URL) {
        let player = AVPlayer(url: url)
        player.allowsExternalPlayback = false  // Disable external playback to prevent PiP issues
        player.preventsDisplaySleepDuringVideoPlayback = true
        
        if let playerItem = player.currentItem {
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            playerItem.preferredForwardBufferDuration = 5
        }
        
        self.player = player
        withAnimation {
            isPlaying = true
        }
        player.play()
    }
    
    private func stopPlayback() {
        player?.pause()
        player = nil
        withAnimation {
            isPlaying = false
        }
    }
}

struct WixVideoPlayerView: View {
    let url: URL
    @Binding var isPresented: Bool
    @StateObject private var viewModel = WixVideoPlayerViewModel()
    @State private var player: AVPlayer?
    @State private var timeObserver: Any?
    @Environment(\.dismiss) private var dismiss
    
    private func startPlayback() {
        setupPlayer()
        // Add a slight delay to ensure the view is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            player?.play()
        }
    }
    
    private func setupPlayer() {
        let p = AVPlayer(url: url)
        p.allowsExternalPlayback = false  // Disable external playback to prevent PiP issues
        p.preventsDisplaySleepDuringVideoPlayback = true
        
        // Configure player item
        if let playerItem = p.currentItem {
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            let bufferDuration: TimeInterval = 5.0
            playerItem.preferredForwardBufferDuration = bufferDuration
            viewModel.observePlayerItem(playerItem)
        }
        
        player = p
    }
    
    private func closePlayer() {
        player?.pause()
        player = nil
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        withAnimation {
            isPresented = false
            dismiss()
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    closePlayer()
                }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        closePlayer()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Close video player")
                    .padding()
                }
                
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#dca54e")))
                            .scaleEffect(1.5)
                        Text("Loading video...")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundColor(.red)
                            .accessibilityHidden(true)
                        Text("Failed to load video")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .textSelection(.enabled)
                        Button("Try Again") {
                            viewModel.loadVideo(url: url)
                        }
                        .buttonStyle(.bordered)
                        .tint(Color(hex: "#dca54e"))
                    }
                    .padding()
                } else if let player = player {
                    VideoPlayerControllerRepresentable(player: player)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .background(Color.black)
                        .ignoresSafeArea(.all)
                }
            }
        }
        .onAppear {
            viewModel.loadVideo(url: url)
            startPlayback()
        }
        .onDisappear {
            closePlayer()
            viewModel.cleanup()
        }
        .interactiveDismissDisabled()
    }
}

struct WixVideoWebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(WixConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(WixConfig.siteId, forHTTPHeaderField: "wix-site-id")
        webView.load(request)
    }
}

#Preview {
    WixPortfolioView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
} 
