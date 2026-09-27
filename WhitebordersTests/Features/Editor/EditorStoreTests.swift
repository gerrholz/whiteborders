import Photos
import XCTest
@testable import Whiteborders

@MainActor
final class EditorStoreTests: XCTestCase {
    func testStartsWithCurrentAuthorizationStatus() {
        let store = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .limited,
                requested: .limited
            )
        )

        XCTAssertEqual(store.authorizationStatus, .limited)
        XCTAssertTrue(store.canReadPhotos)
        XCTAssertFalse(store.accessWasDenied)
    }

    func testRequestUpdatesAuthorizationStatus() async {
        let store = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .notDetermined,
                requested: .authorized
            )
        )

        await store.requestPhotoAccess()

        XCTAssertEqual(store.authorizationStatus, .authorized)
        XCTAssertTrue(store.canReadPhotos)
        XCTAssertFalse(store.isRequestingAuthorization)
    }

    func testDeniedAndRestrictedStatusesCannotReadPhotos() {
        let denied = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .denied,
                requested: .denied
            )
        )
        let restricted = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .restricted,
                requested: .restricted
            )
        )

        XCTAssertTrue(denied.accessWasDenied)
        XCTAssertFalse(denied.canReadPhotos)
        XCTAssertTrue(restricted.accessWasDenied)
        XCTAssertFalse(restricted.canReadPhotos)
    }

    func testImportConnectsResourceAndDocumentWithSamePhotoID() async throws {
        let resource = PhotoResource(
            id: PhotoID(rawValue: "imported-photo"),
            fileURL: URL(filePath: "/tmp/imported-photo.jpg"),
            dimensions: try PixelDimensions(width: 4_032, height: 3_024)
        )
        let store = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .authorized,
                requested: .authorized
            ),
            importer: FakePhotoImporter(result: .success(resource))
        )

        await store.importPhotos([PhotoImportInput(data: Data([1]))])

        XCTAssertEqual(store.document.photos.map(\.id), [resource.id])
        XCTAssertEqual(store.resources[resource.id], resource)
        XCTAssertEqual(store.selectedPhotoID, resource.id)
        XCTAssertEqual(store.document.selectedPhotoIDs, [resource.id])
    }

    func testImportFailureIsExposedWithoutAddingPhoto() async {
        let store = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .authorized,
                requested: .authorized
            ),
            importer: FakePhotoImporter(result: .failure(PhotoImportError.invalidImage))
        )

        await store.importPhotos([PhotoImportInput(data: Data([1]))])

        XCTAssertTrue(store.document.photos.isEmpty)
        XCTAssertNotNil(store.importErrorMessage)
        XCTAssertFalse(store.isImportingPhotos)
    }
}

private nonisolated struct FakePhotoLibraryAuthorization: PhotoLibraryAuthorizing {
    let current: PHAuthorizationStatus
    let requested: PHAuthorizationStatus

    func currentStatus() -> PHAuthorizationStatus { current }
    func requestAccess() async -> PHAuthorizationStatus { requested }
}

private nonisolated struct FakePhotoImporter: PhotoImporting {
    let result: Result<PhotoResource, Error>

    func importPhoto(_ input: PhotoImportInput) async throws -> PhotoResource {
        try result.get()
    }
}
