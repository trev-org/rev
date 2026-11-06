#if os(macOS)
import AppKit
import Foundation

@main
struct SourceApplicationIconProviderRuntimeTest {
    @MainActor
    static func main() {
        let applicationURL = URL(fileURLWithPath: "/Applications/Example.app")
        let applicationIcon = NSImage(size: NSSize(width: 32, height: 32))
        applicationIcon.isTemplate = true
        let fallbackIcon = NSImage(size: NSSize(width: 16, height: 16))
        var resolvedIdentifiers: [String] = []
        var loadedURLs: [URL] = []

        let provider = SourceApplicationIconProvider(
            resolveApplicationURL: {
                resolvedIdentifiers.append($0)
                return $0 == "com.example.app" ? applicationURL : nil
            },
            loadIcon: {
                loadedURLs.append($0)
                return applicationIcon
            },
            fallbackIcon: fallbackIcon
        )

        precondition(
            provider.icon(forBundleIdentifier: "com.example.app") === applicationIcon,
            "Resolved bundle identifier did not return its application icon"
        )
        precondition(
            provider.icon(forBundleIdentifier: "com.example.app") === applicationIcon,
            "Resolved application icon was not cached"
        )
        precondition(
            resolvedIdentifiers == ["com.example.app"],
            "Application URL lookup was not cached"
        )
        precondition(
            loadedURLs == [applicationURL],
            "Icon loader did not receive the resolved application URL"
        )
        precondition(
            !applicationIcon.isTemplate,
            "Application icons must render in full color"
        )

        precondition(
            provider.icon(forBundleIdentifier: "com.example.missing") === fallbackIcon,
            "Missing applications did not use the fallback icon"
        )
        precondition(
            provider.icon(forBundleIdentifier: "com.example.missing") === fallbackIcon,
            "Missing application fallback was not cached"
        )
        precondition(
            resolvedIdentifiers == ["com.example.app", "com.example.missing"],
            "Missing application lookup was not cached"
        )
        precondition(
            provider.icon(forBundleIdentifier: nil) === fallbackIcon,
            "Sources without a bundle identifier did not use the fallback icon"
        )
    }
}
#endif
