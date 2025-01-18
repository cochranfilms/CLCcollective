import Foundation

private struct WixResponse: Codable {
    let dataItems: [FeaturedItemWrapper]
    let pagingMetadata: PagingMetadata
}

@MainActor
class FeaturedService: ObservableObject {
    @Published var featuredItems: [FeaturedItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let logger = AppLogger.shared
    
    func fetchFeaturedItems() async {
        isLoading = true
        error = nil
        
        do {
            var components = URLComponents()
            components.scheme = "https"
            components.host = "www.wixapis.com"
            components.path = "/wix-data/v2/items/query"
            
            guard let url = components.url else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(WixConfig.apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(WixConfig.siteId, forHTTPHeaderField: "wix-site-id")
            
            let query: [String: Any] = [
                "dataCollectionId": "CochranFilms2025",
                "includes": [
                    "title", "description", "category", "thumbnailImage",
                    "thumbnailUrl", "_createdDate", "video", "playbackUrl", "_id",
                    "_owner", "_updatedDate", "link-featured-title"
                ],
                "query": [
                    "sort": [["fieldName": "_createdDate", "order": "DESC"]]
                ]
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: query)
            
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            
            // Log the response headers and status code
            if let httpResponse = httpResponse as? HTTPURLResponse {
                logger.debug("Response status code: \(httpResponse.statusCode)", category: .network)
                logger.debug("Response headers: \(httpResponse.allHeaderFields)", category: .network)
            }
            
            // Log the response data
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.debug("Response data: \(jsonString)", category: .network)
            }
            
            let decoder = JSONDecoder()
            let wixResponse = try decoder.decode(WixResponse.self, from: data)
            self.featuredItems = wixResponse.dataItems.map { $0.data }
            self.isLoading = false
            
        } catch {
            logger.error("Failed to fetch featured items: \(error.localizedDescription)", category: .network)
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    logger.error("Key '\(key.stringValue)' not found: \(context.debugDescription)", category: .network)
                case .valueNotFound(let type, let context):
                    logger.error("Value of type '\(type)' not found: \(context.debugDescription)", category: .network)
                case .typeMismatch(let type, let context):
                    logger.error("Type '\(type)' mismatch: \(context.debugDescription)", category: .network)
                case .dataCorrupted(let context):
                    logger.error("Data corrupted: \(context.debugDescription)", category: .network)
                @unknown default:
                    logger.error("Unknown decoding error: \(decodingError)", category: .network)
                }
            }
            self.error = error
            self.isLoading = false
        }
    }
} 