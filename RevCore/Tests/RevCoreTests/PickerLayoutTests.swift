import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
import Testing
@testable import RevCore

@Suite struct PickerLayoutTests {
    private let visibleFrame = CGRect(x: 0, y: 0, width: 1_000, height: 800)
    private let panelSize = CGSize(width: 300, height: 236)

    @Test func pickerBelowCaretAttachesItsTopEdge() {
        let caret = CGRect(x: 400, y: 500, width: 0, height: 20)

        let layout = PickerPanelLayout.resolve(
            caret: caret,
            visibleFrame: visibleFrame,
            panelSize: panelSize
        )

        XCTAssertEqual(layout.attachmentEdge, .top)
        XCTAssertEqual(layout.frame.maxY, caret.minY - 4)
    }

    @Test func pickerAboveCaretAttachesItsBottomEdge() {
        let caret = CGRect(x: 400, y: 20, width: 0, height: 20)

        let layout = PickerPanelLayout.resolve(
            caret: caret,
            visibleFrame: visibleFrame,
            panelSize: panelSize
        )

        XCTAssertEqual(layout.attachmentEdge, .bottom)
        XCTAssertEqual(layout.frame.minY, caret.maxY + 4)
    }

    @Test func bestResultAndNavigationHugAttachedEdge() {
        XCTAssertEqual(PickerAttachmentEdge.top.orderedResultIndices(count: 4), [0, 1, 2, 3])
        XCTAssertEqual(PickerAttachmentEdge.bottom.orderedResultIndices(count: 4), [3, 2, 1, 0])

        XCTAssertEqual(PickerAttachmentEdge.top.resultIndexDelta(forVisualDelta: -1), -1)
        XCTAssertEqual(PickerAttachmentEdge.bottom.resultIndexDelta(forVisualDelta: -1), 1)
    }
}
