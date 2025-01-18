import Foundation

struct Package: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let price: Int
    let videoOption: String
    let podcastOption: String
    let additionalFeatures: [String]
    
    // Implement hash(into:) for Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement == for Hashable conformance
    static func == (lhs: Package, rhs: Package) -> Bool {
        lhs.id == rhs.id
    }
}

extension Package {
    static let allPackages = [
        Package(
            title: "Fast Frame",
            subtitle: "1 Month",
            description: "Perfect for: Quick-turnaround projects or businesses needing high-quality content in a short time.",
            price: 2500,
            videoOption: "Four professionally crafted 30-second to 1-minute videos tailored to your brand or project.",
            podcastOption: "Three fully produced 1-hour podcasts with industry-standard audio and editing.",
            additionalFeatures: [
                "24/7 availability to address your questions or project updates."
            ]
        ),
        Package(
            title: "Cinematic Spotlight",
            subtitle: "2 Months",
            description: "Ideal for: Brands ready to shine with consistent, impactful content over two months.",
            price: 4800,
            videoOption: "Six expertly produced 30-second to 1-minute videos designed to captivate your audience.",
            podcastOption: "Five fully produced 1-hour+ podcasts with impeccable audio quality.",
            additionalFeatures: [
                "24/7 availability to address your questions or project updates."
            ]
        ),
        Package(
            title: "Masterpiece Collection",
            subtitle: "3 Months",
            description: "Designed for: Clients looking for a sustained, professional touch to build their brand and leave a lasting impression.",
            price: 7000,
            videoOption: "Nine high-quality 30-second to 1-minute videos tailored to elevate your business or brand.",
            podcastOption: "Seven 1-2 hour podcasts with seamless editing and sound production.",
            additionalFeatures: [
                "24/7 availability to address your questions or project updates."
            ]
        )
    ]
} 