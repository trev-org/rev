#if os(macOS)
import AppKit
import Foundation

enum MenuBarIcon {
    static let assetName = "MenuBarIcon"
    static let swiftPMResourceName = "MenuBarIconTemplate"
    static let pointHeight: CGFloat = 18

    /// Retained for the app lifetime and passed directly to the status-item label.
    static let image: NSImage = {
        if let image = load() {
            return image
        }
        NSLog("rev: failed to load the menu bar icon")
        let fallback = NSImage(
            systemSymbolName: "bolt.fill",
            accessibilityDescription: "rev"
        ) ?? NSImage(size: NSSize(width: pointHeight, height: pointHeight))
        return prepare(fallback)
    }()

    static func load(bundle: Bundle = .main) -> NSImage? {
        if let image = bundle.image(forResource: NSImage.Name(assetName)) {
            return prepare(image)
        }
        guard let url = bundle.url(
            forResource: swiftPMResourceName,
            withExtension: "svg"
        ) else {
            return nil
        }
        return load(contentsOf: url)
    }

    static func load(contentsOf url: URL) -> NSImage? {
        NSImage(contentsOf: url).map { prepare($0) }
    }

    private static func prepare(_ image: NSImage) -> NSImage {
        let aspectRatio = image.size.height > 0
            ? image.size.width / image.size.height
            : 1
        image.size = NSSize(
            width: pointHeight * aspectRatio,
            height: pointHeight
        )
        image.isTemplate = true
        return image
    }
}
#endif
