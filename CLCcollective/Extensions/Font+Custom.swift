import SwiftUI

extension Font {
    static func superstar(size: CGFloat) -> Font {
        return .custom("Superstar M54", size: size)
    }
    
    static let superstarHeading = superstar(size: 36)
    static let superstarSubheading = superstar(size: 24)
    static let superstarTitle = superstar(size: 18)
} 