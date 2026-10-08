import Foundation

nonisolated enum EditingDocumentError: Error, Equatable {
    case invalidDimensions
    case invalidBorderFraction
    case invalidColorComponent
    case duplicatePhotoID
    case unknownSelectedPhoto
}

nonisolated struct EditingDocument: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 4

    let schemaVersion: Int
    let id: DocumentID

    var photos: [Photo]
    var selectedPhotoIDs: Set<PhotoID>
    var aspectRatio: CanvasAspectRatio
    var border: Border

    init(
        schemaVersion: Int = Self.currentSchemaVersion,
        id: DocumentID = DocumentID(),
        photos: [Photo],
        selectedPhotoIDs: Set<PhotoID> = [],
        aspectRatio: CanvasAspectRatio,
        border: Border
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
        self.photos = photos
        self.selectedPhotoIDs = selectedPhotoIDs
        self.aspectRatio = aspectRatio
        self.border = border
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, id, photos, selectedPhotoIDs, aspectRatio, border
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            schemaVersion: values.decode(Int.self, forKey: .schemaVersion),
            id: values.decode(DocumentID.self, forKey: .id),
            photos: values.decode([Photo].self, forKey: .photos),
            selectedPhotoIDs: values.decode(Set<PhotoID>.self, forKey: .selectedPhotoIDs),
            aspectRatio: values.decode(CanvasAspectRatio.self, forKey: .aspectRatio),
            border: values.decode(Border.self, forKey: .border)
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

nonisolated struct Photo: Codable, Equatable, Identifiable, Sendable {
    let id: PhotoID
    let sourceDimensions: PixelDimensions

    var showsMetadata: Bool

    init(
        id: PhotoID = PhotoID(),
        sourceDimensions: PixelDimensions,
        showsMetadata: Bool = true
    ) throws {
        self.id = id
        self.sourceDimensions = sourceDimensions
        self.showsMetadata = showsMetadata
    }

    private enum CodingKeys: String, CodingKey {
        case id, sourceDimensions, showsMetadata
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: values.decode(PhotoID.self, forKey: .id),
            sourceDimensions: values.decode(PixelDimensions.self, forKey: .sourceDimensions),
            showsMetadata: values.decode(Bool.self, forKey: .showsMetadata)
        )
    }
}

nonisolated enum CanvasAspectRatio: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case square
    case portraitFourFive
    case landscapeFiveFour
    case portraitNineSixteen
    case landscapeSixteenNine

    var id: Self { self }

    var widthUnits: Int {
        switch self {
        case .square: 1
        case .portraitFourFive: 4
        case .landscapeFiveFour: 5
        case .portraitNineSixteen: 9
        case .landscapeSixteenNine: 16
        }
    }

    var heightUnits: Int {
        switch self {
        case .square: 1
        case .portraitFourFive: 5
        case .landscapeFiveFour: 4
        case .portraitNineSixteen: 16
        case .landscapeSixteenNine: 9
        }
    }

    var label: String { "\(widthUnits):\(heightUnits)" }
    var value: Double { Double(widthUnits) / Double(heightUnits) }
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
    let color: RGBAColor

    init(fraction: Double, color: RGBAColor) throws {
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
            color: values.decode(RGBAColor.self, forKey: .color)
        )
    }
}

nonisolated struct RGBAColor: Codable, Equatable, Hashable, Sendable {
    static let white = try! RGBAColor(red: 1, green: 1, blue: 1)

    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) throws {
        let components = [red, green, blue, alpha]
        guard components.allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
            throw EditingDocumentError.invalidColorComponent
        }
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            red: values.decode(Double.self, forKey: .red),
            green: values.decode(Double.self, forKey: .green),
            blue: values.decode(Double.self, forKey: .blue),
            alpha: values.decode(Double.self, forKey: .alpha)
        )
    }
}
