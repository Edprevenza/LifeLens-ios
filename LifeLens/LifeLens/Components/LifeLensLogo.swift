import SwiftUI

// Reusable LifeLens Logo Component
struct LifeLensLogo: View {
    enum LogoSize {
        case small      // 40x40
        case medium     // 60x60
        case large      // 100x100
        case extraLarge // 120x120
        
        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 100
            case .extraLarge: return 120
            }
        }
    }
    
    enum LogoStyle {
        case standalone    // Just the logo
        case withTitle     // Logo with "LifeLens" text
        case withSubtitle  // Logo with title and subtitle
    }
    
    let size: LogoSize
    let style: LogoStyle
    var subtitle: String?
    
    init(size: LogoSize = .medium, style: LogoStyle = .standalone, subtitle: String? = nil) {
        self.size = size
        self.style = style
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: size == .small ? 4 : 8) {
            // Logo Image - Using system icon as fallback
            Group {
                if #available(macOS 12.0, *) {
                    // Try to load the actual logo, fallback to system icon
                    Image("lifelens_logo")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: size.dimension, height: size.dimension)
                        .overlay(
                            // Fallback to system icon if image not found
                            Image(systemName: "heart.circle.fill")
                                .resizable()
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: size.dimension, height: size.dimension)
                                .opacity(1.0) // Always show system icon for now
                        )
                } else {
                    Image(systemName: "heart.circle.fill")
                        .resizable()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: size.dimension, height: size.dimension)
                }
            }
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Title and Subtitle based on style
            if style != .standalone {
                VStack(spacing: 4) {
                    if style == .withTitle || style == .withSubtitle {
                        Text("LifeLens")
                            .font(titleFont)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    if style == .withSubtitle, let subtitle = subtitle {
                        Text(subtitle)
                            .font(subtitleFont)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    private var titleFont: Font {
        switch size {
        case .small: return .caption
        case .medium: return .headline
        case .large: return .title2
        case .extraLarge: return .largeTitle
        }
    }
    
    private var subtitleFont: Font {
        switch size {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .body
        case .extraLarge: return .headline
        }
    }
}

// Header Logo Component for Navigation Bars
struct HeaderLogo: View {
    var body: some View {
        HStack(spacing: 8) {
            LifeLensLogo(size: .small, style: .standalone)
            Text("LifeLens")
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

// Preview
struct LifeLensLogo_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            LifeLensLogo(size: .small, style: .standalone)
            LifeLensLogo(size: .medium, style: .withTitle)
            LifeLensLogo(size: .large, style: .withSubtitle, subtitle: "Your Health Companion")
            HeaderLogo()
        }
        .padding()
    }
}