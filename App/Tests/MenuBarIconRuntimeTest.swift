#if os(macOS)
import AppKit
import Foundation

@main
struct MenuBarIconRuntimeTest {
    static func main() {
        let appPath = ProcessInfo.processInfo.environment["APP_PATH"]!
        guard let bundle = Bundle(path: appPath) else {
            fatalError("Rev.app is not a readable bundle")
        }
        guard let image = MenuBarIcon.load(bundle: bundle) else {
            fatalError("Rev.app did not load MenuBarIconTemplate.svg")
        }
        precondition(image.isTemplate, "Menu bar icon is not a template")
        precondition(image.size.height == 18, "Unexpected icon height")
        precondition(image.size.width > 0, "Unexpected icon width")
    }
}
#endif
