import Foundation
import ImageIO

nonisolated enum PhotoImportError: Error, Equatable {
    case invalidImage
}

nonisolated protocol PhotoImporting: Sendable {
    func importPhoto(_ input: PhotoImportInput) async throws -> PhotoResource
}

actor PhotoImporter: PhotoImporting {
    private let sessionDirectory: URL

    init(baseDirectory: URL = FileManager.default.temporaryDirectory) {
        sessionDirectory = baseDirectory
            .appending(path: "Whiteborders", directoryHint: .isDirectory)
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    }

    func importPhoto(_ input: PhotoImportInput) async throws -> PhotoResource {
        let dimensions = try ImageDimensionsReader.dimensions(of: input.data)
        let id = PhotoID()
        let fileExtension = normalizedExtension(input.preferredFileExtension)
        let fileURL = sessionDirectory
            .appending(path: id.rawValue)
            .appendingPathExtension(fileExtension)

        try FileManager.default.createDirectory(
            at: sessionDirectory,
            withIntermediateDirectories: true
        )
        try input.data.write(to: fileURL, options: .atomic)

        return PhotoResource(id: id, fileURL: fileURL, dimensions: dimensions)
    }

    func removeAllResources() throws {
        guard FileManager.default.fileExists(atPath: sessionDirectory.path) else { return }
        try FileManager.default.removeItem(at: sessionDirectory)
    }

    private func normalizedExtension(_ value: String?) -> String {
        guard let value else { return "img" }
        let normalized = value.lowercased()
        let allowed = CharacterSet.alphanumerics
        guard !normalized.isEmpty,
              normalized.unicodeScalars.allSatisfy(allowed.contains)
        else {
            return "img"
        }
        return normalized
    }
}

nonisolated enum ImageDimensionsReader {
    static func dimensions(of data: Data) throws -> PixelDimensions {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            throw PhotoImportError.invalidImage
        }

        let orientation = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1
        let swapsDimensions = (5...8).contains(orientation)
        return try PixelDimensions(
            width: swapsDimensions ? height : width,
            height: swapsDimensions ? width : height
        )
    }
}
