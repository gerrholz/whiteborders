import CoreGraphics

nonisolated struct PhotoLayout: Equatable, Sendable {
    let photoFrame: CGRect
    
    static func centered(
        source: PixelDimensions,
        canvas: Canvas,
        borderFraction: Double
    ) -> PhotoLayout {
        let canvasWidth = CGFloat(canvas.width)
        let canvasHeight = CGFloat(canvas.height)
        let sourceWidth = CGFloat(source.width)
        let sourceHeight = CGFloat(source.height)
        let horizontalInset = canvasWidth * borderFraction
        let verticalInset = canvasHeight * borderFraction
        let availableWidth = canvasWidth - (horizontalInset * 2)
        let availableHeight = canvasHeight - (verticalInset * 2)

        let horizontalScale = availableWidth / sourceWidth
        let verticalScale = availableHeight / sourceHeight
        let scale = min(horizontalScale, verticalScale)
        
        let photoWidth = sourceWidth * scale
        let photoHeight = sourceHeight * scale
        
        let x = (canvasWidth - photoWidth) / 2
        let y = (canvasHeight - photoHeight) / 2
        
        let rect = CGRect(x: x, y: y, width: photoWidth, height: photoHeight)
        
        return PhotoLayout(photoFrame: rect)
    }
}
