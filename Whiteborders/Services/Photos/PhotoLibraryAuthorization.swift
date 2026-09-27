import Photos

nonisolated protocol PhotoLibraryAuthorizing: Sendable {
    func currentStatus() -> PHAuthorizationStatus
    func requestAccess() async -> PHAuthorizationStatus
}

nonisolated struct PhotoLibraryAuthorization: PhotoLibraryAuthorizing {
    func currentStatus() -> PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccess() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
}
