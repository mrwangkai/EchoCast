# Claude Code Prompt: Unified Note Preview Sheet

**Goal:** Tapping a note marker on the timeline OR tapping a note row in the Notes tab both open the same `NotePreviewSheet`. The sheet appears layered ON TOP of the player (not swapping with it). From the preview, the user can choose to jump to the timestamp or dismiss.

Do NOT use web search. Read files first, then implement in the order below.

---

## STEP 1: Read — no changes yet

Read these files and report findings:

**`EchoNotes/Views/Player/EpisodePlayerView.swift`**
- All `@State` variables at the top
- Every `.sheet()` modifier on the root view
- The current note marker rendering code (the GeometryReader/ForEach block)
- The Notes tab content — specifically how note rows are rendered and what their tap action is currently

**`EchoNotes/Models/NoteEntity+Extensions.swift`** (or wherever `tagsArray` and `noteText` are defined)
- Confirm property names: `noteText`, `timestamp`, `isPriority`, `tagsArray`

Report all findings before touching anything.

---

## STEP 2: Create `NotePreviewSheet`

Add this as a **private struct at the bottom of `EpisodePlayerView.swift`** (not a separate file).

This is the single shared preview used by both entry points.

```swift
private struct NotePreviewSheet: View {
    let notes: [NoteEntity]                  // 1 note from row tap, 1+ from marker tap
    let onJumpToTime: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(notes) { note in
                        NotePreviewCard(note: note) { timeInSeconds in
                            onJumpToTime(timeInSeconds)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.102, green: 0.235, blue: 0.204)) // #1a3c34
        .presentationDetents(notes.count == 1 ? [.medium] : [.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

private struct NotePreviewCard: View {
    let note: NoteEntity
    let onJump: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Timestamp badge
            if let timestamp = note.timestamp {
                HStack {
                    Text(timestamp)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.102, green: 0.235, blue: 0.204))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0, green: 0.784, blue: 0.702)) // mintAccent #00c8b3
                        .clipShape(Capsule())

                    Spacer()

                    if note.isPriority {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0, green: 0.784, blue: 0.702))
                    }
                }
            }

            // Note text
            if let text = note.noteText, !text.isEmpty {
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
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
                                .background(Color.white.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Jump button
            if let timestamp = note.timestamp,
               let timeInSeconds = parseTimestamp(timestamp) {
                Button {
                    onJump(timeInSeconds)
                } label: {
                    Label("Jump to \(timestamp)", systemImage: "arrow.forward.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0, green: 0.784, blue: 0.702))
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }

    private func parseTimestamp(_ timestamp: String) -> Double? {
        let parts = timestamp.split(separator: ":").compactMap { Double($0) }
        switch parts.count {
        case 2: return parts[0] * 60 + parts[1]
        case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
        default: return nil
        }
    }
}
```

---

## STEP 3: Create `NoteMarkersLayer` — owns the marker sheet state

Replace the inline GeometryReader marker rendering with this wrapper view. It owns its own sheet state so the preview appears **inside** the already-presented player sheet, not competing with it.

Add as a **private struct inside `EpisodePlayerView.swift`**:

```swift
private struct NoteMarkersLayer: View {
    let notes: [NoteEntity]
    let duration: Double
    let onJump: (Double) -> Void

    @State private var selectedNotes: [NoteEntity] = []
    @State private var showingPreview = false

    var body: some View {
        GeometryReader { geo in
            let grouped = groupByProximity(Array(notes), threshold: 30)

            ForEach(Array(grouped.enumerated()), id: \.offset) { _, group in
                if let first = group.first,
                   let ts = first.timestamp,
                   let secs = parseTimestamp(ts),
                   duration > 1 {

                    Button {
                        selectedNotes = group
                        showingPreview = true
                    } label: {
                        ZStack {
                            Capsule()
                                .fill(Color(red: 0, green: 0.784, blue: 0.702)) // mintAccent
                                .frame(width: group.count > 1 ? 24 : 16, height: 16)

                            if group.count > 1 {
                                Text("\(group.count)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color(red: 0.102, green: 0.235, blue: 0.204))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .position(
                        x: (secs / duration) * geo.size.width,
                        y: geo.size.height / 2 - 14  // float above track
                    )
                }
            }
        }
        .sheet(isPresented: $showingPreview) {
            NotePreviewSheet(notes: selectedNotes, onJumpToTime: onJump)
        }
    }

    private func parseTimestamp(_ ts: String) -> Double? {
        let parts = ts.split(separator: ":").compactMap { Double($0) }
        switch parts.count {
        case 2: return parts[0] * 60 + parts[1]
        case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
        default: return nil
        }
    }

    private func groupByProximity(_ notes: [NoteEntity], threshold: Double) -> [[NoteEntity]] {
        var groups: [[NoteEntity]] = []
        var remaining = notes.compactMap { note -> (NoteEntity, Double)? in
            guard let ts = note.timestamp, let secs = parseTimestamp(ts) else { return nil }
            return (note, secs)
        }.sorted { $0.1 < $1.1 }

        while !remaining.isEmpty {
            let first = remaining.removeFirst()
            var group = [first.0]
            remaining = remaining.filter { item in
                if abs(item.1 - first.1) <= threshold {
                    group.append(item.0)
                    return false
                }
                return true
            }
            groups.append(group)
        }
        return groups
    }
}
```

---

## STEP 4: Update the progress bar to use `NoteMarkersLayer`

In the `timeProgressWithMarkers` property, replace the existing inline `GeometryReader` + `ForEach` marker block with:

```swift
NoteMarkersLayer(
    notes: Array(notes),
    duration: player.duration,
    onJump: { timeInSeconds in
        player.seek(to: timeInSeconds)
    }
)
.frame(height: 20)
```

Remove any `@State private var selectedMarkerNotes` and `@State private var showingMarkerPreview` that were previously on `EpisodePlayerView`, along with the corresponding `.sheet(isPresented: $showingMarkerPreview)` on the root view.

---

## STEP 5: Update Notes tab rows to use the same preview

In the Notes tab content (wherever note rows are rendered with a tap action), create a local notes layer that also owns its own sheet state. Add a `@State` pair directly in the notes tab view or use a small wrapper:

Find the note row tap handler — it currently likely calls `player.seek(to:)` and switches the segment to Listening. Replace it with:

```swift
// In the notes list, each row button becomes:
Button {
    selectedPreviewNotes = [note]   // single note
    showingNotePreview = true
} label: {
    // existing note row UI — no visual change
}
```

Add to EpisodePlayerView (or the notes tab subview, whichever owns the notes list):

```swift
@State private var selectedPreviewNotes: [NoteEntity] = []
@State private var showingNotePreview = false
```

And attach the sheet to the **ScrollView or VStack inside the notes tab** (not on the root view):

```swift
.sheet(isPresented: $showingNotePreview) {
    NotePreviewSheet(notes: selectedPreviewNotes) { timeInSeconds in
        player.seek(to: timeInSeconds)
        selectedSegment = 0  // switch back to Listening tab after jump
    }
}
```

**Critical:** Attach this `.sheet` to the inner notes content view, NOT to `EpisodePlayerView`'s body. This ensures it presents as a new layer on top of the player, not competing with the parent sheet.

---

## STEP 6: Remove old note row seek behavior

Now that tapping a row opens the preview instead of seeking directly, remove any direct `player.seek(to:)` + `selectedSegment = 0` calls from note row tap handlers in the Notes tab. The jump now happens from inside `NotePreviewSheet`.

---

## STEP 7: Build and verify

Build only. Report pass or fail with exact errors. Do not fix errors without reporting first.

**Expected behavior when complete:**

- Tapping a marker on the timeline → `NotePreviewSheet` appears on top of the player
- Tapping a note row in the Notes tab → same `NotePreviewSheet` appears on top of the player
- The player stays visible/active underneath in both cases
- "Jump to [time]" in the preview → seeks player, switches to Listening tab, dismisses preview
- Dismissing preview without jumping → returns to player with no change to playback
- Multiple nearby notes grouped into one marker → preview shows all notes as stacked cards, each with their own jump button
