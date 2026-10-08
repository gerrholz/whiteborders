import CoreGraphics
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
            importer: FakePhotoImporter(result: .success(resource)),
            renderer: FakePhotoRenderer(image: makeTestImage())
        )

        await store.importPhotos([PhotoImportInput(data: Data([1]))])

        XCTAssertEqual(store.document.photos.map(\.id), [resource.id])
        XCTAssertEqual(store.resources[resource.id], resource)
        XCTAssertEqual(store.selectedPhotoID, resource.id)
        XCTAssertEqual(store.document.selectedPhotoIDs, [resource.id])
        XCTAssertNotNil(store.renderedPreview)
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

    func testBorderChangesUseHistoryAndCanBeUndone() async throws {
        let resource = PhotoResource(
            id: PhotoID(rawValue: "editable-photo"),
            fileURL: URL(filePath: "/tmp/editable-photo.jpg"),
            dimensions: try PixelDimensions(width: 100, height: 80)
        )
        let store = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .authorized,
                requested: .authorized
            ),
            importer: FakePhotoImporter(result: .success(resource)),
            renderer: FakePhotoRenderer(image: makeTestImage())
        )
        await store.importPhotos([PhotoImportInput(data: Data([1]))])

        await store.setBorderFraction(0.12, isContinuous: false)
        XCTAssertEqual(store.document.border.fraction, 0.12)
        XCTAssertTrue(store.canUndo)

        await store.undo()
        XCTAssertEqual(store.document.border.fraction, 0.07)
        XCTAssertTrue(store.canRedo)
    }

    func testAspectRatioChangesUseHistoryAndCanBeUndone() async throws {
        let resource = PhotoResource(
            id: PhotoID(rawValue: "ratio-photo"),
            fileURL: URL(filePath: "/tmp/ratio-photo.jpg"),
            dimensions: try PixelDimensions(width: 100, height: 80)
        )
        let store = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .authorized,
                requested: .authorized
            ),
            importer: FakePhotoImporter(result: .success(resource)),
            renderer: FakePhotoRenderer(image: makeTestImage())
        )
        await store.importPhotos([PhotoImportInput(data: Data([1]))])

        await store.setAspectRatio(.portraitFourFive)
        XCTAssertEqual(store.document.aspectRatio, .portraitFourFive)

        await store.undo()
        XCTAssertEqual(store.document.aspectRatio, .square)
    }

    func testExportRendersEncodesAndSavesSelectedPhoto() async throws {
        let resource = PhotoResource(
            id: PhotoID(rawValue: "export-photo"),
            fileURL: URL(filePath: "/tmp/export-photo.jpg"),
            dimensions: try PixelDimensions(width: 100, height: 80)
        )
        let store = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .authorized,
                requested: .authorized
            ),
            importer: FakePhotoImporter(result: .success(resource)),
            renderer: FakePhotoRenderer(image: makeTestImage()),
            exporter: FakePhotoExporter(),
            librarySaver: FakePhotoLibrarySaver(shouldFail: false)
        )
        await store.importPhotos([PhotoImportInput(data: Data([1]))])

        await store.exportSelectedPhoto()

        XCTAssertEqual(store.exportNotice, .saved(count: 1))
        XCTAssertFalse(store.isExporting)
    }

    func testExportFailureIsExposed() async throws {
        let resource = PhotoResource(
            id: PhotoID(rawValue: "failed-export"),
            fileURL: URL(filePath: "/tmp/failed-export.jpg"),
            dimensions: try PixelDimensions(width: 100, height: 80)
        )
        let store = EditorStore(
            authorization: FakePhotoLibraryAuthorization(
                current: .authorized,
                requested: .authorized
            ),
            importer: FakePhotoImporter(result: .success(resource)),
            renderer: FakePhotoRenderer(image: makeTestImage()),
            exporter: FakePhotoExporter(),
            librarySaver: FakePhotoLibrarySaver(shouldFail: true)
        )
        await store.importPhotos([PhotoImportInput(data: Data([1]))])

        await store.exportSelectedPhoto()

        guard case .some(.failed) = store.exportNotice else {
            return XCTFail("Expected an export failure notice")
        }
        XCTAssertFalse(store.isExporting)
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

private actor FakePhotoRenderer: PhotoRendering {
    let image: CGImage

    init(image: CGImage) {
        self.image = image
    }

    func render(
        photo: Photo,
        resource: PhotoResource,
        aspectRatio: CanvasAspectRatio,
        border: Border
    ) async throws -> CGImage {
        image
    }
}

private nonisolated struct FakePhotoExporter: PhotoExporting {
    func jpegData(from image: CGImage, quality: Double) throws -> Data {
        Data([0xFF, 0xD8, 0xFF, 0xD9])
    }
}

private actor FakePhotoLibrarySaver: PhotoLibrarySaving {
    let shouldFail: Bool

    init(shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func saveJPEG(_ data: Data) async throws {
        if shouldFail { throw FakeExportError.saveFailed }
    }
}

private nonisolated enum FakeExportError: Error {
    case saveFailed
}

private nonisolated func makeTestImage() -> CGImage {
    let context = CGContext(
        data: nil,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    return context.makeImage()!
}
