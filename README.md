# Whiteborders

Whiteborders is a private, iPhone-first photo-framing app written in Swift and SwiftUI. The initial workflow centers a complete photo inside a square canvas with a configurable white border. Photo processing will remain on the device.

## Requirements

- Xcode 27 or newer
- iOS 18 or newer
- Swift 6

## Open and build

Open `Whiteborders.xcodeproj` in Xcode, select an iPhone simulator or connected iPhone, and run the `Whiteborders` scheme.

For a command-line build without signing:

```sh
xcodebuild \
  -project Whiteborders.xcodeproj \
  -scheme Whiteborders \
  -sdk iphonesimulator \
  -derivedDataPath /tmp/WhitebordersDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Run the unit tests with **Product → Test** (`⌘U`) in Xcode, or from the command line:

```sh
xcodebuild \
  -project Whiteborders.xcodeproj \
  -scheme Whiteborders \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' \
  -derivedDataPath /tmp/WhitebordersDerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

The current implementation includes the native editor, validated editing models, serializable commands, bounded undo/redo, PhotoKit import, production rendering, and selected-photo JPEG export to Photos. Metadata overlays and document persistence remain intentionally unwired.
