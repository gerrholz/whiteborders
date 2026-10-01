import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated enum PhotoExportError: Error, Equatable {
    case invalidJPEGQuality
    case couldNotCreateDestination
    case couldNotFinalizeImage
}

nonisolated protocol PhotoExporting: Sendable {
    func jpegData(from image: CGImage, quality: Double) throws -> Data
}

nonisolated struct PhotoExporter: PhotoExporting {
    func jpegData(from image: CGImage, quality: Double = 0.95) throws -> Data {
        guard quality.isFinite, (0...1).contains(quality) else {
            throw PhotoExportError.invalidJPEGQuality
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw PhotoExportError.couldNotCreateDestination
        }

        let options = [
            kCGImageDestinationLossyCompressionQuality: quality
        ] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)

        guard CGImageDestinationFinalize(destination) else {
            throw PhotoExportError.couldNotFinalizeImage
        }
        return data as Data
    }
}
