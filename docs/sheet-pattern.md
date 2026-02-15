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
    EpisodePlayerView(episode: episode, podcast: podcast)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
}
```

Setting the optional to a non-nil value presents the sheet.
Setting it back to nil (or the user dismissing) closes it.
The item is passed directly into the closure — no optional unwrapping needed.

---

## Required Presentation Modifiers

**Every sheet that presents a full-screen player or content view MUST include these
two modifiers at the call site (on the presented view, inside the sheet closure):**

```swift
.presentationDetents([.large])
.presentationDragIndicator(.visible)
```

### Why these are required

**`.presentationDetents([.large])`**
Without this, iOS presents the sheet edge-to-edge with no top gap — the sheet fills
the entire screen including the top safe area. With `.large`, iOS presents it as a
standard card sheet with:
- Rounded top corners
- A visible gap between the sheet and the top of the screen
- The correct background dimming on the content behind it

Without `.presentationDetents`, any drag handle rendered inside the view has no
visible room and appears to be cut off or missing.

**`.presentationDragIndicator(.visible)`**
This shows the system-provided drag indicator (the small pill at the top of the
sheet). It is preferred over rendering a custom drag handle inside the view itself,
because the system indicator is always correctly positioned relative to the sheet
chrome. Do not render a custom `RoundedRectangle` drag handle inside `EpisodePlayerView`
or any other presented view — let the system handle it.

### Where to apply them

Apply at the **call site**, not inside the presented view:

```swift
// ✅ CORRECT — modifiers on the presented view, inside the sheet closure
.sheet(item: $selectedEpisode) { episode in
    EpisodePlayerView(episode: episode, podcast: podcast)
        .presentationDetents([.large])          // ← here
        .presentationDragIndicator(.visible)    // ← here
}
```

```swift
// ❌ WRONG — modifiers applied somewhere inside EpisodePlayerView's body
// This affects a child sheet (e.g. note capture sheet), not the player sheet itself
var body: some View {
    VStack { ... }
        .presentationDetents([.large])  // ← this is scoped wrong
}
```

### Sheets that do NOT need these modifiers

Small or medium sheets (e.g. AddNoteSheet, settings panels) may use a different
detent. Apply the appropriate size:

```swift
// Medium height sheet — e.g. note capture
.sheet(isPresented: $showingNoteCapture) {
    AddNoteSheet(...)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
}
```

Note: even flag-based sheets should still include the presentation modifiers.

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

## Do Not Render Custom Drag Handles Inside Presented Views

Since `.presentationDragIndicator(.visible)` is always applied at the call site,
there is no need to render a custom drag handle (a `RoundedRectangle` pill) inside
`EpisodePlayerView` or any other presented view. Remove any existing custom handles
from inside presented views — they will appear doubled or incorrectly positioned.

```swift
// ❌ Remove this from inside EpisodePlayerView or any presented view
RoundedRectangle(cornerRadius: 2.5)
    .fill(Color.white.opacity(0.3))
    .frame(width: 36, height: 5)
    .padding(.top, 8)
```

The system indicator replaces this entirely.

---

## Complete Example: Episode Player Sheet

```swift
// In the parent view (e.g. PodcastDetailView, HomeView)

@State private var selectedEpisode: RSSEpisode?

// Tap handler
Button(action: {
    GlobalPlayerManager.shared.loadEpisodeAndPlay(episode, podcast: podcast)
    selectedEpisode = episode
}) {
    EpisodeRowView(episode: episode)
}

// Sheet presentation
.sheet(item: $selectedEpisode) { episode in
    EpisodePlayerView(episode: episode, podcast: podcast)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
}
```

---

## Checklist Before Adding Any New Sheet

- [ ] Is this sheet displaying a selected item? → use `.sheet(item:)`
- [ ] Is this sheet just a flag with no data? → `.sheet(isPresented:)` is fine
- [ ] Does the item type conform to `Identifiable`?
- [ ] Have I removed the companion Bool state variable?
- [ ] Does the sheet have `.presentationDetents([.large])` at the call site?
- [ ] Does the sheet have `.presentationDragIndicator(.visible)` at the call site?
- [ ] Is there a custom drag handle inside the presented view? → remove it
- [ ] Does the sheet dismiss correctly (via `@Environment(\.dismiss)`)?

---

## How to Reference It in Future Prompts

Any time you ask Claude Code to build something with a sheet, add one line:

```
Before writing any sheet code, read docs/sheet-pattern.md and follow it exactly.
```
