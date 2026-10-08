import Foundation

nonisolated enum PhotoScope: Codable, Equatable, Sendable {
    case photo(PhotoID)
    case selectedPhotos
    case allPhotos
}

nonisolated enum EditingCommand: Codable, Equatable, Sendable {
    case setBorderFraction(Double)
    case setBorderColor(RGBAColor)
    case setAspectRatio(CanvasAspectRatio)
    case setMetadataVisible(Bool, scope: PhotoScope)
}

nonisolated enum EditingCommandError: Error, Equatable {
    case photoNotFound(PhotoID)
    case noSelectedPhotos
}

nonisolated enum EditingReducer {
    static func reduce(
        _ document: EditingDocument,
        command: EditingCommand
    ) throws -> EditingDocument {
        var result = document
        switch command {
        case let .setBorderFraction(fraction):
            result.border = try Border(fraction: fraction, color: result.border.color)
            return result
        case let .setBorderColor(color):
            result.border = try Border(fraction: result.border.fraction, color: color)
            return result
        case let .setAspectRatio(aspectRatio):
            result.aspectRatio = aspectRatio
            return result
        case .setMetadataVisible:
            break
        }

        guard case let .setMetadataVisible(isVisible, scope) = command else {
            return result
        }
        let targetIDs = try photoIDs(in: result, scope: scope)

        for index in result.photos.indices where targetIDs.contains(result.photos[index].id) {
            result.photos[index].showsMetadata = isVisible
        }

        return result
    }

    private static func photoIDs(
        in document: EditingDocument,
        scope: PhotoScope
    ) throws -> Set<PhotoID> {
        switch scope {
        case let .photo(id):
            guard document.photos.contains(where: { $0.id == id }) else {
                throw EditingCommandError.photoNotFound(id)
            }
            return [id]
        case .selectedPhotos:
            guard !document.selectedPhotoIDs.isEmpty else {
                throw EditingCommandError.noSelectedPhotos
            }
            return document.selectedPhotoIDs
        case .allPhotos:
            return Set(document.photos.map(\.id))
        }
    }
}
