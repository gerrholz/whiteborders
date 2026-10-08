# Whiteborders architecture

Status: Native implementation baseline

## Platform

Whiteborders is an iPhone application built with Swift 6 and SwiftUI. The minimum deployment target is iOS 18. Xcode is the build, test, signing, archive, and release toolchain. The web/PWA architecture has been retired.

## Boundaries

```text
SwiftUI presentation
        ↓ commands
Editing document and history
        ↓ source/resource identifiers
PhotoKit and image resource adapters
        ↓ render plan
Core Graphics / Image I/O renderer
        ↓
Photos and share-sheet delivery
```

- Presentation owns controls, accessibility, navigation, and transient gesture state.
- The editing model lives in `Whiteborders/Models` and is made from `Codable`, `Equatable`, and `Sendable` value types. It contains a photo identifier and dimensions, never `UIImage`, `CGImage`, Photos framework objects, or encoded bytes.
- Commands are serializable values reduced into new document snapshots.
- History is bounded and remains in memory for the temporary editing session.
- SwiftUI screens and screen-specific components live under `Whiteborders/Features`; the application entry point lives under `Whiteborders/App`.
- PhotoKit authorization and resources enter through adapters rather than the document.
- Rendering will use one deterministic geometry implementation for preview and export.
- Export encodes the renderer's reconstructed pixels as a new JPEG and saves that data through PhotoKit, so source metadata is not copied into the delivered image.

## Current invariant

The complete source photo remains at its native pixel dimensions and is centered on both axes. A canvas with the selected fixed aspect ratio is derived from the source photo and requested border fraction, rounding its common ratio scale upward to a whole pixel. Canvas dimensions are calculated layout output rather than stored document state. There is no crop, zoom, focal point, rotation, or placement state. The default aspect ratio is 1:1 and the default border is uniform 7% white.

## Privacy

The normal workflow performs no network request. Export reconstructs output pixels and does not copy source metadata. The app requests only the Photos access required for the user-selected import/save actions.

## Revisit conditions

Add abstractions only when required by an implemented behavior. In particular, do not introduce manual placement state, background workers, persistence, or third-party packages before their milestone establishes a concrete need.
