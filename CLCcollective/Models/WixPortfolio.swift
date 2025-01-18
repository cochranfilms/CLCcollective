import Foundation

// MARK: - Portfolio Models
public struct WixPortfolioItem: Codable, Identifiable {
    public let id: String
    public let dataCollectionId: String
    public let data: PortfolioData
}

public struct PortfolioData: Codable {
    public let title: String?
    public let description: String?
    public let category: String?
    public let thumbnail: String?
    public let isFeatured: Bool?
    public let _createdDate: WixCreatedDate
    public let video: String?
    public let thumbnailUrl: String?
    public let playbackUrl: String?
    public let _id: String
    public let _owner: String?
    public let _publishStatus: String?
    public let _updatedDate: WixCreatedDate?
    public let labels: [String]?
    public let ownerName: String?
    public let uploadDate: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case description
        case category
        case thumbnail
        case isFeatured
        case _createdDate
        case video
        case thumbnailUrl
        case playbackUrl
        case _id
        case _owner
        case _publishStatus
        case _updatedDate
        case labels
        case ownerName
        case uploadDate
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured)
        _createdDate = try container.decode(WixCreatedDate.self, forKey: ._createdDate)
        video = try container.decodeIfPresent(String.self, forKey: .video)
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        playbackUrl = try container.decodeIfPresent(String.self, forKey: .playbackUrl)
        _id = try container.decode(String.self, forKey: ._id)
        _owner = try container.decodeIfPresent(String.self, forKey: ._owner)
        _publishStatus = try container.decodeIfPresent(String.self, forKey: ._publishStatus)
        _updatedDate = try container.decodeIfPresent(WixCreatedDate.self, forKey: ._updatedDate)
        labels = try container.decodeIfPresent([String].self, forKey: .labels)
        ownerName = try container.decodeIfPresent(String.self, forKey: .ownerName)
        uploadDate = try container.decodeIfPresent(String.self, forKey: .uploadDate)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(isFeatured, forKey: .isFeatured)
        try container.encode(_createdDate, forKey: ._createdDate)
        try container.encodeIfPresent(video, forKey: .video)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(playbackUrl, forKey: .playbackUrl)
        try container.encode(_id, forKey: ._id)
        try container.encodeIfPresent(_owner, forKey: ._owner)
        try container.encodeIfPresent(_publishStatus, forKey: ._publishStatus)
        try container.encodeIfPresent(_updatedDate, forKey: ._updatedDate)
        try container.encodeIfPresent(labels, forKey: .labels)
        try container.encodeIfPresent(ownerName, forKey: .ownerName)
        try container.encodeIfPresent(uploadDate, forKey: .uploadDate)
    }
}

// MARK: - API Response Models
public struct WixPortfolioResponse: Codable {
    public let dataItems: [WixPortfolioItem]
    public let pagingMetadata: PagingMetadata
}

public struct PagingMetadata: Codable {
    public let count: Int
    public let tooManyToCount: Bool
    public let cursors: [String: String]?
    public let hasNext: Bool
    
    // These fields are optional since they're not always present
    public let offset: Int?
    public let total: Int?
}

// MARK: - Portfolio Service
class WixPortfolioService: ObservableObject {
    @Published private(set) var portfolioItems: [WixPortfolioItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let logger = AppLogger.shared
    
    @MainActor
    func fetchPortfolio() async {
        do {
            setLoading(true)
            clearError()
            
            // Check for task cancellation
            try Task.checkCancellation()
            
            let requestBody: [String: Any] = [
                "dataCollectionId": "CochranFilmsPortfolio",
                "includes": [
                    "title", "description", "category", "thumbnail",
                    "isFeatured", "_createdDate", "video", "thumbnailUrl",
                    "playbackUrl", "_id", "_owner", "_publishStatus",
                    "_updatedDate", "labels", "ownerName", "uploadDate"
                ],
                "query": [
                    "sort": [["fieldName": "_createdDate", "order": "DESC"]],
                    "paging": ["limit": 50, "offset": 0]
                ],
                "returnTotalCount": true
            ]
            
            let requestData = try JSONSerialization.data(withJSONObject: requestBody)
            
            var request = URLRequest(url: URL(string: "https://www.wixapis.com/wix-data/v2/items/query")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(WixConfig.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(WixConfig.siteId, forHTTPHeaderField: "wix-site-id")
            request.httpBody = requestData
            
            logger.info("Fetching portfolio items", category: .portfolio)
            let (data, networkResponse) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = networkResponse as? HTTPURLResponse else {
                throw NSError(domain: "Portfolio", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "Portfolio", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error"])
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                if let date = ISO8601DateFormatter().date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
            }
            
            do {
                let portfolioResponse = try decoder.decode(WixPortfolioResponse.self, from: data)
                self.portfolioItems = portfolioResponse.dataItems
                self.isLoading = false
                self.error = nil
                
                logger.info("Successfully fetched \(portfolioResponse.dataItems.count) portfolio items", category: .portfolio)
                Analytics.shared.track(.portfolioView, properties: AnalyticsProperties(["count": portfolioResponse.dataItems.count]))
            } catch DecodingError.keyNotFound(let key, _) {
                throw NSError(domain: "Portfolio", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Required field missing: \(key.stringValue)"
                ])
            } catch DecodingError.valueNotFound(_, let context) {
                throw NSError(domain: "Portfolio", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Missing value: \(context.debugDescription)"
                ])
            } catch {
                throw NSError(domain: "Portfolio", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to decode portfolio data: \(error.localizedDescription)"
                ])
            }
            
        } catch is CancellationError {
            logger.info("Portfolio fetch cancelled", category: .portfolio)
            self.isLoading = false
            // Don't set error for cancellation
            return
        } catch {
            logger.error("Failed to fetch portfolio: \(error.localizedDescription)", category: .portfolio)
            CrashReporter.shared.reportError(error, severity: .medium, context: "Portfolio fetch")
            Analytics.shared.trackError(error, context: "Portfolio fetch")
            
            self.error = error
            self.isLoading = false
        }
    }
    
    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
    }
    
    @MainActor
    private func clearError() {
        error = nil
    }
} 