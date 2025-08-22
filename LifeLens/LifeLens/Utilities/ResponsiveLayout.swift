//
//  ResponsiveLayout.swift
//  LifeLens
//
//  Responsive layout utilities for adaptive UI
//

import SwiftUI

// MARK: - Device Type Detection
enum DeviceType {
    case iPhone
    case iPad
    case mac
    
    static var current: DeviceType {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .iPad
        } else {
            return .iPhone
        }
        #elseif os(macOS)
        return .mac
        #else
        return .iPhone
        #endif
    }
}

// MARK: - Screen Size Categories
enum ScreenSizeCategory {
    case compact   // iPhone SE, iPhone 8
    case regular   // iPhone 14, iPhone 15
    case large     // iPhone Pro Max
    case xlarge    // iPad, Mac
    
    static var current: ScreenSizeCategory {
        let width = UIScreen.main.bounds.width
        
        switch width {
        case 0..<375:
            return .compact
        case 375..<414:
            return .regular
        case 414..<500:
            return .large
        default:
            return .xlarge
        }
    }
}

// MARK: - Responsive Dimensions
struct ResponsiveDimensions {
    static func padding(_ base: CGFloat = 16) -> CGFloat {
        switch ScreenSizeCategory.current {
        case .compact:
            return base * 0.75
        case .regular:
            return base
        case .large:
            return base * 1.2
        case .xlarge:
            return base * 1.5
        }
    }
    
    static func spacing(_ base: CGFloat = 12) -> CGFloat {
        switch ScreenSizeCategory.current {
        case .compact:
            return base * 0.8
        case .regular:
            return base
        case .large:
            return base * 1.1
        case .xlarge:
            return base * 1.3
        }
    }
    
    static func fontSize(_ style: FontStyle) -> CGFloat {
        let baseSize = style.baseSize
        
        switch ScreenSizeCategory.current {
        case .compact:
            return baseSize * 0.9
        case .regular:
            return baseSize
        case .large:
            return baseSize * 1.1
        case .xlarge:
            return baseSize * 1.2
        }
    }
    
    static func cornerRadius(_ base: CGFloat = 12) -> CGFloat {
        switch ScreenSizeCategory.current {
        case .compact:
            return base * 0.8
        case .regular:
            return base
        case .large:
            return base * 1.1
        case .xlarge:
            return base * 1.3
        }
    }
    
    static func iconSize(_ base: CGFloat = 24) -> CGFloat {
        switch ScreenSizeCategory.current {
        case .compact:
            return base * 0.85
        case .regular:
            return base
        case .large:
            return base * 1.15
        case .xlarge:
            return base * 1.3
        }
    }
}

// MARK: - Font Styles
enum FontStyle {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption2
    
    var baseSize: CGFloat {
        switch self {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .body: return 17
        case .callout: return 16
        case .subheadline: return 15
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        }
    }
}

// MARK: - Adaptive Grid Layout
struct AdaptiveGrid {
    static func columns(minWidth: CGFloat = 150, maxColumns: Int? = nil) -> [GridItem] {
        let screenWidth = UIScreen.main.bounds.width
        let padding = ResponsiveDimensions.padding() * 2
        let availableWidth = screenWidth - padding
        
        var columnCount = Int(availableWidth / minWidth)
        
        if let max = maxColumns {
            columnCount = min(columnCount, max)
        }
        
        switch ScreenSizeCategory.current {
        case .compact:
            columnCount = min(columnCount, 2)
        case .regular:
            columnCount = min(columnCount, 2)
        case .large:
            columnCount = min(columnCount, 3)
        case .xlarge:
            break // Use calculated count
        }
        
        return Array(repeating: GridItem(.flexible(), spacing: ResponsiveDimensions.spacing()), count: max(1, columnCount))
    }
}

// MARK: - Progressive Loading Manager
// ProgressiveLoadingManager is now defined in Services/ProgressiveDataService.swift

// MARK: - Offline Cache Manager
class OfflineCacheManager {
    static let shared = OfflineCacheManager()
    
    private let cacheDirectory: URL
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    private init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("LifeLensCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func cache<T: Codable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(object) else { return }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        try? data.write(to: fileURL)
    }
    
    func retrieve<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        
        // Check cache age
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modificationDate) > maxCacheAge {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
    
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

// MARK: - Responsive View Modifiers
struct ResponsivePadding: ViewModifier {
    let edges: Edge.Set
    let base: CGFloat
    
    func body(content: Content) -> some View {
        content.padding(edges, ResponsiveDimensions.padding(base))
    }
}

struct ResponsiveFont: ViewModifier {
    let style: FontStyle
    let weight: Font.Weight
    
    func body(content: Content) -> some View {
        content.font(.system(size: ResponsiveDimensions.fontSize(style), weight: weight))
    }
}

struct ResponsiveCornerRadius: ViewModifier {
    let base: CGFloat
    
    func body(content: Content) -> some View {
        content.cornerRadius(ResponsiveDimensions.cornerRadius(base))
    }
}

// MARK: - View Extensions
extension View {
    func responsivePadding(_ edges: Edge.Set = .all, base: CGFloat = 16) -> some View {
        modifier(ResponsivePadding(edges: edges, base: base))
    }
    
    func responsiveFont(_ style: FontStyle, weight: Font.Weight = .regular) -> some View {
        modifier(ResponsiveFont(style: style, weight: weight))
    }
    
    func responsiveCornerRadius(_ base: CGFloat = 12) -> some View {
        modifier(ResponsiveCornerRadius(base: base))
    }
    
    func adaptiveFrame(minWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil) -> some View {
        let factor: CGFloat = {
            switch ScreenSizeCategory.current {
            case .compact: return 0.9
            case .regular: return 1.0
            case .large: return 1.1
            case .xlarge: return 1.2
            }
        }()
        
        return self.frame(
            minWidth: minWidth.map { $0 * factor },
            maxWidth: maxWidth.map { $0 * factor },
            minHeight: minHeight.map { $0 * factor },
            maxHeight: maxHeight.map { $0 * factor }
        )
    }
}

// MARK: - Orientation Observer
class OrientationObserver: ObservableObject {
    @Published var orientation: UIDeviceOrientation = UIDevice.current.orientation
    @Published var isLandscape: Bool = false
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        updateOrientation()
    }
    
    @objc private func orientationChanged() {
        updateOrientation()
    }
    
    private func updateOrientation() {
        orientation = UIDevice.current.orientation
        isLandscape = orientation.isLandscape
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Network Reachability
class NetworkReachability: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi
    
    enum ConnectionType {
        case wifi
        case cellular
        case offline
    }
    
    static let shared = NetworkReachability()
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Simplified network monitoring
        // In production, use NWPathMonitor from Network framework
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.checkConnection()
        }
    }
    
    private func checkConnection() {
        // This is a simplified check
        // In production, implement proper network monitoring
        URLSession.shared.dataTask(with: URL(string: "https://www.apple.com")!) { _, response, _ in
            DispatchQueue.main.async {
                self.isConnected = (response as? HTTPURLResponse)?.statusCode == 200
            }
        }.resume()
    }
}

// MARK: - Lazy Image Loader
struct LazyImage: View {
    let url: URL?
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    placeholder
                        .foregroundColor(.gray.opacity(0.3))
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url, image == nil, !isLoading else { return }
        
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = uiImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}