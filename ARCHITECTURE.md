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

## Current invariant

The complete source photo is proportionally scaled to fit the available inner rectangle and centered on both axes. There is no crop, zoom, focal point, rotation, or placement state. The default canvas is 1080×1080 pixels with a uniform 7% white border.

## Privacy

The normal workflow performs no network request. Export reconstructs output pixels and does not copy source metadata. The app requests only the Photos access required for the user-selected import/save actions.

## Revisit conditions

Add abstractions only when required by an implemented behavior. In particular, do not introduce manual placement state, background workers, persistence, or third-party packages before their milestone establishes a concrete need.
