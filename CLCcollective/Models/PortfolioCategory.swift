import Foundation

struct PortfolioCategory: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let icon: String
    var videos: [PortfolioVideo] = []
    
    static let allCategories: [PortfolioCategory] = [
        PortfolioCategory(
            title: "Event",
            icon: "calendar",
            videos: [
                PortfolioVideo(
                    id: "7",
                    title: "BNG Halloween Event",
                    description: "Special Halloween event coverage and highlights",
                    thumbnailURL: "BNG_Halloween_Thumb",
                    videoURL: "BNG_Halloween.mp4",
                    isLocalVideo: true
                )
            ]
        ),
        PortfolioCategory(
            title: "Commercial",
            icon: "cart",
            videos: [
                PortfolioVideo(
                    id: "2",
                    title: "Product Launch",
                    description: "Cinematic commercial for new product release",
                    thumbnailURL: "commercial_thumb",
                    videoURL: "commercial_video",
                    isLocalVideo: true
                )
            ]
        ),
        PortfolioCategory(
            title: "Podcast",
            icon: "mic",
            videos: [
                PortfolioVideo(
                    id: "8",
                    title: "T-Pain Interview Part 2",
                    description: "In-depth conversation with Grammy award-winning artist",
                    thumbnailURL: "TPain_Thumb",
                    videoURL: "T-Pain_Part2FINAL.mp4",
                    isLocalVideo: true
                )
            ]
        ),
        PortfolioCategory(
            title: "Corporate",
            icon: "building.2",
            videos: [
                PortfolioVideo(
                    id: "4",
                    title: "Company Overview",
                    description: "Corporate video showcasing company culture and values",
                    thumbnailURL: "corporate_thumb",
                    videoURL: "corporate_video",
                    isLocalVideo: true
                )
            ]
        ),
        PortfolioCategory(
            title: "Live Broadcast",
            icon: "antenna.radiowaves.left.and.right",
            videos: [
                PortfolioVideo(
                    id: "1",
                    title: "Caribbean Currency Live",
                    description: "Live broadcast production showcasing Caribbean music and culture",
                    thumbnailURL: "caribbean_thumb",
                    videoURL: "CaribbeanCurrency_LiveVibes.mp4",
                    isLocalVideo: true
                ),
                PortfolioVideo(
                    id: "5",
                    title: "DJ Popo Live Performance",
                    description: "Live performance and scratch master showcase",
                    thumbnailURL: "DJ_Popo_Thumb1",
                    videoURL: "Scratch_Master_DJPOPO.mp4",
                    isLocalVideo: true
                )
            ]
        ),
        PortfolioCategory(
            title: "CCA",
            icon: "graduationcap.fill",
            videos: [
                PortfolioVideo(
                    id: "6",
                    title: "Welcome to Course Creator Academy",
                    description: "Introduction to our comprehensive film education program",
                    thumbnailURL: "Welcome_Thumb2",
                    videoURL: "Welcoming To CCA.mp4",
                    isLocalVideo: true
                )
            ]
        )
    ]
} 