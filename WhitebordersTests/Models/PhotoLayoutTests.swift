import CoreGraphics
import XCTest
@testable import Whiteborders

final class PhotoLayoutTests: XCTestCase {
    private let accuracy = 0.001

    func testLandscapePhotoFillsAvailableWidthAndIsCentered() throws {
        let result = try layout(width: 4_032, height: 3_024)
        let frame = result.photoFrame

        XCTAssertEqual(result.canvasSize, CGSize(width: 4_689, height: 4_689))
        XCTAssertEqual(frame.minX, 328.5, accuracy: accuracy)
        XCTAssertEqual(frame.minY, 832.5, accuracy: accuracy)
        XCTAssertEqual(frame.width, 4_032, accuracy: accuracy)
        XCTAssertEqual(frame.height, 3_024, accuracy: accuracy)
    }

    func testPortraitPhotoFillsAvailableHeightAndIsCentered() throws {
        let frame = try layout(width: 3_024, height: 4_032).photoFrame

        XCTAssertEqual(frame.minX, 832.5, accuracy: accuracy)
        XCTAssertEqual(frame.minY, 328.5, accuracy: accuracy)
        XCTAssertEqual(frame.width, 3_024, accuracy: accuracy)
        XCTAssertEqual(frame.height, 4_032, accuracy: accuracy)
    }

    func testSquarePhotoFillsInnerRectangle() throws {
        let frame = try layout(width: 2_000, height: 2_000).photoFrame

        XCTAssertEqual(frame.minX, 163, accuracy: accuracy)
        XCTAssertEqual(frame.minY, 163, accuracy: accuracy)
        XCTAssertEqual(frame.width, 2_000, accuracy: accuracy)
        XCTAssertEqual(frame.height, 2_000, accuracy: accuracy)
    }

    func testResultPreservesSourceAspectRatio() throws {
        let frame = try layout(width: 6_000, height: 4_000).photoFrame

        XCTAssertEqual(frame.width / frame.height, 1.5, accuracy: accuracy)
    }

    func testZeroBorderAllowsPhotoToReachCanvasEdge() throws {
        let source = try PixelDimensions(width: 1_000, height: 1_000)
        let frame = PhotoLayout.centered(
            source: source,
            borderFraction: 0
        ).photoFrame

        XCTAssertEqual(frame, CGRect(x: 0, y: 0, width: 1_000, height: 1_000))
    }

    func testFrameStaysInsideBorderBounds() throws {
        let result = try layout(width: 8_000, height: 1_000)
        let frame = result.photoFrame
        let inset = result.canvasSize.width * 0.07

        XCTAssertGreaterThanOrEqual(frame.minX, inset - accuracy)
        XCTAssertGreaterThanOrEqual(frame.minY, inset - accuracy)
        XCTAssertLessThanOrEqual(frame.maxX, result.canvasSize.width - inset + accuracy)
        XCTAssertLessThanOrEqual(frame.maxY, result.canvasSize.height - inset + accuracy)
    }

    func testPortraitFourFiveCanvasUsesRequestedAspectRatio() throws {
        let result = PhotoLayout.centered(
            source: try PixelDimensions(width: 4_032, height: 3_024),
            borderFraction: 0.07,
            aspectRatio: .portraitFourFive
        )

        XCTAssertEqual(result.canvasSize.width / result.canvasSize.height, 4.0 / 5.0, accuracy: accuracy)
        XCTAssertEqual(result.photoFrame.size, CGSize(width: 4_032, height: 3_024))
    }

    func testLandscapeSixteenNineCanvasUsesRequestedAspectRatio() throws {
        let result = PhotoLayout.centered(
            source: try PixelDimensions(width: 3_024, height: 4_032),
            borderFraction: 0.07,
            aspectRatio: .landscapeSixteenNine
        )

        XCTAssertEqual(result.canvasSize.width / result.canvasSize.height, 16.0 / 9.0, accuracy: accuracy)
        XCTAssertEqual(result.photoFrame.size, CGSize(width: 3_024, height: 4_032))
    }

    private func layout(width: Int, height: Int) throws -> PhotoLayout {
        PhotoLayout.centered(
            source: try PixelDimensions(width: width, height: height),
            borderFraction: 0.07
        )
    }
}
