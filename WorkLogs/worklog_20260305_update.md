# Work Log - March 5, 2026 (Update) — T27, T29, T35

## Summary
**Session Focus**: Player visual spacing and marker differentiation, plus episode player notes list redesign

**Completed Tasks**:
- **T27** ✅: Individual player sheet spacing adjustments (album art 240pt, marker gap 6pt, scrubber→controls 24pt, footer bottom 24pt)
- **T29** ✅: Timeline marker shapes — notes as filled circles (●), bookmarks as diamonds (◆)
- **T35** ✅: Created NoteRowView for episode player, reverted NoteCardView to original card style

**Branch**: `update-note-in-player`
**Total commits for T35**: 8 commits (including spacing iterations and revert)
**Total commits for T27**: 2 commits (initial spacing + refinements)
**Total commits for T29**: 2 commits (shape change + position fix)

**⚠️ IMPORTANT NOTE**: T35 was consistently confused with T37 during this session. T35 is now CLOSED, T37 remains OPEN (home screen refactor).

---

## T27: Individual Player Sheet Spacing ✅

### Objective
Increase breathing room in the player's footer section by adjusting spacing values.

### Approach
Surgical spacing updates to `EpisodePlayerView.swift` based on intake specifications.

### Changes Made

#### Change 1 — Album Artwork Size
**File**: `EpisodePlayerView.swift`, `ListeningSegmentView` (~line 919)
- Reduced frame from `280×280pt` to `240×240pt`
- Provides more vertical space for other elements

**Commit**: `47ead42`

#### Change 2 — Note/Bookmark Marker Bottom Padding
**File**: `EpisodePlayerView.swift`, `timeProgressWithMarkers` (~lines 626, 652)
- Added `.padding(.bottom, 8)` to both note and bookmark markers
- Creates 6pt gap between marker bottoms and scrubber track
- Position adjusted from `y: -8` to `y: -11` to account for new padding

**Commit**: `47ead42`

#### Change 3 — Scrubber to Playback Controls Spacing
**File**: `EpisodePlayerView.swift`, footer VStack (~line 223)
- Changed VStack spacing from `16pt` to `24pt`
- Increases visual separation between timeline scrubber and playback controls

**Commit**: `47ead42`

#### Change 4 — Footer Bottom Padding
**File**: `EpisodePlayerView.swift`, footer VStack (~line 242)
- Changed `.padding(.bottom, 48)` to `.padding(.bottom, 32)`
- Reduces footer height by 16pt

**Commit**: `47ead42`

---

### Refined Spacing (Follow-up)
After initial implementation, further refined based on visual feedback:

| Adjustment | Before | After | Commit |
|------------|--------|-------|--------|
| Marker → timeline gap | 3pt | 6pt | `431c845` |
| Footer bottom padding | 32pt | 24pt | `431c845` |

**Final spacing values:**
- Album artwork: 240×240pt
- Marker gap to scrubber: 6pt
- Scrubber → controls: 24pt
- Footer bottom padding: 24pt

---

## T29: Timeline Marker Shapes ✅

### Objective
Differentiate note markers from bookmark markers using distinct shapes — notes as filled circles (●), bookmarks as diamonds (◆).

### Approach
**Branch**: `t29-marker-shapes`
**Target**: `EpisodePlayerView.swift`, `timeProgressWithMarkers` computed property

### Changes Made

#### Change 1 — Bookmark Marker Visual Shape
**Location**: EpisodePlayerView.swift, bookmark marker ForEach (~lines 642-645)

**Before:**
```swift
ZStack {
    Circle()
        .fill(Color.mintAccent)
        .frame(width: 28, height: 28)
    Image(systemName: "bookmark.fill")
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(Color(red: 26/255, green: 60/255, blue: 52/255))
}
```

**After:**
```swift
RoundedRectangle(cornerRadius: 2)
    .fill(Color.mintAccent)
    .frame(width: 20, height: 20)
    .rotationEffect(.degrees(45))
```

- Changed from Circle to rotated RoundedRectangle (diamond shape)
- Reduced visual size from 28pt to 20pt
- Removed inner bookmark icon for cleaner look
- Button maintains 28pt tap area

**Commit**: `bda6074`

#### Change 2 — Fix Bookmark X-Position Offset Bug
**Location**: EpisodePlayerView.swift, bookmark xPos calculation (~line 633)

**Problem**: Bookmark xPos was missing the `-14` centering offset that note markers use, causing 14pt rightward offset.

**Fix:**
```swift
let xPos = player.duration > 0
    ? (bookmark.timestamp / player.duration) * geo.size.width - 14
    : 0
```

**Commit**: `9dff2a7`

#### Change 3 — Fix Bookmark Marker Position Overcorrection
**Location**: EpisodePlayerView.swift, bookmark .position (~line 649)

**Problem**: After adding `-14` offset, the `.position(x: xPos)` was still missing the `+14` to center the marker.

**Fix:**
```swift
.position(x: xPos + 14, y: -11)
```

This matches the note marker pattern exactly: `xPos - 14` (offset calculation), then `+ 14` (position centering).

**Commit**: `9dff2a7`

---

## T35: NoteRowView Creation & NoteCardView Revert ✅

### Objective
Create a reusable `NoteRowView` component for the episode player's Notes tab, while keeping `NoteCardView` as the original card style for Home/Library screens.

### Approach
**Branch**: `update-note-in-player`

---

### Part 1: NoteCardView Redesign (Initially Applied, Then Reverted)

#### Original Redesign Commit: `ceeb944`
Created two-column layout with:
- LEFT: Timestamp (54pt width, .footnote.semibold, .mintAccent)
- RIGHT: Note text (.footnote) + More/Less toggle (243pt width)
- @State isExpanded for expand/collapse
- Tags moved between HStack and SEPARATOR

This redesign was applied to `NoteCardView` but later reverted per user feedback.

---

### Part 2: NoteRowView Creation (Kept)

#### Commit: `18011fb`
**File**: `ContentView.swift`, added above `NoteCardView` (~lines 3069-3148)

**New Component Structure:**
```swift
struct NoteRowView: View {
    let note: NoteEntity
    var onTap: (() -> Void)? = nil
    @State private var isExpanded: Bool = false

    private var hasMoreContent: Bool {
        (note.noteText?.count ?? 0) > 120
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 32) {
                // Timestamp (54pt)
                // Note text + More/Less
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }

            // Tags (if any)
            // Divider
        }
    }
}
```

**Key Features:**
- Two-column layout matching NoteCardView's redesigned style
- Expandable content (4-line limit collapsed, unlimited when expanded)
- More/Less button shows when text > 120 characters
- Optional onTap closure for tap handling
- Dividers between rows

---

### Part 3: Episode Player Notes Tab Integration

#### Commit: `18011fb`
**File**: `EpisodePlayerView.swift`, `NotesSegmentView` (~lines 972-996)

Changed `notesListView` to use `NoteRowView`:
```swift
private var notesListView: some View {
    VStack(spacing: 0) {  // Changed from 12
        ForEach(notes, id: \.id) { note in
            NoteRowView(note: note) {  // Changed from NoteRow
                onNoteTap(note)
            }
            // swipeActions + contextMenu preserved
        }
    }
    .padding(.horizontal, EchoSpacing.screenPadding)
}
```

**Changes:**
- Replaced `NoteRow` with `NoteRowView`
- VStack spacing: `12 → 0` (dividers handle separation)
- Preserved swipe actions and context menu

---

### Part 4: Spacing Iterations (Multiple Commits)

#### Iteration 1 — Horizontal Padding Fix
**Commit**: `a1540de`
- Added `.padding(.horizontal, EchoSpacing.screenPadding)` to notesListView
- Fixed flush-against-edge timestamp issue

#### Iteration 2 — Increase Horizontal Padding
**Commit**: `a76cb48`
- Horizontal padding: `16pt → 24pt` (+8pt each side)

#### Iteration 3 — Further Adjustments
**Commit**: `9b68290`
- Horizontal padding: `24pt → 32pt`
- Bottom spacer: `16pt → 0pt`

#### Iteration 4 — Bottom Spacing
**Commit**: `a03ba3d`
- Bottom spacer in NotesSegmentView: `0 → 24pt`
- Creates gap between notes and footer

#### Iteration 5 — Footer Top Padding
**Commit**: `ddf1c47`
- Footer top padding: `12pt → 24pt`
- Creates additional space above episode metadata

**Final spacing values:**
- Notes horizontal padding: 32pt
- Notes bottom spacer: 24pt
- Footer top padding: 24pt
- **Total spacing from notes to episode metadata: 24pt + 24pt = 48pt**

---

### Part 5: NoteCardView Revert

#### Commit: `706d5cf`
**File**: `ContentView.swift`, `NoteCardView` (~lines 3152-3290)

Reverted NoteCardView to original card-style design:
- Removed `@State private var isExpanded`
- Restored original TOP section:
  - Note text: 17pt serif, lineLimit 4
  - Timestamp: Mint badge with clock icon
  - Tags: Right side, 225px max width
- Kept SEPARATOR and BOTTOM podcast metadata unchanged
- `NoteRowView` remains for episode player Notes tab

---

### Files Modified
- `EchoNotes/Views/Player/EpisodePlayerView.swift`
- `EchoNotes/ContentView.swift`

---

### Commits (T35 Sequence)

| Commit | Description |
|--------|-------------|
| `ceeb944` | t35: redesign NoteCardView to two-column timestamp/note layout with expand toggle |
| `18011fb` | t35: add NoteRowView for episode player notes tab |
| `a1540de` | t35: fix horizontal padding on player notes list |
| `a76cb48` | t35: adjust notes list padding — horizontal 24pt, bottom spacer 16pt |
| `9b68290` | t35: further adjust notes list padding — horizontal 32pt, bottom spacer 0 |
| `a03ba3d` | t35: increase bottom spacing in notes tab above footer |
| `ddf1c47` | t35: increase footer top padding to 24pt for more spacing from notes |
| `706d5cf` | t35: revert NoteCardView to original card style (row style is player-only) |

Supporting commits:
- `3f574fc` | docs: fix T35 attribution and add priorities to T33-T34, T36-T37
- `7e5fa48` | docs: mark T35 complete with commit ddf1c47

---

### Issues Encountered & Resolved

#### Issue 1: Over-Iterative Spacing Adjustments
**Cause**: Required multiple rounds of spacing tweaks based on visual feedback to get the right balance.

**Resolution**: Made incremental commits for each spacing change, allowing for easy rollback if needed.

#### Issue 2: NoteCardView Revert
**Cause**: User decided the two-column row style should be player-only, not for Home/Library cards.

**Resolution**: Created separate `NoteRowView` component for episode player, reverted `NoteCardView` to original card design.

---

### Key Design Decisions

1. **Separation of Concerns**:
   - `NoteCardView`: Full card with artwork, metadata, used in Home/Library
   - `NoteRowView`: Compact row with timestamp + note text, used in episode player

2. **Reusable Pattern**:
   - NoteRowView establishes a pattern that could be used in other list contexts

3. **Spacing Philosophy**:
   - Generous horizontal padding (32pt) for comfortable reading
   - Strategic vertical spacing (48pt total) to separate notes from episode metadata

---

## Branch Status
- **Current branch**: `update-note-in-player`
- **Status**: Ready for merge after final visual fix
- **Main branch**: At `7e5fa48` (ahead of origin)

---

## Related Tasks

### T37: Refactor Home Screen Top Section (OPEN - NOT TO BE CONFUSED WITH T35)
**Priority**: P1
**Description**: Refactor the top section of home screen to have the search and settings button be similar to library tab.
**Status**: Not started. This was confused with T35 during intake, but is a separate task. T35 (NoteRowView creation) is complete.

### T40: Update Button Styling (NEXT)
**Priority**: P1
**Description**: Update button style for "add note at current time" and "bookmark" — currently two primary buttons, would two-line button be too small to read?
**Status**: Ready to start

---

## Current Status (Pre-Merge)
**Date**: March 5, 2026
**Main repo branch**: `t27-player-spacing-adjustments`
**EchoNotes submodule branch**: `update-note-in-player`
**Status**: Awaiting one final visual fix before merge
**Uncommitted changes**: echocast_todo.md, UserInterfaceState.xcuserstate

## Next Steps
1. User will make one final visual fix before merging `update-note-in-player` branch
2. Merge branch to `main`
3. Begin T40: Update button styling for add note/bookmark buttons

---

## Task Status Clarification (T35 vs T37)

**IMPORTANT**: T35 and T37 were consistently confused during this work session.

| Task | ID | Status | Description |
|------|-----|--------|-------------|
| Update individual notes row on episode sheet | **T35** | ✅ CLOSED (commit ddf1c47) | Created NoteRowView component, reverted NoteCardView to original |
| Refactor home screen top section | **T37** | 🔶 OPEN | Search/settings button refactor (not yet started) |

**Root cause of confusion**: The intake_placeholder.md initially referenced T37, but the actual NoteCardView redesign work was for T35. This was corrected mid-stream, and commits reflect T35. Both the TODO.md and this worklog now correctly reflect T35 as closed and T37 as open.
