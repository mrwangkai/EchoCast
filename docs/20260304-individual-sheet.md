# Individual Player Sheet Specifications

**Document Date:** March 4, 2026
**Component:** `EpisodePlayerView.swift`
**Task Reference:** T27 (Individual player sheet styling — bottom section spacing)

---

## Overview

The individual player sheet is the full-screen episode player accessed from:
- Mini player tap expansion
- Podcast episode cards
- Direct navigation

**File Location:** `EchoNotes/Views/Player/EpisodePlayerView.swift`

---

## Layout Structure

```
┌─────────────────────────────────────────────────────────────┐
│  SECTION 1: HEADER (~68px)                                  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Segmented Control (36pt height)                      │  │
│  │ [Listening | Notes | Episode Info]                   │  │
│  └───────────────────────────────────────────────────────┘  │
│  Padding top: 20pt                                            │
├─────────────────────────────────────────────────────────────┤
│  SECTION 2: MID-SECTION (~377px)                            │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Notes/Bookmarks/Episode Info content                   │  │
│  │ (Scrollable, varies by selection)                     │  │
│  └───────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  SECTION 3: FOOTER (~290pt) ← T27 TARGET                    │
│  See detailed specs below                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## SECTION 3: FOOTER — Detailed Specifications

**VStack spacing:** `16pt` (between elements)

### ASCII Mock with Exact Spacing

```
┌─────────────────────────────────────────────────────────────┐
│                                                              │  ← Top of Section 3
│  16pt horizontal pad              16pt horizontal pad         │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐│
│  │ episodeMetadataView                                    ││
│  │ "Episode Title - Two lines max if needed"             ││
│  │ "Show Name"                                            ││
│  └────────────────────────────────────────────────────────┘│
│                         ↑ 16pt spacing                       │
│  ┌────────────────────────────────────────────────────────┐│
│  │ timeProgressWithMarkers (Scrubber)                    ││
│  │ ▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  ││
│  │                          ●                             ││
│  │ ─────────────────────────────────────────────────────││
│  │ 15:00 / 45:00                                         ││
│  └────────────────────────────────────────────────────────┘│
│                         ↑ 16pt spacing                       │
│  ┌────────────────────────────────────────────────────────┐│
│  │ playbackControlButtons                                 ││
│  │  [◀ 15:00 ▶]  1.0x  [list] [∷]  [bookmark ▶]       ││
│  └────────────────────────────────────────────────────────┘│
│                         ↑ 16pt spacing                       │
│  ┌────────────────────────────────────────────────────────┐│
│  │ addNoteButton                                          ││
│  │ 16pt horizontal pad              16pt horizontal pad   ││
│  │ ◖──────────────────────────────────────────────────────││
│  │ │ [📝]  Add note at current time       [🔖]          ││
│  │ └──────────────────────────────────────────────────────││
│  └────────────────────────────────────────────────────────┘│
│                                                              │
│  48pt bottom padding ← Safe area for home indicator          │
└─────────────────────────────────────────────────────────────┘
```

### Exact Spacing Values

| Element | Value | Location |
|---------|-------|----------|
| **Element spacing** | `16pt` | VStack spacing between all footer elements |
| **Top padding** | `12pt` | Section 3 top padding |
| **Bottom padding** | `48pt` | Section 3 bottom padding (safe area) |
| **Horizontal padding** | `16pt` | `EchoSpacing.screenPadding` |
| **Add Note button horizontal pad** | `16pt` | Applied via `.padding(.horizontal, 16)` |

### Component Heights

| Component | Height | Notes |
|-----------|--------|-------|
| **Episode metadata** | Variable | 2 lines max, auto height |
| **Scrubber with time** | ~40pt | Track (6pt) + markers + time label |
| **Playback controls** | ~48pt | Buttons + skip buttons |
| **Add Note button row** | ~48pt | Fixed button height |

---

## Color Specifications (Dark Mode)

| Element | Color | RGB/Reference |
|---------|-------|---------------|
| **Background** | `Color.echoBackground` | #262626 |
| **Sheet background (Add Note)** | `Color(red: 0.149, green: 0.149, blue: 0.149)` | Dark gray |
| **Input field background** | `Color(red: 0.2, green: 0.2, blue: 0.2)` | Slightly lighter gray |
| **Primary text** | `.foregroundStyle(.primary)` | White |
| **Secondary text** | `.foregroundStyle(.secondary)` | White 85% |
| **Tertiary text** | `.foregroundStyle(.tertiary)` | White 65% |
| **Mint accent** | `Color.mintAccent` | Brand color |

---

## Typography Specifications

| Element | Size | Weight | Style |
|---------|------|--------|-------|
| **Segmented control** | 13pt | medium | `system(size: 13, weight: .medium)` |
| **Episode title** | Variable | - | Auto from metadata |
| **Show name** | Variable | - | Auto from metadata |
| **Time label** | 15pt | regular | Auto from player |
| **Button text** | 15pt | medium | `bodyRoundedMedium()` or `.system(size: 15, weight: .medium)` |

---

## Related Tasks

- **T27** (P1): Individual player sheet styling — give bottom section more spacing/breathing room
- **T26** (P2): Refine NoteCaptureSheetWrapper styling — fix light mode rendering
- **T29** (P1): Timeline marker shapes (notes vs bookmarks)
- **T30** (P2): Bookmark toast position

---

## Code Reference

**Footer implementation:** `EpisodePlayerView.swift` lines 222-241

```swift
// --- SECTION 3: FOOTER (FIXED HEIGHT: ~290px) ---
VStack(spacing: 16) {
    // Metadata (Always visible, 2 lines max)
    episodeMetadataView

    // Scrubber
    timeProgressWithMarkers

    // Playback controls
    playbackControlButtons

    // Add Note CTA (Always visible with player controls)
    addNoteButton
        .padding(.horizontal, 16)
        .sensoryFeedback(.impact, trigger: activeSheet == .noteCapture)
}
.padding(.horizontal, EchoSpacing.screenPadding)  // 16pt
.padding(.top, 12)
.background(Color.echoBackground)
.padding(.bottom, 48)
```

---

## Design Token References

- `EchoSpacing.screenPadding` = `16pt` (defined in `EchoCastDesignTokens.swift`)
- `Color.echoBackground` = Dark background color
- `Color.mintAccent` = Brand mint/green accent color

---

*Last Updated: March 4, 2026*
