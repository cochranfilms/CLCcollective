import SwiftUI
import AVKit

private struct AutoPlayVideoKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var autoPlayVideo: Bool {
        get { self[AutoPlayVideoKey.self] }
        set { self[AutoPlayVideoKey.self] = newValue }
    }
}

// Custom AVPlayer View
struct CustomAVPlayerView: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}

// Custom Slider for video progress
struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    init(value: Binding<Double>, in range: ClosedRange<Double>) {
        self._value = value
        self.range = range
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                
                // Progress track
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)), height: 4)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .offset(x: geometry.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 6)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let newValue = range.lowerBound + Double(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound)
                                value = max(range.lowerBound, min(newValue, range.upperBound))
                            }
                    )
            }
        }
        .frame(height: 24)
    }
}

// Time formatting function
func formatTime(_ timeInSeconds: Double) -> String {
    let hours = Int(timeInSeconds / 3600)
    let minutes = Int(timeInSeconds.truncatingRemainder(dividingBy: 3600) / 60)
    let seconds = Int(timeInSeconds.truncatingRemainder(dividingBy: 60))
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

class VideoPlayerViewModel: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading = true
    @Published var error: Error?
    @Published var showError = false
    @Published var isMuted = false
    @Published var isFullScreen = false
    
    private var timeObserverToken: Any?
    private var itemObserver: NSKeyValueObservation?
    private var audioSession: AVAudioSession?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers, .allowAirPlay, .defaultToSpeaker])
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
            try audioSession?.overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func setupPlayer(with url: URL) {
        // Configure audio session before setting up player
        setupAudioSession()
        
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player?.actionAtItemEnd = .pause
        
        // Ensure audio plays
        player?.volume = 1.0
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if self.duration == 0 {
                self.duration = playerItem.duration.seconds
            }
        }
        
        // Observe player item status
        itemObserver = playerItem.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.duration = item.duration.seconds
                case .failed:
                    self?.error = item.error
                    self?.showError = true
                    self?.isLoading = false
                default:
                    break
                }
            }
        }
        
        // Observe player end time
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidPlayToEndTime),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func toggleMute() {
        isMuted.toggle()
        player?.isMuted = isMuted
    }
    
    func replay() {
        seek(to: 0)
        if !isPlaying {
            togglePlayPause()
        }
    }
    
    @objc func playerItemDidPlayToEndTime() {
        isPlaying = false
        seek(to: 0)
    }
    
    func cleanup() {
        isPlaying = false
        player?.pause()
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        itemObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)
        
        // Clean up audio session
        do {
            try audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        player?.replaceCurrentItem(with: nil)
        player = nil
    }
    
    deinit {
        cleanup()
    }
}

struct CustomVideoPlayer: View {
    let videoId: String
    let isLocalVideo: Bool
    @StateObject private var viewModel = VideoPlayerViewModel()
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @GestureState private var dragOffset: CGFloat = 0
    @Environment(\.autoPlayVideo) private var autoPlayVideo
    
    private func setupControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation {
                showControls = false
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Video Layer
                if let url = isLocalVideo ? 
                    Bundle.main.url(forResource: videoId.replacingOccurrences(of: ".mp4", with: ""), withExtension: "mp4") :
                    URL(string: videoId) {
                    let asset = AVURLAsset(url: url)
                    let playerItem = AVPlayerItem(asset: asset)
                    CustomAVPlayerView(player: viewModel.player ?? AVPlayer(playerItem: playerItem))
                        .gesture(
                            DragGesture()
                                .updating($dragOffset) { value, state, _ in
                                    let translation = value.translation.width
                                    state = translation
                                    let seekTime = viewModel.currentTime + Double(translation / 500)
                                    viewModel.seek(to: max(0, min(seekTime, viewModel.duration)))
                                }
                        )
                        .onAppear {
                            // Only auto-play if enabled
                            if autoPlayVideo {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    viewModel.setupPlayer(with: url)
                                    viewModel.togglePlayPause()
                                }
                            } else {
                                viewModel.setupPlayer(with: url)
                            }
                        }
                        .onDisappear {
                            viewModel.cleanup()
                        }
                } else {
                    // Show error placeholder if video can't be loaded
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        Text("Video not available")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.7))
                }
                
                // Loading Indicator
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                
                // Controls Overlay
                if showControls {
                    controlsOverlay
                        .transition(.opacity)
                }
            }
            .background(Color.black)
            .alert("Playback Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "Failed to play video")
            }
        }
        .onAppear {
            if let url = isLocalVideo ? 
                Bundle.main.url(forResource: videoId.replacingOccurrences(of: ".mp4", with: ""), withExtension: "mp4") :
                URL(string: videoId) {
                viewModel.setupPlayer(with: url)
                setupControlsTimer()
            }
        }
        .onDisappear {
            viewModel.cleanup()
            controlsTimer?.invalidate()
        }
        .onTapGesture {
            withAnimation {
                showControls.toggle()
                if showControls {
                    setupControlsTimer()
                }
            }
        }
    }
    
    private var controlsOverlay: some View {
        VStack {
            // Top Bar
            HStack {
                Spacer()
                Button(action: viewModel.toggleMute) {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.white)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Center Play/Pause Button
            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Bottom Controls
            VStack(spacing: 8) {
                // Progress Slider
                CustomSlider(value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.seek(to: $0) }
                ), in: 0...max(viewModel.duration, 0.01))
                
                HStack {
                    // Time Labels
                    Text(formatTime(viewModel.currentTime))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Replay Button
                    Button(action: viewModel.replay) {
                        Image(systemName: "gobackward")
                            .foregroundColor(.white)
                    }
                    
                    // Play/Pause Button
                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    // Fullscreen Button
                    Button(action: { viewModel.isFullScreen.toggle() }) {
                        Image(systemName: viewModel.isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .foregroundColor(.white)
                    }
                    
                    Text(formatTime(viewModel.duration))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.black.opacity(0.7), .clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .font(.system(size: 14))
    }
}

#Preview {
    CustomVideoPlayer(videoId: "sample_video", isLocalVideo: true)
        .frame(height: 300)
        .preferredColorScheme(.dark)
} 