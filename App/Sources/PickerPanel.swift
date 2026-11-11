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
    static let height = CGFloat(maxVisibleRows) * rowHeight + verticalPadding
    static let size = NSSize(width: width, height: height)

    private let model: PickerModel

    init(model: PickerModel) {
        self.model = model
        super.init(contentRect: NSRect(origin: .zero, size: Self.size),
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
    func show(caret: NSRect) {
        let screen = NSScreen.screens.first { $0.frame.insetBy(dx: -1, dy: -1).contains(caret.origin) }
            ?? NSScreen.main ?? NSScreen.screens.first
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 10_000, height: 10_000)
        let layout = PickerPanelLayout.resolve(
            caret: caret,
            visibleFrame: visible,
            panelSize: Self.size
        )

        model.set(attachmentEdge: layout.attachmentEdge)
        setFrame(layout.frame, display: true)
        orderFrontRegardless()
    }

    /// Whether a screen point is over the rows rather than the deliberately empty viewport area.
    func containsResults(at point: NSPoint) -> Bool {
        guard frame.contains(point) else { return false }
        let visibleRowCount = min(model.results.count, Self.maxVisibleRows)
        let resultHeight = CGFloat(visibleRowCount) * Self.rowHeight + Self.verticalPadding
        let resultFrame: NSRect
        switch model.attachmentEdge {
        case .top:
            resultFrame = NSRect(
                x: frame.minX,
                y: frame.maxY - resultHeight,
                width: frame.width,
                height: resultHeight
            )
        case .bottom:
            resultFrame = NSRect(
                x: frame.minX,
                y: frame.minY,
                width: frame.width,
                height: resultHeight
            )
        }
        return resultFrame.contains(point)
    }
}

/// Lets row clicks register without activating rev first.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}
#endif
