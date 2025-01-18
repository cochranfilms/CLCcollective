import Foundation

public struct FeaturedItemWrapper: Codable {
    public let id: String
    public let dataCollectionId: String
    public let data: FeaturedItem
}

public struct FeaturedItem: Identifiable, Codable {
    public let id: String
    public let title: String
    public let description: String?
    public let category: String?
    public let thumbnailImage: String?
    public let thumbnailUrl: String?
    public let playbackUrl: String?
    public let video: String?
    public let linkFeaturedTitle: String?
    public let _owner: String?
    public let _createdDate: WixCreatedDate?
    public let _updatedDate: WixCreatedDate?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case description
        case category
        case thumbnailImage
        case thumbnailUrl
        case playbackUrl
        case video
        case linkFeaturedTitle = "link-featured-title"
        case _owner
        case _createdDate
        case _updatedDate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        thumbnailImage = try container.decodeIfPresent(String.self, forKey: .thumbnailImage)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        playbackUrl = try container.decodeIfPresent(String.self, forKey: .playbackUrl)
        video = try container.decodeIfPresent(String.self, forKey: .video)
        linkFeaturedTitle = try container.decodeIfPresent(String.self, forKey: .linkFeaturedTitle)
        _owner = try container.decodeIfPresent(String.self, forKey: ._owner)
        _createdDate = try container.decodeIfPresent(WixCreatedDate.self, forKey: ._createdDate)
        _updatedDate = try container.decodeIfPresent(WixCreatedDate.self, forKey: ._updatedDate)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(thumbnailImage, forKey: .thumbnailImage)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(playbackUrl, forKey: .playbackUrl)
        try container.encodeIfPresent(video, forKey: .video)
        try container.encodeIfPresent(linkFeaturedTitle, forKey: .linkFeaturedTitle)
        try container.encodeIfPresent(_owner, forKey: ._owner)
        try container.encodeIfPresent(_createdDate, forKey: ._createdDate)
        try container.encodeIfPresent(_updatedDate, forKey: ._updatedDate)
    }
    
    public init(
        id: String,
        title: String,
        description: String? = nil,
        category: String? = nil,
        thumbnailImage: String? = nil,
        thumbnailUrl: String? = nil,
        playbackUrl: String? = nil,
        video: String? = nil,
        linkFeaturedTitle: String? = nil,
        _owner: String? = nil,
        _createdDate: WixCreatedDate? = nil,
        _updatedDate: WixCreatedDate? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.thumbnailImage = thumbnailImage
        self.thumbnailUrl = thumbnailUrl
        self.playbackUrl = playbackUrl
        self.video = video
        self.linkFeaturedTitle = linkFeaturedTitle
        self._owner = _owner
        self._createdDate = _createdDate
        self._updatedDate = _updatedDate
    }
    
    // Preview initializer
    public static func preview(
        id: String = "preview-id",
        title: String = "Sample Title",
        description: String? = "Sample Description",
        category: String? = "Sample Category",
        thumbnailImage: String? = "sample-thumbnail",
        thumbnailUrl: String? = nil,
        playbackUrl: String? = "sample-url",
        video: String? = nil
    ) -> FeaturedItem {
        FeaturedItem(
            id: id,
            title: title,
            description: description,
            category: category,
            thumbnailImage: thumbnailImage,
            thumbnailUrl: thumbnailUrl,
            playbackUrl: playbackUrl,
            video: video,
            linkFeaturedTitle: "/featured/sample",
            _owner: "sample-owner",
            _createdDate: WixCreatedDate(date: "2025-01-04T07:38:26.704Z"),
            _updatedDate: WixCreatedDate(date: "2025-01-04T07:38:26.704Z")
        )
    }
} 