import Foundation
import XCTest
@testable import Whiteborders

final class PhotoImporterTests: XCTestCase {
    func testReadsJPEGDimensionsWithoutRenderingImage() throws {
        let data = try fixtureData(name: "generated-landscape", extension: "jpg")

        XCTAssertEqual(
            try ImageDimensionsReader.dimensions(of: data),
            try PixelDimensions(width: 4, height: 3)
        )
    }

    func testReadsPortraitPNGDimensions() throws {
        let data = try fixtureData(name: "generated-portrait", extension: "png")

        XCTAssertEqual(
            try ImageDimensionsReader.dimensions(of: data),
            try PixelDimensions(width: 3, height: 4)
        )
    }

    func testRejectsMalformedImageData() {
        XCTAssertThrowsError(try ImageDimensionsReader.dimensions(of: Data([0, 1, 2, 3]))) {
            error in
            XCTAssertEqual(error as? PhotoImportError, .invalidImage)
        }
    }

    func testImporterCopiesImageToOwnedSessionDirectory() async throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let importer = PhotoImporter(baseDirectory: baseDirectory)
        let data = try fixtureData(name: "generated-landscape", extension: "png")

        let resource = try await importer.importPhoto(
            PhotoImportInput(data: data, preferredFileExtension: "png")
        )

        XCTAssertEqual(resource.dimensions, try PixelDimensions(width: 4, height: 3))
        XCTAssertEqual(resource.fileURL.pathExtension, "png")
        XCTAssertEqual(try Data(contentsOf: resource.fileURL), data)
        XCTAssertTrue(resource.fileURL.path.hasPrefix(baseDirectory.path))

        try await importer.removeAllResources()
        try? FileManager.default.removeItem(at: baseDirectory)
    }

    private func fixtureData(name: String, extension fileExtension: String) throws -> Data {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: name, withExtension: fileExtension)
        )
        return try Data(contentsOf: url)
    }
}
