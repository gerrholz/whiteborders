import CoreGraphics

nonisolated struct PhotoLayout: Equatable, Sendable {
    let canvasSize: CGSize
    let photoFrame: CGRect

    static func centered(
        source: PixelDimensions,
        borderFraction: Double,
        aspectRatio: CanvasAspectRatio = .square
    ) -> PhotoLayout {
        let sourceWidth = CGFloat(source.width)
        let sourceHeight = CGFloat(source.height)
        let usableFraction = 1 - (2 * borderFraction)
        let widthUnits = CGFloat(aspectRatio.widthUnits)
        let heightUnits = CGFloat(aspectRatio.heightUnits)
        let unitScale = ceil(max(
            sourceWidth / (usableFraction * widthUnits),
            sourceHeight / (usableFraction * heightUnits)
        ))
        let canvasSize = CGSize(
            width: unitScale * widthUnits,
            height: unitScale * heightUnits
        )
        let photoFrame = CGRect(
            x: (canvasSize.width - sourceWidth) / 2,
            y: (canvasSize.height - sourceHeight) / 2,
            width: sourceWidth,
            height: sourceHeight
        )

        return PhotoLayout(canvasSize: canvasSize, photoFrame: photoFrame)
    }
}
