#if os(macOS)
import AppKit
import RevCore
import SwiftUI

/// Borderless, non-activating panel: the target app keeps keyboard focus.
final class PickerPanel: NSPanel {
    static let width: CGFloat = 300
    static let rowHeight: CGFloat = 28
    static let verticalPadding: CGFloat = 12
    static let maxVisibleRows = 8
    private var layout: PickerPanelLayout?

    init(model: PickerModel) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 100),
                   styleMask: [.nonactivatingPanel, .borderless],
                   backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .popUpMenu
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        worksWhenModal = true
        isMovable = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        contentView = FirstMouseHostingView(rootView: PickerView(model: model))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not supported") }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Shows the panel below the caret (or above it if there is no room), clamped to the screen.
    func show(rowCount: Int, caret: NSRect) {
        let height = Self.height(for: rowCount)
        let maximumHeight = Self.height(for: Self.maxVisibleRows)
        let screen = NSScreen.screens.first { $0.frame.insetBy(dx: -1, dy: -1).contains(caret.origin) }
            ?? NSScreen.main ?? NSScreen.screens.first
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 10_000, height: 10_000)
        // Choose a side using the maximum viewport so later result growth remains on-screen.
        let maximumLayout = PickerPanelLayout.resolve(
            caret: caret,
            visibleFrame: visible,
            panelSize: NSSize(width: Self.width, height: maximumHeight)
        )
        let layout = maximumLayout.resized(toHeight: height)

        self.layout = layout
        setFrame(layout.frame, display: true)
        orderFrontRegardless()
    }

    func resize(rowCount: Int) {
        guard isVisible, let layout else { return }
        let resized = layout.resized(toHeight: Self.height(for: rowCount))
        self.layout = resized
        setFrame(resized.frame, display: true)
    }

    private static func height(for rowCount: Int) -> CGFloat {
        CGFloat(min(max(rowCount, 1), maxVisibleRows)) * rowHeight + verticalPadding
    }
}

/// Lets row clicks register without activating rev first.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
#endif
