# T66: Your Notes — Empty State (Listen → Capture → Remember)

## Task
Implement the "Your Notes" empty state on the Home screen. When a user has zero notes,
the section shows a three-column illustrative card explaining the capture loop.
Once the first note is saved, this card disappears and real note content takes its place.

## Design spec
Three equal-width columns inside a single rounded card:

| Column | Verb | Sub-copy | Icon treatment |
|--------|------|----------|----------------|
| 1 | Listen | Play any episode | 🎧 emoji on neutral bg |
| 2 | Capture | Right as you hear it | ✎ on `mintAccent` bg |
| 3 | Remember | Ideas that stick | Mini note preview (timestamp chip + 2 lines) |

- Columns separated by 1px vertical dividers + a `›` arrow connector between each
- Verb 2 ("Capture") uses `mintAccent` color; Verbs 1 and 3 use `echoTextPrimary`
- Card background: `noteCardBackground` token; border: `echoSeparator` token; corner radius: 14pt
- Section header: "Your Notes" in standard `sh-t` style (same as "Continue Listening")
- No "View all" link when empty

## Condition
Show this card when: `notes.isEmpty` (fetched from Core Data `NoteEntity`)
Hide (replace with real content) when: `notes.count > 0`

## Phase 1 — Diagnose (read-only, no changes)

1. In `HomeView.swift`, locate:
   - Where the "Your Notes" section currently renders (line numbers)
   - The existing `@FetchRequest` or fetch call for `NoteEntity` — confirm the predicate
   - The current empty state treatment (if any) for notes
   - The horizontal screen padding value in use (should match `EchoSpacing.screenPadding`)

2. In `EchoCastDesignTokens.swift`, confirm these tokens exist and report their values:
   - `noteCardBackground`
   - `echoSeparator` (or equivalent border color token)
   - `mintAccent`
   - `echoTextPrimary`
   - `echoTextTertiary`

3. Report findings. Stop and wait for confirmation before any changes.

## Phase 2 — Implement (only after Phase 1 confirmed)

### New component: `NotesEmptyStateCard.swift`
Do NOT create a new file unless the component exceeds ~60 lines.
Prefer a private sub-view inside `HomeView.swift`.

```swift
// Render condition (in HomeView notes section):
if notes.isEmpty {
    NotesEmptyStateCard()
} else {
    // existing note cards
}
```

### NotesEmptyStateCard layout

```swift
HStack(spacing: 0) {
    NotesEmptyStep(
        icon: { /* 🎧 in neutral rounded rect */ },
        verb: "Listen",
        sub: "Play any episode",
        accentVerb: false
    )
    Divider() // 1pt, echoSeparator color
    // arrow connector "›" overlaid between columns
    NotesEmptyStep(
        icon: { /* ✎ on mintAccent bg */ },
        verb: "Capture",
        sub: "Right as you hear it",
        accentVerb: true   // mintAccent color on verb
    )
    Divider()
    NotesEmptyStep(
        icon: { /* mini note preview */ },
        verb: "Remember",
        sub: "Ideas that stick",
        accentVerb: false
    )
}
.background(Color.noteCardBackground)
.clipShape(RoundedRectangle(cornerRadius: 14))
.overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.echoSeparator, lineWidth: 1))
```

### "Remember" icon — mini note preview
A small `VStack` inside a neutral rounded rect (same size as the other icons):
- Top-trailing: a tiny timestamp chip ("1:23") — `mintAccent` text, `mintAccent` dim bg, 1pt border
- Two `Capsule` shapes for note content lines (full width, then 65% width)
- Use `echoTextTertiary` opacity fills for the capsules

### Arrow connectors between columns
Overlay a `›` character centered vertically between each divider.
Use `echoTextTertiary` (low opacity), font size 12pt.

### Sizing
- Icon wells: 38×38pt, cornerRadius 10pt
- Verb: `.caption2Medium()` font token (or closest available), `echoTextPrimary`
- Sub-copy: `.caption2()` or 9pt, `echoTextTertiary`
- Column vertical padding: 15pt top, 14pt bottom
- Horizontal padding per column: 6pt each side

## Constraints
- No new files unless component exceeds 60 lines
- Check `EchoCastDesignTokens.swift` before using any color or font literals
- Do not touch `NoteCardView`, `NoteRowView`, or any existing note display component
- Do not change the fetch request or notes data flow — only add the conditional branch
- Route any discovered issues to `echocast_todo.md` Inbox

## Git
Branch: `t66-notes-empty-state`
Commit message: `feat(T66): add Listen→Capture→Remember empty state to Your Notes section`
Update `echocast_todo.md`: move T66 to Done with commit hash.
