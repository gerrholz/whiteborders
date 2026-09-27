import Observation
import Photos

@MainActor
@Observable
final class EditorStore {
    private let authorization: any PhotoLibraryAuthorizing

    private(set) var authorizationStatus: PHAuthorizationStatus
    private(set) var isRequestingAuthorization = false

    init(
        authorization: any PhotoLibraryAuthorizing = PhotoLibraryAuthorization()
    ) {
        self.authorization = authorization
        authorizationStatus = authorization.currentStatus()
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
}
