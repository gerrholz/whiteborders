import Foundation
import Photos
import UniformTypeIdentifiers

nonisolated protocol PhotoLibrarySaving: Sendable {
    func saveJPEG(_ data: Data) async throws
}

nonisolated struct PhotoLibrarySaver: PhotoLibrarySaving {
    func saveJPEG(_ data: Data) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = "Whiteborders-\(UUID().uuidString).jpg"
            options.uniformTypeIdentifier = UTType.jpeg.identifier

            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, data: data, options: options)
        }
    }
}
