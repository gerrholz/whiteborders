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
}

private nonisolated struct FakePhotoLibraryAuthorization: PhotoLibraryAuthorizing {
    let current: PHAuthorizationStatus
    let requested: PHAuthorizationStatus

    func currentStatus() -> PHAuthorizationStatus { current }
    func requestAccess() async -> PHAuthorizationStatus { requested }
}
