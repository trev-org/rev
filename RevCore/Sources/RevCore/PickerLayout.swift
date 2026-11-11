import Foundation

/// The edge of the inline picker that is attached to the text caret.
public enum PickerAttachmentEdge: Equatable, Sendable {
    case top
    case bottom

    /// Orders result indices so index zero is always at the edge nearest the caret.
    public func orderedResultIndices(count: Int) -> [Int] {
        guard count > 0 else { return [] }
        let indices = Array(0..<count)
        return self == .top ? indices : Array(indices.reversed())
    }

    /// Converts an on-screen movement (-1 up, +1 down) into a result-index movement.
    public func resultIndexDelta(forVisualDelta delta: Int) -> Int {
        self == .top ? delta : -delta
    }
}

/// Screen placement for the inline picker.
public struct PickerPanelLayout {
    public let frame: CGRect
    public let attachmentEdge: PickerAttachmentEdge

    public init(frame: CGRect, attachmentEdge: PickerAttachmentEdge) {
        self.frame = frame
        self.attachmentEdge = attachmentEdge
    }

    /// Places the picker below the caret when it fits, otherwise above it, then clamps it on-screen.
    public static func resolve(
        caret: CGRect,
        visibleFrame: CGRect,
        panelSize: CGSize,
        horizontalOffset: CGFloat = 8,
        gap: CGFloat = 4
    ) -> PickerPanelLayout {
        let belowY = caret.minY - gap - panelSize.height
        let attachmentEdge: PickerAttachmentEdge = belowY >= visibleFrame.minY ? .top : .bottom
        let proposedY = attachmentEdge == .top ? belowY : caret.maxY + gap

        let maxX = max(visibleFrame.minX, visibleFrame.maxX - panelSize.width)
        let maxY = max(visibleFrame.minY, visibleFrame.maxY - panelSize.height)
        let x = min(max(caret.minX - horizontalOffset, visibleFrame.minX), maxX)
        let y = min(max(proposedY, visibleFrame.minY), maxY)

        return PickerPanelLayout(
            frame: CGRect(origin: CGPoint(x: x, y: y), size: panelSize),
            attachmentEdge: attachmentEdge
        )
    }
}
