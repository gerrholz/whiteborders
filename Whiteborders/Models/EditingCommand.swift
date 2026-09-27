import Foundation

nonisolated enum PhotoScope: Codable, Equatable, Sendable {
    case photo(PhotoID)
    case selectedPhotos
    case allPhotos
}

nonisolated enum EditingCommand: Codable, Equatable, Sendable {
    case setBorderFraction(Double, scope: PhotoScope)
    case setBorderColor(HexColor, scope: PhotoScope)
    case setPhotoCornerRadius(Double, scope: PhotoScope)
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
        let targetIDs = try photoIDs(in: result, scope: command.scope)

        for index in result.photos.indices where targetIDs.contains(result.photos[index].id) {
            let photo = result.photos[index]
            switch command {
            case let .setBorderFraction(fraction, _):
                result.photos[index].border = try Border(
                    fraction: fraction,
                    color: photo.border.color
                )
            case let .setBorderColor(color, _):
                result.photos[index].border = try Border(
                    fraction: photo.border.fraction,
                    color: color
                )
            case let .setPhotoCornerRadius(radius, _):
                result.photos[index] = try Photo(
                    id: photo.id,
                    sourceDimensions: photo.sourceDimensions,
                    border: photo.border,
                    photoCornerRadius: radius,
                    showsMetadata: photo.showsMetadata
                )
            case let .setMetadataVisible(isVisible, _):
                result.photos[index].showsMetadata = isVisible
            }
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

private extension EditingCommand {
    nonisolated var scope: PhotoScope {
        switch self {
        case let .setBorderFraction(_, scope),
             let .setBorderColor(_, scope),
             let .setPhotoCornerRadius(_, scope),
             let .setMetadataVisible(_, scope):
            return scope
        }
    }
}
