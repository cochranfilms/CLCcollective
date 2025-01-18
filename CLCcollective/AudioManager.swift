import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private var audioPlayer: AVAudioPlayer?
    
    func startBackgroundMusic() {
        guard let path = Bundle.main.path(forResource: "background_music", ofType: "mp3") else {
            print("Could not find audio file")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = 0 // Play only once
            audioPlayer?.volume = 0.5 // 50% volume
            audioPlayer?.play()
        } catch {
            print("Could not create audio player: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        audioPlayer?.stop()
    }
} 