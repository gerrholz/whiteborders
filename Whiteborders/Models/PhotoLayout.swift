import CoreGraphics

nonisolated struct PhotoLayout: Equatable, Sendable {
    let canvasSize: CGSize
    let photoFrame: CGRect

    static func centered(
        source: PixelDimensions,
        borderFraction: Double
    ) -> PhotoLayout {
        let sourceWidth = CGFloat(source.width)
        let sourceHeight = CGFloat(source.height)
        let longestEdge = max(sourceWidth, sourceHeight)
        let canvasSide = ceil(longestEdge / (1 - (2 * borderFraction)))
        let canvasSize = CGSize(width: canvasSide, height: canvasSide)
        let photoFrame = CGRect(
            x: (canvasSide - sourceWidth) / 2,
            y: (canvasSide - sourceHeight) / 2,
            width: sourceWidth,
            height: sourceHeight
        )

        return PhotoLayout(canvasSize: canvasSize, photoFrame: photoFrame)
    }
}
