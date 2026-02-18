# Notes Tab Figma Redesign + Note Marker Improvements

**Branch:** `feature/notes-tab-figma-redesign`  
**Figma Reference:** https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=2262-5361  
**Scope:** Notes tab layout redesign + Note marker interaction improvements + "Go back" button for scrubbing

---

## PART A: Listening Tab with Embedded Notes List

### Context

The Figma design at node 2262-5361 shows **notes embedded directly in the Listening tab**, scrolling above the player controls. This is a fundamental UX change from the current 3-tab pattern (Listening / Notes / Episode Info). The new design removes the separate Notes tab entirely and integrates notes into the Listening experience.

### Design Specifications from Figma (Screenshot Analysis)

**Layout Structure:**
1. **Top:** Segmented control (Listening selected, Notes grayed out, Episode Info)
2. **Scrollable content area:** Notes list (5 visible in screenshot)
3. **Sticky bottom:** Episode metadata, progress bar, playback controls, "Add note" button

**Individual Note Row:**
- **Timestamp:** Left column, fixed width (~60pt), white text, 13pt regular (not semibold as originally stated)
- **Note text:** Right column, flexible width, white text, 13pt regular, 2 lines max
- **Divider:** Thin white line (10% opacity) between rows
- **No card backgrounds:** Just rows with dividers

**Typography:**
- Both timestamp and note text use **Footnote / Regular (13pt)** — same weight
- Text color: White 100% (echoTextPrimary)

**Content Height:**
- Notes list scrolls within ~317pt content area
- Player controls remain sticky at bottom

### Implementation Steps

**File:** `EpisodePlayerView.swift` — specifically the `listeningTabContent` section.

#### Step 1: Replace Listening Tab Content with ScrollView + Notes List

Find `listeningTabContent` (currently shows artwork + metadata). Replace with scrollable notes list:

```swift
private var listeningTabContent: some View {
    ScrollView {
        VStack(spacing: 0) {
            if notes.isEmpty {
                emptyNotesInListeningTab
            } else {
                notesListEmbedded
            }
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
    }
}
```

#### Step 2: Create Embedded Notes List Component

Add this new computed property:

```swift
private var notesListEmbedded: some View {
    VStack(spacing: 0) {
        ForEach(notes) { note in
            Button {
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                // Seek to timestamp
                if let timestamp = note.timestamp,
                   let timeInSeconds = parseTimestamp(timestamp) {
                    player.seek(to: timeInSeconds)
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Timestamp (left, fixed width)
                    Text(note.timestamp ?? "")
                        .font(.system(size: 13, weight: .regular))  // Footnote Regular
                        .foregroundColor(.echoTextPrimary)
                        .frame(width: 60, alignment: .leading)
                    
                    // Note text (right, flexible width)
                    Text(note.noteText ?? "")
                        .font(.system(size: 13, weight: .regular))  // Footnote Regular
                        .foregroundColor(.echoTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteNote(note)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            // Divider between rows
            if note != notes.last {
                Divider()
                    .background(Color.white.opacity(0.1))
            }
        }
    }
}
```

#### Step 3: Add Empty State for Embedded Notes

```swift
private var emptyNotesInListeningTab: some View {
    VStack(spacing: 16) {
        Spacer()
        
        Image(systemName: "note.text")
            .font(.system(size: 48))
            .foregroundColor(.white.opacity(0.3))
        
        Text("No notes yet")
            .font(.title2Echo())
            .foregroundColor(.echoTextPrimary)
        
        Text("Tap 'Add note at current time' below to capture your thoughts")
            .font(.bodyEcho())
            .foregroundColor(.echoTextSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        
        Spacer()
    }
    .frame(maxWidth: .infinity)
    .frame(height: 300)  // Approximate content area height
}
```

#### Step 4: Update Player Controls Section to Include Episode Metadata

The player controls are sticky at the bottom. Episode metadata should be directly above the progress bar:

```swift
private var playerControlsSection: some View {
    VStack(spacing: 16) {
        // Episode metadata (title + podcast name)
        VStack(spacing: 4) {
            Text(podcast.title ?? "This American Life")
                .font(.caption2Medium())
                .foregroundColor(.echoTextSecondary)
            
            Text(episode.title)
                .font(.bodyRoundedMedium())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(1)
        }
        
        // Existing player controls (progress bar, buttons, etc.)
        timeProgressWithMarkers
        playbackControlButtons
        
        // Add note button
        addNoteButton
    }
    .padding(.horizontal, EchoSpacing.screenPadding)
    .padding(.bottom, 24)
    .background(Color.echoBackground)
}
```

#### Step 5: Hide/Disable the "Notes" Segmented Control Option

Since notes are now embedded in Listening tab, the Notes segment should be removed or disabled:

**Option 1 — Remove Notes segment entirely:**

```swift
Picker("Tab", selection: $selectedSegment) {
    Text("Listening").tag(0)
    // Remove: Text("Notes").tag(1)
    Text("Episode Info").tag(1)  // Renumber from 2 to 1
}
.pickerStyle(.segmented)
```

**Option 2 — Keep but disable (matches Figma screenshot):**

```swift
// If you want to keep the visual but disable interaction, show as grayed out
// This requires custom segmented control styling, which is complex
// Recommend Option 1 for simplicity
```

#### Step 6: Update selectedSegment Logic

Since Notes tab is removed, update any code that references `selectedSegment`:

```swift
// Old: 0 = Listening, 1 = Notes, 2 = Episode Info
// New: 0 = Listening, 1 = Episode Info

// In content switcher:
switch selectedSegment {
case 0:
    listeningTabContent  // Now shows notes list + sticky controls
case 1:
    episodeInfoTabContent
default:
    EmptyView()
}
```

---

## PART B: Note Marker Visual & Interaction Improvements

### B1: Visual — Darker Background with White Outline

**Problem:** Current mint-filled circles don't pop against dark mode background.

**Solution:** Darker mint fill + white outline for accessibility.

**File:** `EpisodePlayerView.swift` — in the `timeProgressWithMarkers` section where note markers are rendered.

**Find the marker render code (it will look like):**

```swift
ForEach(notes.filter { $0.timestamp != nil }) { note in
    if let timestamp = note.timestamp,
       let timeInSeconds = parseTimestamp(timestamp),
       player.duration > 0 {
        Circle()
            .fill(Color.mintAccent)
            .frame(width: 12, height: 12)
            // ...position logic
    }
}
```

**Replace with:**

```swift
ForEach(notes.filter { $0.timestamp != nil }) { note in
    if let timestamp = note.timestamp,
       let timeInSeconds = parseTimestamp(timestamp),
       player.duration > 0 {
        
        ZStack {
            // White outline (accessibility contrast)
            Circle()
                .stroke(Color.white, lineWidth: 2)
            
            // Darker mint fill (60% opacity for better dark mode contrast)
            Circle()
                .fill(Color.mintAccent.opacity(0.6))
                .padding(2)  // Inset from stroke
        }
        .frame(width: 14, height: 14)  // Slightly larger for outline
        .position(
            x: markerPosition(timeInSeconds, width: geometry.size.width),
            y: geometry.size.height / 2
        )
    }
}
```

**Accessibility check:** The white stroke at 2pt width + darker mint fill at 60% opacity should pass WCAG AA contrast requirements against `Color.echoBackground` (#262626).

**Key changes:**
1. Wrap marker in ZStack
2. Outer circle: white stroke, 2pt width
3. Inner circle: mint accent at 60% opacity (darker), padded 2pt inset
4. Increase frame to 14x14pt to accommodate stroke

---

### B2: Interaction — Tap-to-Reveal Note Preview Popover

**Problem:** Markers are too small to tap accurately without disrupting scrubber interaction.

**Solution:** Tap marker → Show popover with note preview + "Jump to time" button.

**File:** `EpisodePlayerView.swift` — in the `timeProgressWithMarkers` section.

#### Step 1: Add State for Popover

At the top of `EpisodePlayerView`:

```swift
@State private var selectedMarkerNote: NoteEntity? = nil
@State private var showNotePreviewPopover = false
```

#### Step 2: Update Marker to be Tappable

Replace the marker circle code with a tappable button:

```swift
ForEach(notes.filter { $0.timestamp != nil }) { note in
    if let timestamp = note.timestamp,
       let timeInSeconds = parseTimestamp(timestamp),
       player.duration > 0 {
        
        Button {
            selectedMarkerNote = note
            showNotePreviewPopover = true
        } label: {
            ZStack {
                // White outline
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                
                // Darker mint fill
                Circle()
                    .fill(Color.mintAccent.opacity(0.6))
                    .padding(2)
            }
            .frame(width: 14, height: 14)
        }
        .buttonStyle(.plain)
        .position(
            x: markerPosition(timeInSeconds, width: geometry.size.width),
            y: geometry.size.height / 2
        )
    }
}
```

#### Step 3: Add Popover Sheet Presentation

Add this modifier to the parent view that contains `timeProgressWithMarkers` (likely the `playerControlsSection` or the outermost VStack in player controls):

```swift
.sheet(item: $selectedMarkerNote) { note in
    NotePreviewPopover(
        note: note,
        notesAtSameTimestamp: notesAtTimestamp(note.timestamp ?? ""),
        onJumpToTime: {
            if let timestamp = note.timestamp,
               let timeInSeconds = parseTimestamp(timestamp) {
                player.seek(to: timeInSeconds)
                selectedMarkerNote = nil
            }
        },
        onDismiss: {
            selectedMarkerNote = nil
        }
    )
    .presentationDetents([.height(200)])  // Compact sheet
    .presentationDragIndicator(.visible)
}
```

#### Step 4: Create Note Preview Popover Component

Add this as a new supporting view in the same file:

```swift
// MARK: - Note Preview Popover

struct NotePreviewPopover: View {
    let note: NoteEntity
    let notesAtSameTimestamp: [NoteEntity]
    let onJumpToTime: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // If multiple notes at same timestamp
                    if notesAtSameTimestamp.count > 1 {
                        Text("\(notesAtSameTimestamp.count) notes at this time")
                            .font(.caption2Medium())
                            .foregroundColor(.echoTextSecondary)
                    }
                    
                    // Note preview(s)
                    ForEach(notesAtSameTimestamp) { noteItem in
                        VStack(alignment: .leading, spacing: 8) {
                            // Note text (max 3 lines)
                            Text(noteItem.noteText ?? "")
                                .font(.bodyEcho())
                                .foregroundColor(.echoTextPrimary)
                                .lineLimit(3)
                            
                            // Tags if present
                            if !noteItem.tagsArray.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(noteItem.tagsArray.prefix(3), id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2Medium())
                                            .foregroundColor(.echoTextSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        if noteItem != notesAtSameTimestamp.last {
                            Divider()
                        }
                    }
                }
                .padding(EchoSpacing.screenPadding)
            }
            .navigationTitle("Note at \(note.timestamp ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundColor(.mintAccent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Jump to Time") {
                        onJumpToTime()
                    }
                    .foregroundColor(.mintAccent)
                    .font(.bodyRoundedMedium())
                }
            }
        }
    }
}
```

#### Step 5: Add Helper Function for Multiple Notes at Same Timestamp

Add this function to `EpisodePlayerView`:

```swift
private func notesAtTimestamp(_ timestamp: String) -> [NoteEntity] {
    notes.filter { $0.timestamp == timestamp }
}
```

**Best practices for long notes:**
- Use `.lineLimit(3)` to prevent preview from getting too tall
- ScrollView allows user to read full content if needed
- "Jump to Time" button is always visible in toolbar

**Best practices for multiple notes:**
- Show count at top: "3 notes at this time"
- List all notes with dividers
- Each note preview limited to 3 lines + first 3 tags

---

## PART C: "Go Back" Button for Scrub Forgiveness

### Context

Add a temporary "Go back" button that appears for 8 seconds after the user scrubs the timeline, providing an undo mechanism for accidental seeks.

### Implementation

**File:** `EpisodePlayerView.swift` — in the player controls section.

#### Step 1: Add State for Go Back Button

```swift
@State private var showGoBackButton = false
@State private var previousPlaybackPosition: TimeInterval = 0
@State private var goBackTimer: Timer? = nil
```

#### Step 2: Track Scrub Events

Find where the slider/progress bar handles user interaction (likely in `timeProgressWithMarkers` or wherever the Slider is defined).

**Add `.onEditingChanged` to the Slider:**

```swift
Slider(
    value: $player.currentTime,
    in: 0...player.duration,
    onEditingChanged: { editing in
        if editing {
            // User started dragging — save current position
            previousPlaybackPosition = player.currentTime
        } else {
            // User finished dragging — show go back button
            showGoBackButton = true
            
            // Cancel existing timer
            goBackTimer?.invalidate()
            
            // Set 8-second timer
            goBackTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { _ in
                withAnimation {
                    showGoBackButton = false
                }
            }
        }
    }
)
```

#### Step 3: Add Go Back Button UI

Add this button **inside** the player controls section, positioned above the progress bar:

```swift
// Inside playerControlsSection, above timeProgressWithMarkers:

if showGoBackButton {
    Button {
        // Jump back to previous position
        player.seek(to: previousPlaybackPosition)
        
        // Hide button immediately
        withAnimation {
            showGoBackButton = false
        }
        goBackTimer?.invalidate()
        
    } label: {
        HStack(spacing: 6) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 14, weight: .medium))
            Text("Go back")
                .font(.caption2Medium())
        }
        .foregroundColor(.mintAccent)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    .transition(.opacity.combined(with: .move(edge: .top)))
    .padding(.bottom, 8)
}
```

**Positioning:** Place this button right above the progress bar so it's contextually close to the scrub action.

**Animation:** Use `.transition()` for smooth fade-in/fade-out and subtle slide-down.

#### Step 4: Cleanup on View Disappear

Add `.onDisappear` modifier to the main view to cancel the timer:

```swift
// In EpisodePlayerView body, at the end of the main VStack:

.onDisappear {
    goBackTimer?.invalidate()
}
```

---

## Implementation Order

Execute in this sequence to minimize complexity:

1. **Part A** — Notes tab Figma redesign (visual-only, no new interactions)
2. **Part B1** — Note marker visual update (stroke + fill)
3. **Part C** — Go back button (independent feature, easier to test)
4. **Part B2** — Note marker popover (most complex, do last)

Build and verify after each part before moving to the next.

---

## Verification Checklist

### Part A: Listening Tab with Embedded Notes
- [ ] Listening tab shows scrollable notes list (not album artwork)
- [ ] Note rows use Footnote/Regular (13pt) for BOTH timestamp and note text
- [ ] Timestamp column is fixed width (~60pt), left-aligned
- [ ] Note text is flexible width, left-aligned, 2 lines max
- [ ] Both timestamp and note text are white (echoTextPrimary), not mint
- [ ] Rows have 12pt vertical padding
- [ ] Thin white dividers (10% opacity) between rows
- [ ] No card backgrounds (simple list with dividers)
- [ ] Episode metadata (title + podcast name) appears above progress bar in sticky controls
- [ ] Player controls remain sticky at bottom
- [ ] Notes segment is removed from segmented control (or grayed out/disabled)
- [ ] Episode Info segment is renumbered to tag(1)
- [ ] Empty state shows when no notes exist
- [ ] Tap row → seeks to timestamp (no sheet opening, just direct seek)
- [ ] Swipe-to-delete still works
- [ ] Content scrolls smoothly above sticky controls

### Part B1: Note Marker Visual
- [ ] Markers are 14x14pt (slightly larger for outline)
- [ ] White stroke is 2pt width
- [ ] Inner fill is mint accent at 60% opacity (darker)
- [ ] Markers pop against dark background (#262626)
- [ ] Passes WCAG AA contrast check (use online contrast checker)

### Part B2: Note Marker Popover
- [ ] Tapping marker opens compact sheet (.height(200))
- [ ] Sheet shows note preview (3 lines max)
- [ ] Sheet shows first 3 tags if present
- [ ] If multiple notes at timestamp, shows count + all previews
- [ ] "Jump to Time" button in toolbar seeks to timestamp
- [ ] "Close" button dismisses sheet
- [ ] Popover doesn't interfere with scrubber dragging

### Part C: Go Back Button
- [ ] Button appears after user scrubs timeline
- [ ] Button shows for 8 seconds then fades out
- [ ] Tapping button jumps back to pre-scrub position
- [ ] Button positioned above progress bar (contextually close)
- [ ] Smooth fade-in/fade-out transition
- [ ] Timer is cancelled on view disappear
- [ ] Multiple scrubs reset the timer (button stays visible for 8s from last scrub)

---

## Files Modified

- `EpisodePlayerView.swift` — Main changes to Notes tab layout, note markers, and player controls
- No new files created

---

## Accessibility Notes

**Color Contrast:**
- White stroke (2pt) on mint fill (60% opacity) against `Color.echoBackground` (#262626) should achieve minimum 3:1 contrast for UI components per WCAG AA.
- Verify using: https://webaim.org/resources/contrastchecker/
  - Background: #262626
  - Foreground (stroke): #FFFFFF
  - Foreground (fill): #00c8b3 at 60% = approximately #4DD4C5

**Touch Targets:**
- Note markers remain small visually (14x14pt) but tap reveals popover — no accuracy required for direct seek
- Go back button: 12pt horizontal + 6pt vertical padding = minimum 44pt tap target when accounting for text
- Note rows: Full-width tappable area with 12pt vertical padding

---

## Out of Scope

Do NOT modify in this branch:
- Episode Info tab (but it will be renumbered from tag 2 to tag 1)
- Any other views outside `EpisodePlayerView.swift`
- Album artwork display (may be used in Episode Info tab or elsewhere, but not in Listening tab anymore)
- Mini player (though episode metadata layout changes in main player may inspire future mini player updates)

**Architectural note:** This redesign fundamentally changes the Listening tab from "artwork + controls" to "notes list + controls". The Notes tab is removed/disabled entirely. This is a significant UX shift that consolidates note-taking directly into the playback experience.
