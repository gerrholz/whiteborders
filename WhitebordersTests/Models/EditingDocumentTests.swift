import XCTest
@testable import Whiteborders

final class EditingDocumentTests: XCTestCase {
    func testDefaultsDescribeWhiteBorderComposition() throws {
        let document = try makeDocument()

        XCTAssertEqual(document.schemaVersion, 3)
        XCTAssertEqual(document.photos[0].border, try Border(fraction: 0.07, color: .white))
    }

    func testEncodedDocumentDoesNotStoreDerivedCanvasDimensions() throws {
        let data = try JSONEncoder().encode(makeDocument())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNil(json["canvas"])
    }

    func testRejectsInvalidValues() throws {
        XCTAssertThrowsError(try PixelDimensions(width: 0, height: 100))
        XCTAssertThrowsError(try Border(fraction: .infinity, color: .white))
        XCTAssertThrowsError(try Border(fraction: 0.5, color: .white))
        XCTAssertThrowsError(try RGBAColor(red: 1.1, green: 0, blue: 0))
        XCTAssertThrowsError(try RGBAColor(red: 0, green: .nan, blue: 0))
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
