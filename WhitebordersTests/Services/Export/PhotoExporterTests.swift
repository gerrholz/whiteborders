import CoreGraphics
import Foundation
import ImageIO
import XCTest
@testable import Whiteborders

final class PhotoExporterTests: XCTestCase {
    func testJPEGPreservesRenderedDimensions() throws {
        let image = try makeImage(width: 12, height: 8)
        let data = try PhotoExporter().jpegData(from: image, quality: 0.95)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let exported = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))

        XCTAssertEqual(exported.width, 12)
        XCTAssertEqual(exported.height, 8)
    }

    func testJPEGDoesNotContainSourceMetadataDictionaries() throws {
        let data = try PhotoExporter().jpegData(
            from: makeImage(width: 4, height: 3),
            quality: 0.95
        )
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try XCTUnwrap(
            CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        )

        XCTAssertNil(properties[kCGImagePropertyExifDictionary])
        XCTAssertNil(properties[kCGImagePropertyGPSDictionary])
        XCTAssertNil(properties[kCGImagePropertyTIFFDictionary])
    }

    func testRejectsInvalidJPEGQuality() throws {
        let image = try makeImage(width: 1, height: 1)

        XCTAssertThrowsError(try PhotoExporter().jpegData(from: image, quality: 1.1)) {
            error in
            XCTAssertEqual(error as? PhotoExportError, .invalidJPEGQuality)
        }
    }

    private func makeImage(width: Int, height: Int) throws -> CGImage {
        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return try XCTUnwrap(context.makeImage())
    }
}
