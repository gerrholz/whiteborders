import CoreGraphics
import XCTest
@testable import Whiteborders

final class PhotoLayoutTests: XCTestCase {
    private let accuracy = 0.001

    func testLandscapePhotoFillsAvailableWidthAndIsCentered() throws {
        let frame = try layout(width: 4_032, height: 3_024).photoFrame

        XCTAssertEqual(frame.minX, 75.6, accuracy: accuracy)
        XCTAssertEqual(frame.minY, 191.7, accuracy: accuracy)
        XCTAssertEqual(frame.width, 928.8, accuracy: accuracy)
        XCTAssertEqual(frame.height, 696.6, accuracy: accuracy)
    }

    func testPortraitPhotoFillsAvailableHeightAndIsCentered() throws {
        let frame = try layout(width: 3_024, height: 4_032).photoFrame

        XCTAssertEqual(frame.minX, 191.7, accuracy: accuracy)
        XCTAssertEqual(frame.minY, 75.6, accuracy: accuracy)
        XCTAssertEqual(frame.width, 696.6, accuracy: accuracy)
        XCTAssertEqual(frame.height, 928.8, accuracy: accuracy)
    }

    func testSquarePhotoFillsInnerRectangle() throws {
        let frame = try layout(width: 2_000, height: 2_000).photoFrame

        XCTAssertEqual(frame.minX, 75.6, accuracy: accuracy)
        XCTAssertEqual(frame.minY, 75.6, accuracy: accuracy)
        XCTAssertEqual(frame.width, 928.8, accuracy: accuracy)
        XCTAssertEqual(frame.height, 928.8, accuracy: accuracy)
    }

    func testResultPreservesSourceAspectRatio() throws {
        let frame = try layout(width: 6_000, height: 4_000).photoFrame

        XCTAssertEqual(frame.width / frame.height, 1.5, accuracy: accuracy)
    }

    func testZeroBorderAllowsPhotoToReachCanvasEdge() throws {
        let source = try PixelDimensions(width: 1_000, height: 1_000)
        let frame = PhotoLayout.centered(
            source: source,
            canvas: .default,
            borderFraction: 0
        ).photoFrame

        XCTAssertEqual(frame, CGRect(x: 0, y: 0, width: 1_080, height: 1_080))
    }

    func testFrameStaysInsideBorderBounds() throws {
        let frame = try layout(width: 8_000, height: 1_000).photoFrame
        let inset = 1_080.0 * 0.07

        XCTAssertGreaterThanOrEqual(frame.minX, inset - accuracy)
        XCTAssertGreaterThanOrEqual(frame.minY, inset - accuracy)
        XCTAssertLessThanOrEqual(frame.maxX, 1_080 - inset + accuracy)
        XCTAssertLessThanOrEqual(frame.maxY, 1_080 - inset + accuracy)
    }

    private func layout(width: Int, height: Int) throws -> PhotoLayout {
        PhotoLayout.centered(
            source: try PixelDimensions(width: width, height: height),
            canvas: .default,
            borderFraction: 0.07
        )
    }
}
