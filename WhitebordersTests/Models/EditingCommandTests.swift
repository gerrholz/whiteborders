import XCTest
@testable import Whiteborders

final class EditingCommandTests: XCTestCase {
    func testBorderFractionChangesTheDocument() throws {
        let document = try makeDocument(photoCount: 2)
        let changed = try EditingReducer.reduce(
            document,
            command: .setBorderFraction(0.12)
        )

        XCTAssertEqual(changed.border.fraction, 0.12)
        XCTAssertEqual(changed.border.color, .white)
        XCTAssertEqual(changed.photos, document.photos)
    }

    func testAllScopeChangesEveryPhoto() throws {
        let document = try makeDocument(photoCount: 2)
        let changed = try EditingReducer.reduce(
            document,
            command: .setMetadataVisible(false, scope: .allPhotos)
        )

        XCTAssertTrue(changed.photos.allSatisfy { !$0.showsMetadata })
    }

    func testAspectRatioChangesTheDocument() throws {
        let document = try makeDocument(photoCount: 2)
        let changed = try EditingReducer.reduce(
            document,
            command: .setAspectRatio(.portraitFourFive)
        )

        XCTAssertEqual(changed.aspectRatio, .portraitFourFive)
        XCTAssertEqual(changed.photos, document.photos)
    }

    func testUnknownPhotoFailsWithoutChangingDocument() throws {
        let document = try makeDocument()
        let missingID = PhotoID(rawValue: "missing")

        XCTAssertThrowsError(
            try EditingReducer.reduce(
                document,
                command: .setMetadataVisible(false, scope: .photo(missingID))
            )
        ) { error in
            XCTAssertEqual(error as? EditingCommandError, .photoNotFound(missingID))
        }
    }

    func testCommandIsSerializable() throws {
        let command = EditingCommand.setBorderColor(
            try RGBAColor(red: 0.67, green: 0.8, blue: 0.94)
        )
        let encoded = try JSONEncoder().encode(command)
        let decoded = try JSONDecoder().decode(EditingCommand.self, from: encoded)

        XCTAssertEqual(decoded, command)
    }
}
