# Claude Code Prompt: Note Preview Overlay Card

**Goal:** Tapping a note marker on the timeline OR tapping a note row in the
Notes tab shows a floating overlay card INSIDE EpisodePlayerView. No new
sheets — the card appears as a ZStack layer within the existing player.
From the card, the user can jump to the timestamp or dismiss.

Checkpoint: if anything breaks, revert to `998185f`.

Do NOT use web search. Read files first, then implement in order.

---

## STEP 1: Read — no changes yet

Read `EchoNotes/Views/Player/EpisodePlayerView.swift` and report:

1. All `@State` variables at the top of EpisodePlayerView
2. The outermost view structure of `body` — first 20 lines
3. Every `.sheet()` modifier currently in the file
4. The current note marker tap handler
5. The current NotesSegmentView call site (how onNoteTap is wired)
6. The full NotesSegmentView struct signature

Report before touching anything.

---

## STEP 2: Add overlay state to EpisodePlayerView

Add exactly these two `@State` vars — types must be exact:

```swift
@State private var previewNote: NoteEntity? = nil
@State private var showingNotePreview: Bool = false
```

⚠️ Critical: the type MUST be `NoteEntity?` not `Entity?` or any
other type. Double-check after adding.

---

## STEP 3: Create NoteOverlayCard

Add this as a private struct at the BOTTOM of EpisodePlayerView.swift:

```swift
private struct NoteOverlayCard: View {
    let note: NoteEntity
    let allNotesAtTimestamp: [NoteEntity]
    let onJump: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Header: timestamp badge + note count + close button
            HStack {
                if let timestamp = note.timestamp {
                    Text(timestamp)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.102, green: 0.235, blue: 0.204))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.mintAccent)
                        .clipShape(Capsule())
                }

                if allNotesAtTimestamp.count > 1 {
                    Text("\(allNotesAtTimestamp.count) notes here")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }

            // Note text
            if let text = note.noteText, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Tags
            let tags = note.tagsArray
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Jump button
            Button(action: onJump) {
                HStack {
                    Image(systemName: "arrow.forward.circle.fill")
                    Text("Jump to time")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.mintAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.mintAccent.opacity(0.15))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.14, green: 0.14, blue: 0.16))
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -4)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
```

---

## STEP 4: Wrap body in a ZStack with the overlay

The existing body content becomes the bottom layer. Add the overlay
card as the top layer, gated by `showingNotePreview`.

```swift
var body: some View {
    ZStack(alignment: .bottom) {

        // ── EXISTING BODY CONTENT (unchanged) ──
        // Move ALL current body content here as-is.
        // Keep ALL existing modifiers (.background, .presentationDetents,
        // .sheet(item: $activeSheet), etc.) attached to this inner content.

        // ── OVERLAY LAYER ──
        if showingNotePreview, let note = previewNote {

            // Dimming background — tap to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showingNotePreview = false
                        previewNote = nil
                    }
                }

            NoteOverlayCard(
                note: note,
                allNotesAtTimestamp: notesAtTimestamp(note.timestamp ?? ""),
                onJump: {
                    if let timestamp = note.timestamp,
                       let timeInSeconds = parseTimestamp(timestamp) {
                        player.seek(to: timeInSeconds)
                        withAnimation(.spring(response: 0.3)) {
                            showingNotePreview = false
                            previewNote = nil
                            selectedSegment = 0
                        }
                    }
                },
                onDismiss: {
                    withAnimation(.spring(response: 0.3)) {
                        showingNotePreview = false
                        previewNote = nil
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    // No modifiers here — all modifiers stay on the inner content view
}
```

---

## STEP 5: Update trigger locations

### Marker tap (timeline):
Find the Button inside the ForEach marker block. Replace its action with:

```swift
Button {
    if let firstNote = group.notes.first {
        withAnimation(.spring(response: 0.3)) {
            previewNote = firstNote       // NoteEntity, not Entity
            showingNotePreview = true
        }
    }
} label: { ... }
```

### Note row tap (Notes tab):
The onNoteTap callback in the NotesSegmentView call site should be:

```swift
onNoteTap: { note in
    withAnimation(.spring(response: 0.3)) {
        previewNote = note               // NoteEntity, not Entity
        showingNotePreview = true
    }
}
```

---

## STEP 6: PlayerSheet enum — remove .notePreview if present

If the PlayerSheet enum still has a `.notePreview(NoteEntity)` case,
remove it. Only `.noteCapture` should remain.

Remove any `.notePreview` case from the `.sheet(item: $activeSheet)`
switch block as well.

---

## STEP 7: Type safety verification

Before building, run this and paste the output:

```
grep -n "previewNote" EchoNotes/Views/Player/EpisodePlayerView.swift
```

Confirm that every occurrence of `previewNote` refers to type
`NoteEntity?` — not `Entity?` or any other type.
If any line shows the wrong type, fix it before building.

---

## STEP 8: Build

Build only. Report pass or fail with exact errors.
Do not fix errors without reporting first.

---

## STEP 9: If build passes

```bash
git add -A
git commit -m "Note preview: ZStack overlay card inside player, no nested sheets"
```

Report commit hash.

---

## Expected behavior when complete

- Tapping a timeline marker → overlay card slides up from bottom of player
- Tapping a note row in Notes tab → same overlay card
- Player artwork, controls, and context remain fully visible behind card
- Dimming layer behind card, tap outside to dismiss
- "Jump to time" seeks player, switches to Listening tab, dismisses card
- Dismissing without jumping leaves playback unchanged
- No sheet swapping, no nested sheet conflicts
