import CoreGraphics
import Foundation
import XCTest
@testable import Whiteborders

final class PhotoRendererTests: XCTestCase {
    func testRenderProducesDerivedSquareCanvasAndPreservesSource() async throws {
        let sourceURL = try fixtureURL(name: "generated-landscape", extension: "png")
        let originalData = try Data(contentsOf: sourceURL)
        let photo = try Photo(
            id: PhotoID(rawValue: "landscape"),
            sourceDimensions: PixelDimensions(width: 4, height: 3),
            border: Border(fraction: 0.1, color: .white)
        )
        let resource = PhotoResource(
            id: photo.id,
            fileURL: sourceURL,
            dimensions: photo.sourceDimensions
        )

        let output = try await PhotoRenderer().render(photo: photo, resource: resource)

        XCTAssertEqual(output.width, 5)
        XCTAssertEqual(output.height, 5)
        XCTAssertEqual(try Data(contentsOf: sourceURL), originalData)
    }

    func testBorderPixelUsesConfiguredColor() async throws {
        let sourceURL = try fixtureURL(name: "generated-landscape", extension: "png")
        let red = try RGBAColor(red: 1, green: 0, blue: 0)
        let photo = try Photo(
            sourceDimensions: PixelDimensions(width: 4, height: 3),
            border: Border(fraction: 0.1, color: red)
        )
        let resource = PhotoResource(
            id: photo.id,
            fileURL: sourceURL,
            dimensions: photo.sourceDimensions
        )

        let output = try await PhotoRenderer().render(photo: photo, resource: resource)
        let pixel = try rgbaPixel(in: output, x: 0, y: 0)

        XCTAssertGreaterThanOrEqual(pixel.red, 250)
        XCTAssertLessThanOrEqual(pixel.green, 5)
        XCTAssertLessThanOrEqual(pixel.blue, 5)
        XCTAssertGreaterThanOrEqual(pixel.alpha, 250)
    }

    func testMissingSourceThrowsReadableError() async throws {
        let photo = try Photo(sourceDimensions: PixelDimensions(width: 4, height: 3))
        let resource = PhotoResource(
            id: photo.id,
            fileURL: URL(filePath: "/tmp/whiteborders-missing-image.png"),
            dimensions: photo.sourceDimensions
        )

        do {
            _ = try await PhotoRenderer().render(photo: photo, resource: resource)
            XCTFail("Expected rendering to fail")
        } catch {
            XCTAssertEqual(error as? PhotoRenderError, .unreadableImage)
        }
    }

    private func fixtureURL(name: String, extension fileExtension: String) throws -> URL {
        try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: name, withExtension: fileExtension)
        )
    }

    private func rgbaPixel(in image: CGImage, x: Int, y: Int) throws -> Pixel {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        return try bytes.withUnsafeMutableBytes { storage in
            let context = try XCTUnwrap(
                CGContext(
                    data: storage.baseAddress,
                    width: image.width,
                    height: image.height,
                    bitsPerComponent: 8,
                    bytesPerRow: image.width * 4,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            )
            context.draw(
                image,
                in: CGRect(x: 0, y: 0, width: image.width, height: image.height)
            )
            let offset = ((y * image.width) + x) * 4
            return Pixel(
                red: storage[offset],
                green: storage[offset + 1],
                blue: storage[offset + 2],
                alpha: storage[offset + 3]
            )
        }
    }
}

private struct Pixel {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}
