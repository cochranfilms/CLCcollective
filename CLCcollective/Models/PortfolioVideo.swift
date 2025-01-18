import Foundation

struct PortfolioVideo: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String?
    let thumbnailURL: String?
    let videoURL: String?
    let isLocalVideo: Bool
    
    static let featuredVideos: [PortfolioVideo] = [
        PortfolioVideo(
            id: "1",
            title: "DJ POPO Behind The Scenes",
            description: "Exclusive behind-the-scenes footage of DJ POPO's creative process",
            thumbnailURL: "DJ_Popo_Featured",
            videoURL: "DJ_POPO_BTS.mp4",
            isLocalVideo: true
        ),
        PortfolioVideo(
            id: "2",
            title: "Cursor Overview",
            description: "A comprehensive overview of the Cursor application",
            thumbnailURL: "Cursor_Thumb",
            videoURL: "Cursor_Overview.mp4",
            isLocalVideo: true
        )
    ]
    
    static let portfolioVideos: [PortfolioVideo] = [
        PortfolioVideo(
            id: "4",
            title: "Caribbean Currency Live",
            description: "Live broadcast production showcasing Caribbean music and culture",
            thumbnailURL: "caribbean_thumb",
            videoURL: "CaribbeanCurrency_LiveVibes.mp4",
            isLocalVideo: true
        ),
        PortfolioVideo(
            id: "5",
            title: "Cursor Overview",
            description: "A comprehensive overview of the Cursor application",
            thumbnailURL: "Cursor_Thumb",
            videoURL: "Cursor_Overview.mp4",
            isLocalVideo: true
        ),
        PortfolioVideo(
            id: "6",
            title: "Animation Demo",
            description: "Showcase of animation capabilities",
            thumbnailURL: "animation_thumb",
            videoURL: "Animation.mp4",
            isLocalVideo: true
        )
    ]
} 