import XCTest
@testable import Whiteborders

final class FixtureFoundationTests: XCTestCase {
    func testPNGHeaderContainsRequestedDimensions() {
        let data = FixtureFactory.pngDimensionHeader(width: 6_000, height: 4_000)

        XCTAssertEqual(Array(data.prefix(8)), [137, 80, 78, 71, 13, 10, 26, 10])
        XCTAssertEqual(readBigEndianUInt32(data, at: 16), 6_000)
        XCTAssertEqual(readBigEndianUInt32(data, at: 20), 4_000)
    }

    func testMalformedFixtureGenerationIsDeterministic() {
        XCTAssertEqual(
            FixtureFactory.malformedData(count: 32, seed: 42),
            FixtureFactory.malformedData(count: 32, seed: 42)
        )
        XCTAssertNotEqual(
            FixtureFactory.malformedData(count: 32, seed: 42),
            FixtureFactory.malformedData(count: 32, seed: 43)
        )
    }

    private func readBigEndianUInt32(_ data: Data, at offset: Int) -> UInt32 {
        data[offset..<(offset + 4)].reduce(0) { partial, byte in
            partial << 8 | UInt32(byte)
        }
    }
}

