# EchoCast Sheet Presentation Pattern

**Rule: Always use `.sheet(item:)` when a sheet displays data tied to a selected item.**

---

## The Problem with `.sheet(isPresented:)`

Using a Bool + optional together creates a race condition:
```swift
// ❌ BROKEN — do not use this pattern
@State private var selectedEpisode: Episode?
@State private var showingPlayer = false

row.onTapGesture {
    selectedEpisode = episode  // Step 1: set data
    showingPlayer = true       // Step 2: show sheet
}

.sheet(isPresented: $showingPlayer) {
    if let episode = selectedEpisode { // May still be nil — race!
        EpisodePlayerView(episode: episode)
    }
}
```

SwiftUI can evaluate the sheet content before `selectedEpisode` is set.
Result: blank sheet on first tap, works on second tap.
This has caused repeated bugs in EchoCast — do not reintroduce this pattern.

---

## The Correct Pattern
```swift
// ✅ CORRECT — use this for all item-driven sheets
@State private var selectedEpisode: Episode?  // one variable, no Bool

row.onTapGesture {
    selectedEpisode = episode  // single atomic operation
}

.sheet(item: $selectedEpisode) { episode in  // SwiftUI handles presentation
    EpisodePlayerView(episode: episode)
}
```

Setting the optional to a non-nil value presents the sheet.
Setting it back to nil (or the user dismissing) closes it.
The item is passed directly into the closure — no optional unwrapping needed.

---

## Requirements

The type passed to `.sheet(item:)` must conform to `Identifiable`.

- Core Data entities: already conform via their `id: UUID` property ✅
- RSS/API model structs: add `Identifiable` if missing
```swift
// If a struct is missing Identifiable:
struct RSSEpisode: Identifiable, Codable {
    var id: String { guid ?? url ?? title ?? UUID().uuidString }
    // ...
}
```

---

## When `.sheet(isPresented:)` Is Still Fine

Use `isPresented` only when the sheet has **no associated data item**:
```swift
// ✅ Fine — no item, just a flag
@State private var showingSettings = false

settingsButton.onTapGesture {
    showingSettings = true
}

.sheet(isPresented: $showingSettings) {
    SettingsView()
}
```

---

## Dismissal

From inside the sheet, dismiss normally:
```swift
struct NoteDetailSheetView: View {
    @Environment(\.dismiss) private var dismiss
    // No need to nil out selectedNote — SwiftUI handles it on dismiss
}
```

If you need to dismiss programmatically from the parent, nil out the item:
```swift
selectedNote = nil  // closes the sheet
```

---

## Checklist Before Adding Any New Sheet

- [ ] Is this sheet displaying a selected item? → use `.sheet(item:)`
- [ ] Is this sheet just a flag with no data? → `.sheet(isPresented:)` is fine
- [ ] Does the item type conform to `Identifiable`?
- [ ] Have I removed the companion Bool state variable?
- [ ] Does the sheet dismiss correctly (via `@Environment(\.dismiss)`)?
```

---

## How to Reference It in Future Prompts

Any time you ask Claude Code to build something with a sheet, add one line:
```
Before writing any sheet code, read docs/SHEET-PATTERN.md and follow it exactly.
