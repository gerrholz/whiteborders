import XCTest
@testable import Whiteborders

final class EditingHistoryTests: XCTestCase {
    func testUndoAndRedoRestoreSnapshots() throws {
        var history = EditingHistory(document: try makeDocument())

        try history.apply(.setBorderFraction(0.12, scope: .allPhotos))
        XCTAssertEqual(history.document.photos[0].border.fraction, 0.12)
        XCTAssertTrue(history.undo())
        XCTAssertEqual(history.document.photos[0].border.fraction, 0.07)
        XCTAssertTrue(history.redo())
        XCTAssertEqual(history.document.photos[0].border.fraction, 0.12)
    }

    func testNewCommandClearsRedoHistory() throws {
        var history = EditingHistory(document: try makeDocument())

        try history.apply(.setBorderFraction(0.12, scope: .allPhotos))
        history.undo()
        try history.apply(.setMetadataVisible(false, scope: .allPhotos))

        XCTAssertFalse(history.canRedo)
    }

    func testCoalescedSliderUpdatesUndoAsOneGesture() throws {
        var history = EditingHistory(document: try makeDocument())

        try history.apply(
            .setBorderFraction(0.08, scope: .allPhotos),
            coalescingKey: "border-slider"
        )
        try history.apply(
            .setBorderFraction(0.14, scope: .allPhotos),
            coalescingKey: "border-slider"
        )
        history.endCoalescing()

        XCTAssertEqual(history.document.photos[0].border.fraction, 0.14)
        XCTAssertTrue(history.undo())
        XCTAssertEqual(history.document.photos[0].border.fraction, 0.07)
        XCTAssertFalse(history.undo())
    }

    func testCapacityDropsOldestSnapshots() throws {
        var history = EditingHistory(document: try makeDocument(), capacity: 2)

        try history.apply(.setBorderFraction(0.08, scope: .allPhotos))
        try history.apply(.setBorderFraction(0.09, scope: .allPhotos))
        try history.apply(.setBorderFraction(0.10, scope: .allPhotos))

        XCTAssertTrue(history.undo())
        XCTAssertTrue(history.undo())
        XCTAssertFalse(history.undo())
        XCTAssertEqual(history.document.photos[0].border.fraction, 0.08)
    }
}
