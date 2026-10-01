import Observation
import Photos
import CoreGraphics

@MainActor
@Observable
final class EditorStore {
    private let authorization: any PhotoLibraryAuthorizing
    private let importer: any PhotoImporting
    private let renderer: any PhotoRendering
    private var history: EditingHistory

    private(set) var authorizationStatus: PHAuthorizationStatus
    private(set) var isRequestingAuthorization = false
    private(set) var isImportingPhotos = false
    private(set) var resources: [PhotoID: PhotoResource] = [:]
    private(set) var selectedPhotoID: PhotoID?
    private(set) var importErrorMessage: String?
    private(set) var renderedPreview: CGImage?

    init(
        authorization: any PhotoLibraryAuthorizing = PhotoLibraryAuthorization(),
        importer: any PhotoImporting = PhotoImporter(),
        renderer: any PhotoRendering = PhotoRenderer()
    ) {
        self.authorization = authorization
        self.importer = importer
        self.renderer = renderer
        authorizationStatus = authorization.currentStatus()
        history = EditingHistory(document: try! EditingDocument(photos: []))
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

    var document: EditingDocument { history.document }

    var selectedPhoto: Photo? {
        guard let selectedPhotoID else { return nil }
        return document.photos.first { $0.id == selectedPhotoID }
    }

    var canUndo: Bool { history.canUndo }
    var canRedo: Bool { history.canRedo }

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
                var updatedDocument = history.document
                updatedDocument.photos.append(photo)
                updatedDocument.selectedPhotoIDs = [resource.id]
                history = EditingHistory(document: updatedDocument)
                resources[resource.id] = resource
                selectedPhotoID = resource.id
            } catch {
                importErrorMessage = "One or more selected photos could not be imported."
            }
        }
        await renderSelectedPhoto()
    }

    func selectPhoto(_ id: PhotoID) async {
        guard resources[id] != nil else { return }
        selectedPhotoID = id
        try? history.updateSelection([id])
        await renderSelectedPhoto()
    }

    func setBorderFraction(_ fraction: Double, isContinuous: Bool) async {
        guard selectedPhotoID != nil else { return }
        do {
            try history.apply(
                .setBorderFraction(fraction, scope: .selectedPhotos),
                coalescingKey: isContinuous ? "border-fraction" : nil
            )
            if !isContinuous { history.endCoalescing() }
            await renderSelectedPhoto()
        } catch {
            importErrorMessage = "The border setting could not be applied."
        }
    }

    func setBorderColor(_ color: RGBAColor) async {
        guard selectedPhotoID != nil else { return }
        do {
            try history.apply(.setBorderColor(color, scope: .selectedPhotos))
            await renderSelectedPhoto()
        } catch {
            importErrorMessage = "The border color could not be applied."
        }
    }

    func setMetadataVisible(_ isVisible: Bool) {
        guard selectedPhotoID != nil else { return }
        try? history.apply(.setMetadataVisible(isVisible, scope: .selectedPhotos))
    }

    func undo() async {
        guard history.undo() else { return }
        await renderSelectedPhoto()
    }

    func redo() async {
        guard history.redo() else { return }
        await renderSelectedPhoto()
    }

    func clearImportError() {
        importErrorMessage = nil
    }

    func reportImportFailure() {
        importErrorMessage = "One or more selected photos could not be imported."
    }

    private func renderSelectedPhoto() async {
        guard let photo = selectedPhoto, let resource = selectedResource else {
            renderedPreview = nil
            return
        }

        do {
            let output = try await renderer.render(photo: photo, resource: resource)
            guard selectedPhoto == photo else { return }
            renderedPreview = output
        } catch {
            renderedPreview = nil
            importErrorMessage = "The selected photo could not be rendered."
        }
    }
}
