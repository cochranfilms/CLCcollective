import SwiftUI

/// App-wide styling constants and modifiers
enum AppStyle {
    /// Brand Colors
    enum Colors {
        static let brandYellow = Color(hex: "#dca54e")
        static let brandDarkGreen = Color(hex: "#001A1A")
        static let brandTeal = Color(hex: "#00B2B2")
        
        // Background colors
        static let cardBackground = brandDarkGreen.opacity(0.95)
        static let overlayBackground = Color.black.opacity(0.3)
        
        // Text colors
        static let primaryText = Color.white
        static let secondaryText = Color.white
        static let accentText = brandYellow
    }
    
    /// Text Styles
    enum Typography {
        // Large titles (40pt)
        static let largeTitle: SwiftUI.Font = .system(size: 40, weight: .bold)
        
        // Section titles (32pt)
        static let title1: SwiftUI.Font = .system(size: 32, weight: .bold)
        
        // Card titles (28pt)
        static let title2: SwiftUI.Font = .system(size: 28, weight: .bold)
        
        // Subtitles (24pt)
        static let title3: SwiftUI.Font = .system(size: 24, weight: .bold)
        
        // Heading (20pt)
        static let heading: SwiftUI.Font = .system(size: 20, weight: .bold)
        
        // Body text (16pt)
        static let body: SwiftUI.Font = .system(size: 16)
        
        // Button text
        static let button: SwiftUI.Font = .headline
    }
    
    /// Layout Constants
    enum Layout {
        // Standard spacing
        static let spacing: CGFloat = 16
        static let padding: CGFloat = 16
        
        // Card dimensions
        static let cardCornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 12
        static let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
        static let maxContentWidth: CGFloat = 500
        
        // Content heights
        static let standardHeight: CGFloat = 180
        static let headerHeight: CGFloat = 160
        static let buttonHeight: CGFloat = 50
        
        // Image dimensions
        static let iconHeight: CGFloat = 40
        static let logoHeight: CGFloat = 50
    }
    
    /// Gradient Styles
    enum Gradients {
        static let primaryGradient = LinearGradient(
            colors: [Colors.brandYellow, Colors.brandTeal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let darkOverlay = LinearGradient(
            colors: [Colors.brandDarkGreen.opacity(0.85), Colors.brandDarkGreen.opacity(0.95)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    /// Border Styles
    enum Borders {
        static let cardBorder = RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
            .strokeBorder(Colors.brandTeal.opacity(0.3), lineWidth: 1)
        
        static let buttonBorder = RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
            .strokeBorder(Colors.brandYellow.opacity(0.5), lineWidth: 1)
    }
}

// MARK: - View Modifiers

/// Card Style Modifier
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppStyle.Layout.padding)
            .frame(maxWidth: AppStyle.Layout.maxContentWidth)
            .background(AppStyle.Colors.cardBackground)
            .cornerRadius(AppStyle.Layout.cardCornerRadius)
            .overlay(AppStyle.Borders.cardBorder)
    }
}

/// Button Style
struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppStyle.Typography.button)
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: AppStyle.Layout.buttonHeight)
            .background(AppStyle.Colors.brandYellow)
            .cornerRadius(AppStyle.Layout.buttonCornerRadius)
    }
}

/// Text 3D Style
struct ThreeDTextStyle: ViewModifier {
    let startColor: Color
    let endColor: Color
    
    init(startColor: Color = AppStyle.Colors.brandYellow, 
         endColor: Color = AppStyle.Colors.brandTeal) {
        self.startColor = startColor
        self.endColor = endColor
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(
                LinearGradient(
                    colors: [startColor, endColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 2, y: 2)
            .shadow(color: startColor.opacity(0.3), radius: 1, x: -1, y: -1)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func primaryButtonStyle() -> some View {
        modifier(PrimaryButtonStyle())
    }
    
    func threeDStyle(
        startColor: Color = AppStyle.Colors.brandYellow,
        endColor: Color = AppStyle.Colors.brandTeal
    ) -> some View {
        modifier(ThreeDTextStyle(startColor: startColor, endColor: endColor))
    }
} 