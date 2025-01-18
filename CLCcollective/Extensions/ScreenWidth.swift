import SwiftUI

private struct ScreenWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat = UIScreen.main.bounds.width
}

extension EnvironmentValues {
    var screenWidth: CGFloat {
        get { self[ScreenWidthKey.self] }
        set { self[ScreenWidthKey.self] = newValue }
    }
} 