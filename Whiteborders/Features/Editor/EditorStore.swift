import Observation
import Photos

@MainActor
@Observable
final class EditorStore {
    private let authorization: any PhotoLibraryAuthorizing
    private let importer: any PhotoImporting

    private(set) var authorizationStatus: PHAuthorizationStatus
    private(set) var isRequestingAuthorization = false
    private(set) var isImportingPhotos = false
    private(set) var document: EditingDocument
    private(set) var resources: [PhotoID: PhotoResource] = [:]
    private(set) var selectedPhotoID: PhotoID?
    private(set) var importErrorMessage: String?

    init(
        authorization: any PhotoLibraryAuthorizing = PhotoLibraryAuthorization(),
        importer: any PhotoImporting = PhotoImporter()
    ) {
        self.authorization = authorization
        self.importer = importer
        authorizationStatus = authorization.currentStatus()
        document = try! EditingDocument(photos: [])
    }

    func requestPhotoAccess() async {
        guard authorizationStatus == .notDetermined else { return }

        isRequestingAuthorization = true
        authorizationStatus = await authorization.requestAccess()
        isRequestingAuthorization = false
    }

    var canReadPhotos: Bool {
        authorizationStatus == .authorized || authorizationStatus == .limited
    }

    var accessWasDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var selectedResource: PhotoResource? {
        guard let selectedPhotoID else { return nil }
        return resources[selectedPhotoID]
    }

    var orderedResources: [PhotoResource] {
        document.photos.compactMap { resources[$0.id] }
    }

    func importPhotos(_ inputs: [PhotoImportInput]) async {
        guard !inputs.isEmpty else { return }

        isImportingPhotos = true
        importErrorMessage = nil
        defer { isImportingPhotos = false }

        for input in inputs {
            do {
                let resource = try await importer.importPhoto(input)
                let photo = try Photo(
                    id: resource.id,
                    sourceDimensions: resource.dimensions
                )
                resources[resource.id] = resource
                document.photos.append(photo)
                document.selectedPhotoIDs = [resource.id]
                selectedPhotoID = resource.id
            } catch {
                importErrorMessage = "One or more selected photos could not be imported."
            }
        }
    }

    func selectPhoto(_ id: PhotoID) {
        guard resources[id] != nil else { return }
        selectedPhotoID = id
        document.selectedPhotoIDs = [id]
    }

    func clearImportError() {
        importErrorMessage = nil
    }

    func reportImportFailure() {
        importErrorMessage = "One or more selected photos could not be imported."
    }
}
