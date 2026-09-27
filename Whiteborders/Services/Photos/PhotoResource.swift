import Foundation

nonisolated struct PhotoResource: Identifiable, Equatable, Sendable {
    let id: PhotoID
    let fileURL: URL
    let dimensions: PixelDimensions
}

nonisolated struct PhotoImportInput: Sendable {
    let data: Data
    let preferredFileExtension: String?

    init(data: Data, preferredFileExtension: String? = nil) {
        self.data = data
        self.preferredFileExtension = preferredFileExtension
    }
}
