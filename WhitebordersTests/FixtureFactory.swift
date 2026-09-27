import Foundation

enum FixtureFactory {
    static func pngDimensionHeader(width: UInt32, height: UInt32) -> Data {
        var data = Data([137, 80, 78, 71, 13, 10, 26, 10])
        appendBigEndian(13, to: &data)
        data.append(contentsOf: [73, 72, 68, 82])
        appendBigEndian(width, to: &data)
        appendBigEndian(height, to: &data)
        return data
    }

    static func malformedData(count: Int, seed: UInt32 = 0x5742) -> Data {
        precondition(count >= 0, "Fixture byte count cannot be negative")

        var state = seed
        var bytes = [UInt8]()
        bytes.reserveCapacity(count)
        for _ in 0..<count {
            state = state &* 1_664_525 &+ 1_013_904_223
            bytes.append(UInt8(truncatingIfNeeded: state))
        }
        return Data(bytes)
    }

    private static func appendBigEndian(_ value: UInt32, to data: inout Data) {
        var bigEndianValue = value.bigEndian
        withUnsafeBytes(of: &bigEndianValue) { bytes in
            data.append(contentsOf: bytes)
        }
    }
}

