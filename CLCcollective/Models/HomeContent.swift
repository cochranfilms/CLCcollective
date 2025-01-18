import SwiftUI

struct HomeSection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let description: String?
    let imageName: String?
    let imageSystemName: String?
    
    init(title: String, subtitle: String? = nil, description: String? = nil, imageName: String? = nil, imageSystemName: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.imageName = imageName
        self.imageSystemName = imageSystemName
    }
}

extension HomeSection {
    static let sections = [
        HomeSection(
            title: "Professional\nVideo Production",
            subtitle: "Elevating Stories Through\nCinematic Excellence",
            imageName: nil
        ),
        HomeSection(
            title: "Welcome to CLC Collective",
            description: "CLC Collective is a dynamic media powerhouse dedicated to elevating stories and empowering creatives. With a focus on videography, business development, and film education, we bring a comprehensive approach to storytelling.",
            imageName: "clc_logo"
        ),
        HomeSection(
            title: "Back in FX",
            subtitle: "Professional Photography &\nCinematography Studio",
            imageName: "bfx_logo"
        ),
        HomeSection(
            title: "Cochran Films",
            subtitle: "Stories That Tell Themselves",
            imageName: "cochran_films_logo"
        ),
        HomeSection(
            title: "Course Creator Academy",
            subtitle: "The Hub for Beginner and\nIntermediate Creators",
            imageName: "course_creator_logo"
        ),
        HomeSection(
            title: "Entrepreneur Spotlight",
            subtitle: "Featuring JB Flickss - Visionary\nCreator & Entrepreneur",
            imageName: nil
        ),
        HomeSection(
            title: "Featured Video",
            subtitle: nil,
            imageName: "featured_video_thumb"
        )
    ]
} 