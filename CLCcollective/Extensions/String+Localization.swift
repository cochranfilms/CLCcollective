import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// Namespace for localization keys
enum LocalizationKey {
    enum General {
        static let appName = "app.name"
    }
    
    enum Portfolio {
        static let title = "portfolio.title"
        static let loading = "portfolio.loading"
        static let errorTitle = "portfolio.error.title"
        static let tryAgain = "portfolio.error.tryAgain"
        static let empty = "portfolio.empty"
        static let categoryAll = "portfolio.category.all"
    }
    
    enum Video {
        static let errorTitle = "video.error.title"
        static let errorPermissions = "video.error.permissions"
        static let close = "video.close"
        static let play = "video.play"
        static let loading = "video.loading"
    }
    
    enum Category {
        static let prefix = "category.prefix"
        static let select = "category.select"
        static let selected = "category.selected"
    }
    
    enum Accessibility {
        static let videoClose = "accessibility.video.close"
        static let videoPlay = "accessibility.video.play"
        static let categorySelect = "accessibility.category.select"
        static let categorySelected = "accessibility.category.selected"
        static let errorTryAgain = "accessibility.error.tryAgain"
        static let tagsPrefix = "accessibility.tags.prefix"
    }
    
    enum Error {
        static let network = "error.network"
        static let unknown = "error.unknown"
        static let tryAgain = "error.tryAgain"
    }
} 