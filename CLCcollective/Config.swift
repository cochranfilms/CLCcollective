import Foundation

enum Environment {
    case development
    case production
    
    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

enum Config {
    private static let baseURL: String = {
        switch Environment.current {
        case .development:
            // Feature branch preview URL
            return "https://clc-collective-feature-backend-setup.vercel.app/api"
        case .production:
            return "https://clc-collective.vercel.app/api"
        }
    }()
    
    enum API {
        static let chat = "\(baseURL)/chat"
        static let wave = "\(baseURL)/wave"
        static let wix = "\(baseURL)/wix"
        static let postmarkCF = "\(baseURL)/postmark/cf"
        static let postmarkCCA = "\(baseURL)/postmark/cca"
        static let google = "\(baseURL)/google"
    }
    
    enum Cloudinary {
        static let cloudName = "clccollective"
        static let apiKey = "587664693879771"
        static let apiSecret = "srct4h7_u1o-sgR3mIJ8_f7y9Ic"
        static let uploadPreset = "profile_images"
    }
    
    enum Services {
        static let openAIEndpoint = API.chat
        static let waveInvoiceEndpoint = "\(API.wave)/invoice"
        static let postmarkCFEndpoint = "\(API.postmarkCF)/send"
        static let postmarkCCAEndpoint = "\(API.postmarkCCA)/send"
        static let wixPortfolioEndpoint = "\(API.wix)/portfolio"
        static let googleAnalyticsEndpoint = "\(API.google)/analytics"
    }
} 