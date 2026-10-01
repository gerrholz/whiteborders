import CoreGraphics
import CoreImage
import Foundation

nonisolated enum PhotoRenderError: Error, Equatable {
    case unreadableImage
    case couldNotCreateBitmap
    case couldNotCreateOutput
}

nonisolated protocol PhotoRendering: Sendable {
    func render(photo: Photo, resource: PhotoResource) async throws -> CGImage
}

actor PhotoRenderer: PhotoRendering {
    private lazy var imageContext = CIContext(options: [
        .cacheIntermediates: false,
        .useSoftwareRenderer: true
    ])

    func render(photo: Photo, resource: PhotoResource) async throws -> CGImage {
        guard let orientedImage = CIImage(
            contentsOf: resource.fileURL,
            options: [.applyOrientationProperty: true]
        ), let sourceImage = imageContext.createCGImage(
            orientedImage,
            from: orientedImage.extent
        ) else {
            throw PhotoRenderError.unreadableImage
        }

        let layout = PhotoLayout.centered(
            source: photo.sourceDimensions,
            borderFraction: photo.border.fraction
        )
        let width = Int(layout.canvasSize.width)
        let height = Int(layout.canvasSize.height)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw PhotoRenderError.couldNotCreateBitmap
        }

        let borderColor = photo.border.color
        context.setFillColor(
            CGColor(
                red: CGFloat(borderColor.red),
                green: CGFloat(borderColor.green),
                blue: CGFloat(borderColor.blue),
                alpha: CGFloat(borderColor.alpha)
            )
        )
        context.fill(CGRect(origin: .zero, size: layout.canvasSize))

        context.interpolationQuality = .high
        context.draw(sourceImage, in: layout.photoFrame)

        guard let output = context.makeImage() else {
            throw PhotoRenderError.couldNotCreateOutput
        }
        return output
    }
}
