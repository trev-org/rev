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

    @Test func resizingBelowCaretPreservesTopEdge() {
        let original = PickerPanelLayout(
            frame: CGRect(x: 100, y: 200, width: 300, height: 236),
            attachmentEdge: .top
        )

        let shrunk = original.resized(toHeight: 68)
        let expanded = shrunk.resized(toHeight: 236)

        XCTAssertEqual(shrunk.frame.maxY, original.frame.maxY)
        XCTAssertEqual(shrunk.frame.height, 68)
        XCTAssertEqual(expanded.frame.maxY, original.frame.maxY)
        XCTAssertEqual(expanded.frame.height, 236)
    }

    @Test func resizingAboveCaretPreservesBottomEdge() {
        let original = PickerPanelLayout(
            frame: CGRect(x: 100, y: 200, width: 300, height: 236),
            attachmentEdge: .bottom
        )

        let shrunk = original.resized(toHeight: 68)
        let expanded = shrunk.resized(toHeight: 236)

        XCTAssertEqual(shrunk.frame.minY, original.frame.minY)
        XCTAssertEqual(shrunk.frame.height, 68)
        XCTAssertEqual(expanded.frame.minY, original.frame.minY)
        XCTAssertEqual(expanded.frame.height, 236)
    }

    @Test func maximumHeightPlacementSupportsLaterResultGrowth() {
        let caret = CGRect(x: 400, y: 100, width: 0, height: 20)
        let maximum = PickerPanelLayout.resolve(
            caret: caret,
            visibleFrame: visibleFrame,
            panelSize: panelSize
        )

        let initiallyNarrow = maximum.resized(toHeight: 40)
        let expanded = initiallyNarrow.resized(toHeight: panelSize.height)

        XCTAssertEqual(maximum.attachmentEdge, .bottom)
        XCTAssertEqual(initiallyNarrow.frame.minY, caret.maxY + 4)
        XCTAssertEqual(expanded.frame.minY, caret.maxY + 4)
        XCTAssertLessThanOrEqual(expanded.frame.maxY, visibleFrame.maxY)
    }
}
