import Foundation

nonisolated enum EditingDocumentError: Error, Equatable {
    case invalidDimensions
    case invalidBorderFraction
    case invalidCornerRadius
    case invalidHexColor
    case duplicatePhotoID
    case unknownSelectedPhoto
}

nonisolated struct EditingDocument: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let id: DocumentID

    var canvas: Canvas
    var photos: [Photo]
    var selectedPhotoIDs: Set<PhotoID>

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        id: DocumentID = DocumentID(),
        canvas: Canvas = .default,
        photos: [Photo],
        selectedPhotoIDs: Set<PhotoID> = []
    ) throws {
        let photoIDs = photos.map(\.id)
        guard Set(photoIDs).count == photoIDs.count else {
            throw EditingDocumentError.duplicatePhotoID
        }
        guard selectedPhotoIDs.isSubset(of: Set(photoIDs)) else {
            throw EditingDocumentError.unknownSelectedPhoto
        }

        self.schemaVersion = schemaVersion
        self.id = id
        self.canvas = canvas
        self.photos = photos
        self.selectedPhotoIDs = selectedPhotoIDs
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, canvas, photos, selectedPhotoIDs
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            schemaVersion: values.decode(Int.self, forKey: .schemaVersion),
            id: values.decode(DocumentID.self, forKey: .id),
            canvas: values.decode(Canvas.self, forKey: .canvas),
            photos: values.decode([Photo].self, forKey: .photos),
            selectedPhotoIDs: values.decode(Set<PhotoID>.self, forKey: .selectedPhotoIDs)
        )
    }
}

nonisolated struct DocumentID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) { self.rawValue = rawValue }
    init() { rawValue = UUID().uuidString }
}

nonisolated struct PhotoID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String

    init(rawValue: String) { self.rawValue = rawValue }
    init() { rawValue = UUID().uuidString }
}

nonisolated struct Canvas: Codable, Equatable, Sendable {
    static let `default` = try! Canvas(width: 1_080, height: 1_080)

    let width: Int
    let height: Int

    init(width: Int, height: Int) throws {
        guard width > 0, height > 0 else {
            throw EditingDocumentError.invalidDimensions
        }
        self.width = width
        self.height = height
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            width: values.decode(Int.self, forKey: .width),
            height: values.decode(Int.self, forKey: .height)
        )
    }
}

nonisolated struct Photo: Codable, Equatable, Identifiable, Sendable {
    let id: PhotoID
    let sourceDimensions: PixelDimensions

    var border: Border
    var photoCornerRadius: Double
    var showsMetadata: Bool

    init(
        id: PhotoID = PhotoID(),
        sourceDimensions: PixelDimensions,
        border: Border = .default,
        photoCornerRadius: Double = 0.07,
        showsMetadata: Bool = true
    ) throws {
        guard photoCornerRadius.isFinite, (0...0.5).contains(photoCornerRadius) else {
            throw EditingDocumentError.invalidCornerRadius
        }
        self.id = id
        self.sourceDimensions = sourceDimensions
        self.border = border
        self.photoCornerRadius = photoCornerRadius
        self.showsMetadata = showsMetadata
    }

    private enum CodingKeys: String, CodingKey {
        case id, sourceDimensions, border, photoCornerRadius, showsMetadata
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: values.decode(PhotoID.self, forKey: .id),
            sourceDimensions: values.decode(PixelDimensions.self, forKey: .sourceDimensions),
            border: values.decode(Border.self, forKey: .border),
            photoCornerRadius: values.decode(Double.self, forKey: .photoCornerRadius),
            showsMetadata: values.decode(Bool.self, forKey: .showsMetadata)
        )
    }
}

nonisolated struct PixelDimensions: Codable, Equatable, Sendable {
    let width: Int
    let height: Int

    init(width: Int, height: Int) throws {
        guard width > 0, height > 0 else {
            throw EditingDocumentError.invalidDimensions
        }
        self.width = width
        self.height = height
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            width: values.decode(Int.self, forKey: .width),
            height: values.decode(Int.self, forKey: .height)
        )
    }
}

nonisolated struct Border: Codable, Equatable, Sendable {
    static let `default` = try! Border(fraction: 0.07, color: .white)

    let fraction: Double
    let color: HexColor

    init(fraction: Double, color: HexColor) throws {
        guard fraction.isFinite, (0...0.49).contains(fraction) else {
            throw EditingDocumentError.invalidBorderFraction
        }
        self.fraction = fraction
        self.color = color
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            fraction: values.decode(Double.self, forKey: .fraction),
            color: values.decode(HexColor.self, forKey: .color)
        )
    }
}

nonisolated struct HexColor: RawRepresentable, Codable, Equatable, Sendable {
    static let white = HexColor(rawValue: "#FFFFFF")!

    let rawValue: String

    init?(rawValue: String) {
        let normalized = rawValue.uppercased()
        guard normalized.range(of: "^#[0-9A-F]{6}$", options: .regularExpression) != nil else {
            return nil
        }
        self.rawValue = normalized
    }

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        guard let color = Self(rawValue: value) else {
            throw EditingDocumentError.invalidHexColor
        }
        self = color
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
