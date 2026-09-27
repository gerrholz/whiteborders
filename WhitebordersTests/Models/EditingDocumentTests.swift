import XCTest
@testable import Whiteborders

final class EditingDocumentTests: XCTestCase {
    func testDefaultsDescribeSquareWhiteBorderComposition() throws {
        let document = try makeDocument()

        XCTAssertEqual(document.schemaVersion, 1)
        XCTAssertEqual(document.canvas, try Canvas(width: 1_080, height: 1_080))
        XCTAssertEqual(document.photos[0].border, try Border(fraction: 0.07, color: .white))
        XCTAssertEqual(document.photos[0].photoCornerRadius, 0.07)
    }

    func testRejectsInvalidValues() throws {
        XCTAssertThrowsError(try PixelDimensions(width: 0, height: 100))
        XCTAssertThrowsError(try Border(fraction: .infinity, color: .white))
        XCTAssertThrowsError(try Border(fraction: 0.5, color: .white))
        XCTAssertNil(HexColor(rawValue: "white"))
    }

    func testRejectsSelectionThatIsNotInDocument() throws {
        let photo = try makePhoto(id: "photo-1")

        XCTAssertThrowsError(
            try EditingDocument(
                photos: [photo],
                selectedPhotoIDs: [PhotoID(rawValue: "missing")]
            )
        ) { error in
            XCTAssertEqual(error as? EditingDocumentError, .unknownSelectedPhoto)
        }
    }

    func testJSONRoundTripPreservesDocument() throws {
        let original = try makeDocument()
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EditingDocument.self, from: encoded)

        XCTAssertEqual(decoded, original)
    }
}

func makePhoto(id: String = "photo-1") throws -> Photo {
    try Photo(
        id: PhotoID(rawValue: id),
        sourceDimensions: PixelDimensions(width: 4_032, height: 3_024)
    )
}

func makeDocument(photoCount: Int = 1) throws -> EditingDocument {
    let photos = try (1...photoCount).map { try makePhoto(id: "photo-\($0)") }
    return try EditingDocument(
        id: DocumentID(rawValue: "document-1"),
        photos: photos,
        selectedPhotoIDs: [photos[0].id]
    )
}
