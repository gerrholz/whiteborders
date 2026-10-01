# Whiteborders native implementation milestones

## Review contract

Each milestone introduces one primary concept, includes focused tests where behavior exists, passes the Xcode build/test gate, and receives explicit approval before the next milestone begins.

| ID  | Milestone                              | Status    | Depends on |
| --- | -------------------------------------- | --------- | ---------- |
| N01 | Native SwiftUI visual prototype        | Complete  | —          |
| N02 | XCTest and fixture foundation          | Complete  | N01        |
| N03 | Canonical editing document             | Complete  | N02        |
| N04 | Commands, scopes, and undo/redo        | Complete  | N03        |
| N05 | Deterministic centered-contain layout  | Complete  | N03        |
| N06 | PhotoKit import and resource lifecycle | Complete  | N02        |
| N07 | Core Graphics preview renderer         | In review | N05, N06   |
| N08 | JPEG export and Photos delivery        | In review | N07        |
| N09 | Metadata extraction and overlay        | Deferred  | N06, N07   |
| N10 | Accessibility and release hardening    | Planned   | N08        |
| N11 | App Store archive and release          | Planned   | N10        |

## N01 — Native SwiftUI visual prototype

**Outcome:** The iPhone editor is recognizable and reviewable before production behavior is attached.

**Deliverables:** An iPhone-only Xcode project, SwiftUI editor shell, square centered-photo preview, 7% white border, fixture photo strip, border control, metadata toggle, and save affordance.

**Excluded:** Real Photos access, rendering, export, document state, and persistence.

## N02 — XCTest and fixture foundation

**Outcome:** Native behavior can be developed test-first with controlled assets.

**Deliverables:** Unit-test target, fixture provenance, deterministic dimension helpers, and one UI-independent smoke test.

## N03 — Canonical editing document

**Outcome:** A `Codable`, `Equatable`, `Sendable` value describes one square photo composition without retaining image resources.

**Deliverables:** Branded identifier value types, versioned document, canvas/photo/border/layout/metadata values, defaults, validation, and examples used by tests and the prototype.

## N04 — Commands, scopes, and undo/redo

**Outcome:** Serializable commands produce immutable document snapshots through a pure reducer.

**Deliverables:** Command enum, this/selected/all scopes, bounded history, undo/redo, redo invalidation, and slider-gesture coalescing.

## N05 — Deterministic centered-contain layout

**Outcome:** Pure geometry fits and centers the complete source image without cropping or stretching.

## N06 — PhotoKit import and resource lifecycle

**Outcome:** A user selects a JPEG/PNG-backed photo and the app retains only the resources needed for the temporary session.

## N07 — Core Graphics preview renderer

**Outcome:** The editor displays a production preview using the same geometry rules intended for export.

## N08 — JPEG export and Photos delivery

**Outcome:** The user saves a newly encoded JPEG of the selected composition to Photos without copied source metadata.

## N09 — Metadata extraction and overlay

**Outcome:** Selected camera settings can be rendered visibly without retaining unrelated metadata. This is deferred until the core import, edit, and export workflow is approved.

## N10 — Accessibility and release hardening

**Outcome:** VoiceOver, Dynamic Type, failure recovery, privacy declarations, memory behavior, and real-device workflows are release-ready.

## N11 — App Store archive and release

**Outcome:** A signed archive passes validation and is ready for TestFlight/App Store distribution.
