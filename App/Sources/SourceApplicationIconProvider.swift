#if os(macOS)
import AppKit

/// Resolves and caches the installed application icon for a clipboard item's source bundle.
@MainActor
final class SourceApplicationIconProvider {
    static let shared = SourceApplicationIconProvider()

    typealias ApplicationURLResolver = @MainActor (String) -> URL?
    typealias IconLoader = @MainActor (URL) -> NSImage

    private let resolveApplicationURL: ApplicationURLResolver
    private let loadIcon: IconLoader
    private let fallbackIcon: NSImage
    private var cachedIcons: [String: NSImage] = [:]

    init(
        resolveApplicationURL: @escaping ApplicationURLResolver = { bundleIdentifier in
            if let runningURL = NSRunningApplication
                .runningApplications(withBundleIdentifier: bundleIdentifier)
                .first(where: { !$0.isTerminated })?
                .bundleURL {
                return runningURL
            }
            return NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: bundleIdentifier
            )
        },
        loadIcon: @escaping IconLoader = {
            NSWorkspace.shared.icon(forFile: $0.path)
        },
        fallbackIcon: NSImage? = nil
    ) {
        self.resolveApplicationURL = resolveApplicationURL
        self.loadIcon = loadIcon
        self.fallbackIcon = fallbackIcon ?? Self.makeFallbackIcon()
    }

    func icon(forBundleIdentifier bundleIdentifier: String?) -> NSImage {
        guard let bundleIdentifier,
              !bundleIdentifier.isEmpty else { return fallbackIcon }
        if let cached = cachedIcons[bundleIdentifier] { return cached }

        guard let applicationURL = resolveApplicationURL(bundleIdentifier) else {
            cachedIcons[bundleIdentifier] = fallbackIcon
            return fallbackIcon
        }

        let icon = loadIcon(applicationURL)
        icon.isTemplate = false
        cachedIcons[bundleIdentifier] = icon
        return icon
    }

    private static func makeFallbackIcon() -> NSImage {
        NSImage(
            systemSymbolName: "questionmark.app.dashed",
            accessibilityDescription: "Unknown application"
        ) ?? NSImage(
            systemSymbolName: "app",
            accessibilityDescription: "Unknown application"
        ) ?? NSImage(size: NSSize(width: 16, height: 16))
    }
}
#endif
