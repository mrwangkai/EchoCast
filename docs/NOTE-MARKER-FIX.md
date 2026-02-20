Read only first — confirm line numbers match, then implement.

---

## THE PROBLEM
EpisodePlayerView has two .sheet() modifiers on the same view (lines 194 
and 201). SwiftUI silently ignores the second one, and both compete with 
the parent sheet that presents EpisodePlayerView itself. This causes 
swapping instead of layering.

## THE FIX: One sheet, driven by an enum

---

## STEP 1: Add this enum at the top of EpisodePlayerView.swift 
(before the struct, not inside it)

private enum PlayerSheet: Identifiable {
    case noteCapture
    case notePreview(NoteEntity)
    
    var id: String {
        switch self {
        case .noteCapture: return "noteCapture"
        case .notePreview(let note): return "notePreview-\(note.objectID)"
        }
    }
}

---

## STEP 2: In EpisodePlayerView, replace the two @State sheet vars

Remove:
@State private var showingNoteCaptureSheet: Bool
@State private var selectedMarkerNote: NoteEntity?

Replace with single:
@State private var activeSheet: PlayerSheet? = nil

---

## STEP 3: Replace both .sheet() modifiers (lines 194 and 201) 
with one single .sheet(item:) on the root view

Remove Sheet #1 (line 194) and Sheet #2 (line 201) entirely.

Add ONE replacement:

.sheet(item: $activeSheet) { sheet in
    switch sheet {
    case .noteCapture:
        NoteCaptureSheetWrapper(
            episode: episode,
            podcast: podcast,
            currentTime: player.currentTime
        )
    case .notePreview(let note):
        NotePreviewPopover(
            note: note,
            notesAtSameTimestamp: notesAtTimestamp(note.timestamp ?? ""),
            onJumpToTime: {
                if let timestamp = note.timestamp,
                   let timeInSeconds = parseTimestamp(timestamp) {
                    player.seek(to: timeInSeconds)
                    activeSheet = nil
                }
            },
            onDismiss: {
                activeSheet = nil
            }
        )
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }
}

---

## STEP 4: Update all call sites in EpisodePlayerView

Anywhere that previously set showingNoteCaptureSheet = true:
→ Change to: activeSheet = .noteCapture

Anywhere that previously set selectedMarkerNote = note 
(timeline marker tap):
→ Change to: activeSheet = .notePreview(note)

---

## STEP 5: Fix NotesSegmentView — remove its sheet, use a callback instead

The .sheet(item: $selectedRowNote) inside NotesSegmentView (line 683) 
must be removed. Sheets nested inside child views that are inside a 
presented sheet are unreliable in SwiftUI.

Instead, add a callback to NotesSegmentView:

Change struct signature to add:
let onNoteTap: (NoteEntity) -> Void

Remove:
@State private var selectedRowNote: NoteEntity? = nil

Change note row tap from:
selectedRowNote = note
To:
onNoteTap(note)

Remove the entire .sheet(item: $selectedRowNote) block from notesListView.

---

## STEP 6: Update the NotesSegmentView call site in EpisodePlayerView

Find where NotesSegmentView is instantiated and add the callback:

NotesSegmentView(
    notes: ...,
    addNoteAction: ...,
    player: player,
    selectedSegment: $selectedSegment,
    onNoteTap: { note in
        activeSheet = .notePreview(note)
    }
)

---

## STEP 7: Build

Build only. Report pass or fail with exact errors.
Do not fix errors without reporting first.

---

## STEP 8: If build passes

git add -A
git commit -m "Fix sheet conflict: single activeSheet enum drives all player sheets"

Report commit hash.
