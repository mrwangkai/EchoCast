# Individual Player Sheet Specifications

**Document Date:** March 4, 2026
**Component:** `EpisodePlayerView.swift`
**Task Reference:** T27 (Individual player sheet styling — bottom section spacing)
**Commit:** `f333460` (spacing update: playback controls → Add Note button = 24pt)

---

## Complete Layout Structure

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  INDIVIDUAL PLAYER SHEET (Full Screen)                                            │
│  Width: Full screen width                                                            │
│  Height: Device height                                                              │
└────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────────────┐
│  SECTION 1: HEADER                                                                    │
│  Height: 56pt (20pt top + 36pt control)                                             │
│  ┌────────────────────────────────────────────────────────────────────────────┐│
│  │  ← ← ← ← ← ← ← ← ← [Listening] [Notes] [Episode Info] → → → → → → → → → ││
│  │  Padding: 3pt (control) + 24pt (sides)                                          ││
│  │  ┌───────────────────────────────────────────────────────────────────────┐││
│  │  │ Segmented Control Container                                               │││
│  │  │ Height: 32pt per button, Corner radius: 8pt                            │││
│  │  │ Spacing: 2pt between buttons                                           │││
│  │  └───────────────────────────────────────────────────────────────────────┘││
│  │  Background: Color.white.opacity(0.06), Corner radius: 10pt               ││
│  └────────────────────────────────────────────────────────────────────────────┘│
│  Padding top: 20pt                                                                     │
└────────────────────────────────────────────────────────────────────────────────┘
                                ↓ 0pt (sections are adjacent)
┌────────────────────────────────────────────────────────────────────────────────┐
│  SECTION 2: MID-SECTION                                                              │
│  Height: ~377pt (varies by content)                                                    │
│  ┌────────────────────────────────────────────────────────────────────────────┐│
│  │                                                                                  ││
│  │  ┌──────────────────────┐                                                     ││
│  │  │                      │  280×280pt artwork                                   ││
│  │  │   Album Artwork       │  Corner radius: 12pt                              ││
│  │  │                      │  Shadow: 8pt + 4pt                                ││
│  │  │                      │                                                     ││
│  │  └──────────────────────┘                                                     ││
│  │                                                                                  ││
│  │  Padding sides: 16pt (EchoSpacing.screenPadding)                                  ││
│  └────────────────────────────────────────────────────────────────────────────┘│
│  Padding bottom: 0pt                                                                  │
└────────────────────────────────────────────────────────────────────────────────┘
                                ↓ 12pt
┌────────────────────────────────────────────────────────────────────────────────┐
│  SECTION 3: FOOTER ← T27 TARGET                                                      │
│  Height: ~290pt                                                                      │
│  ┌────────────────────────────────────────────────────────────────────────────┐│
│  │                                                                                  ││
│  │  ┌──────────────────────────────────────────────────────────────────────┐││
│  │  │ EPISODE METADATA                                                            │││
│  │  │ ┌────────────────────────────────────────────────────────────────┐   │││
│  │  │ │ "Episode Title - Two lines max if needed"                         │   │││
│  │  │ │   Font: bodyRoundedMedium()                                      │   │││
│  │  │ │   Color: echoTextPrimary                                          │   │││
│  │  │ │   Line limit: 2                                                     │   │││
│  │  │ │                                                                        │   │││
│  │  │ │ "Show Name"                                                           │   │││
│  │  │ │   Font: system(15, medium)                                        │   │││
│  │  │ │   Color: echoTextSecondary                                        │   │││
│  │  │ │   Line limit: 1                                                     │   │││
│  │  │ └────────────────────────────────────────────────────────────────┘   │││
│  │  │                                                                        │   │││
│  │  │  VStack spacing: 10pt (between episode and show name)                  │   │││
│  │  │  Bottom padding: 32pt                                                 │   │││
│  │  └──────────────────────────────────────────────────────────────────────┘││
│  │                                                                                  ││
│  │  ↑ 16pt spacing                                                                   ││
│  │                                                                                  ││
│  │  ┌──────────────────────────────────────────────────────────────────────┐││
│  │  │ SCRUBBER WITH TIME                                                       │││
│  │  │ ┌─────────────────────────────────────────────────────────────────┐   │││
│  │  │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│   │││
│  │  │ │ Inactive: Color.white.opacity(0.2), Height: 6pt                  │   │││
│  │  │ │ Active: Color.mintAccent, Height: 6pt                            │   │││
│  │  │ └─────────────────────────────────────────────────────────────────┘   │││
│  │  │                                                                        │   │││
│  │  │  ┌─────────────────────────────────────────────────────────────────┐   │││
│  │  │ │ ● ● ● ● Note/bookmark markers (28pt circles)                       │   │││
│  │  │ │   Positioned above track, show preview on tap                      │   │││
│  │  │ └─────────────────────────────────────────────────────────────────┘   │││
│  │  │                                                                        │   │││
│  │  │  ┌─────────────────────────────────────────────────────────────────┐   │││
│  │  │ │         ● ← Scrubber knob (20×20pt white circle)                   │   │││
│  │  │ │           Offset: -10pt from center                                 │   │││
│  │  │ └─────────────────────────────────────────────────────────────────┘   │││
│  │  │                                                                        │   │││
│  │  │  ─────────────────────────────────────────────────────────────────   │││
│  │  │  15:00 / 45:00                                                          │   │││
│  │  │   Font: system(15)                                                      │   │││
│  │  │   Color: echoTextPrimary                                               │   │││
│  │  └──────────────────────────────────────────────────────────────────────┘││
│  │                                                                                  ││
│  │  ↑ 16pt spacing                                                                   ││
│  │                                                                                  ││
│  │  ┌──────────────────────────────────────────────────────────────────────┐││
│  │  │ PLAYBACK CONTROLS                                                          │││
│  │  │  ┌──────┐  ┌─────────────┐  ┌────┐  ┌──────┐  ┌─────────────┐    │││
│  │  │  │ ◀ 15 │  │      ▶       │  │1.0x│  │≡  ≡│  │      ◀       │    │││
│  │  │  └──────┘  └─────────────┘  └────┘  └──────┘  └─────────────┘    │││
│  │  │    48×48        48×48         48×48    48×48          48×48      │││
│  │  │                                                                         │││
│  │  │  Skip -15:     Play/Pause       Speed    Speed      Bookmark    │││
│  │  │                                                                         │││
│  │  │  Button spacing: 12pt between groups                                 │││
│  │  └──────────────────────────────────────────────────────────────────────┘││
│  │                                                                                  ││
│  │  ↓ 8pt padding (.padding(.bottom, 8))                                          ││
│  │                                                                                  ││
│  │  ↑ 24pt total spacing (16pt VStack + 8pt padding)                                ││
│  │                                                                                  ││
│  │  ┌──────────────────────────────────────────────────────────────────────┐││
│  │  │ ADD NOTE BUTTON ROW                                                       │││
│  │  │  ┌────────────────────────────────────────────────────────────────┐│││││││
│  │  │  │ ┌────┐  ┌─────────────────────────────────────────────┐        │││││││
│  │  │  │ │ 📝  │  │ Add note at current time                   │        │││││││
│  │  │  │ └────┘  └─────────────────────────────────────────────┘        │││││││
│  │  │  │ 80% width, 48pt height, mint background                    │││││││
│  │  │  └────────────────────────────────────────────────────────────────┘│││││││
│  │  │                                                           ┌──────┐        │││││││
│  │  │                                                           │ 🔖   │        │││││││
│  │  │                                                           │ 48×48│        │││││││
│  │  │                                                           │Bookmark     │││││││
│  │  │                                                           └──────┘        │││││││
│  │  │ 20% width, 48pt height, mint background                               │││││││
│  │  └──────────────────────────────────────────────────────────────────────┘││
│  │                                                                                  ││
│  │  Horizontal padding: 16pt                                                           ││
│  └────────────────────────────────────────────────────────────────────────────┘│
│                                                                                  │
│  Horizontal padding: 16pt (EchoSpacing.screenPadding)                             │
│  Top padding: 12pt                                                                  │
│  Background: Color.echoBackground                                                   │
│  Bottom padding: 48pt ← Safe area for home indicator                                 │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## SECTION 1: HEADER — Detailed Specs

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  HEIGHT: 56pt                                                                     │
│  ┌────────────────────────────────────────────────────────────────────────────┐│
│  │  Padding: 3pt                                                                 ││
│  │  ┌────────┐ 8pt ┌────────┐ 8pt ┌────────┐ 8pt ┌────────┐                 ││
│  │  │Listening│   │  Notes  │   │Episode │   │        │                 ││
│  │  │  32×?pt │   │  32×?pt │   │  Info   │   │        │                 ││
│  │  └────────┘   └────────┘   └────────┘   └────────┘                 ││
│  │  Height: 32pt per button                                                      ││
│  │  Corner radius: 8pt                                                            ││
│  │  Selected: Color.white.opacity(0.15)                                      ││
│  │  Unselected: Color.clear                                                        ││
│  │  Text: 13pt medium, White or White.opacity(0.4)                             ││
│  └────────────────────────────────────────────────────────────────────────────┘│
│  Corner radius: 10pt                                                               │
│  Background: Color.white.opacity(0.06)                                          │
│  Padding sides: 24pt                                                               │
└────────────────────────────────────────────────────────────────────────────────┘
     ↑
   20pt padding from top
```

| Element | Value | Location |
|---------|-------|----------|
| **Total height** | 56pt | 20pt top + 32pt control + 3pt control padding + ~1pt text |
| **Top padding** | 20pt | `.padding(.top, 20)` |
| **Button height** | 32pt | `.frame(height: 32)` |
| **Button corner radius** | 8pt | `.clipShape(RoundedRectangle(cornerRadius: 8))` |
| **Button spacing** | 2pt | `HStack(spacing: 2)` |
| **Control padding** | 3pt | `.padding(3)` |
| **Segmented control sides** | 24pt | `.padding(.horizontal, 24)` |
| **Segmented control radius** | 10pt | `.clipShape(RoundedRectangle(cornerRadius: 10))` |
| **Text size** | 13pt | `.font(.system(size: 13, weight: .medium))` |

---

## SECTION 2: MID-SECTION — Detailed Specs (Listening Segment)

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  HEIGHT: ~296pt (280pt artwork + 16pt padding)                                        │
│  ┌────────────────────────────────────────────────────────────────────────────┐│
│  │                                                                                  ││
│  │  ┌──────────────────────────────────────────────────────────────────┐    ││
│  │  │                                                                      │    ││
│  │  │  ┌────────────────────────────────────────────────────────┐      │    ││
│  │  │  │                                                          │      │    ││
│  │  │  │                                                          │      │    ││
│  │  │  │             ALBUM ARTWORK                                  │      │    ││
│  │  │  │             280×280pt                                  │      │    ││
│  │  │  │             Corner radius: 12pt                          │      │    ││
│  │  │  │                                                          │      │    ││
│  │  │  │                                                          │      │    ││
│  │  │  │                                                          │      │    ││
│  │  │  └────────────────────────────────────────────────────────┘      │    ││
│  │  │                                                                      │    ││
│  │  │  Shadow (outer): Color.black.opacity(0.3), radius: 8pt, x: 0, y: 4    │    ││
│  │  │  Shadow (inner): Color.black.opacity(0.15), radius: 4pt, x: 0, y: 2   │    ││
│  │  │                                                                      │    ││
│  │  └──────────────────────────────────────────────────────────────────┘    ││
│  │                                                                                  ││
│  │  Padding sides: 16pt (EchoSpacing.screenPadding)                                  ││
│  │                                                                                  ││
│  └────────────────────────────────────────────────────────────────────────────┘│
│                                                                                  │
│  Padding top: 8pt (only when in Listening segment)                                       │
│  Padding bottom: 0pt                                                                │
└────────────────────────────────────────────────────────────────────────────────┘
```

| Element | Value |
|---------|-------|
| **Artwork size** | 280×280pt |
| **Artwork corner radius** | 12pt |
| **Horizontal padding** | 16pt |
| **Top padding (Listening)** | 8pt |
| **Top padding (Notes/Info)** | 16pt |
| **Bottom padding** | 0pt |
| **Shadow outer** | Color.black.opacity(0.3), radius: 8pt, y: 4pt |
| **Shadow inner** | Color.black.opacity(0.15), radius: 4pt, y: 2pt |

---

## SECTION 3: FOOTER — Detailed Specs

### episodeMetadataView

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  ┌────────────────────────────────────────────────────────────────────────────┐│
│  │  VStack(spacing: 10)                                                          ││
│  │   ↑                                                                            ││
│  │  ┌──────────────────────────────────────────────────────────────────────┐││
│  │  │ "Episode Title - Two lines max if needed"                             │││
│  │  │   Font: bodyRoundedMedium()                                            │││
│  │  │   Color: echoTextPrimary                                               │││
│  │  │   Line limit: 2                                                       │││
│  │  └──────────────────────────────────────────────────────────────────────┘││
│  │   ↓ 10pt spacing                                                               ││
│  │  ┌──────────────────────────────────────────────────────────────────────┐││
│  │  │ "Show Name"                                                            │││
│  │  │   Font: system(size: 15, weight: .medium)                            │││
│  │  │   Color: echoTextSecondary                                             │││
│  │  │   Line limit: 1                                                       │││
│  │  └──────────────────────────────────────────────────────────────────────┘││
│  │   ↓                                                                            ││
│  │   ↓ 32pt bottom padding                                                      ││
│  └────────────────────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────────────────────┘
```

| Element | Value |
|---------|-------|
| **Episode title → Show name spacing** | 10pt |
| **Bottom padding** | 32pt |

### Scrubber (timeProgressWithMarkers)

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  VStack(spacing: 8)                                                              │
│  ┌────────────────────────────────────────────────────────────────────────────┐│
│  │  GeometryReader → Full width                                                   ││
│  │  ┌──────────────────────────────────────────────────────────────────────┐││
│  │  │ ┌─────────────────────────────────────────────────────────────────┐    │││
│  │  │ │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│    │││
│  │  │ │ Capsule (inactive)                                                       │    │││
│  │  │ │ Color: Color.white.opacity(0.2)                                    │    │││
│  │  │ │ Height: 6pt                                                          │    │││
│  │  │ └─────────────────────────────────────────────────────────────────┘    │││
│  │  │ ┌─────────────────────────────────────────────────────────────────┐    │││
│  │  │ │ ████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░│    │││
│  │  │ │ Capsule (active)                                                         │    │││
│  │  │ │ Color: Color.mintAccent                                                │    │││
│  │  │ │ Height: 6pt                                                          │    │││
│  │  │ └─────────────────────────────────────────────────────────────────┘    │││
│  │  │ ● ← Scrubber knob (Circle 20×20pt)                                    │    │││
│  │  │    Color: Color.white                                                   │    │││
│  │  │    Offset: -10pt from center to align properly                         │    │││
│  │  └──────────────────────────────────────────────────────────────────────┘││
│  │   ↓ 8pt spacing                                                                ││
│  │  "15:00 / 45:00"                                                              ││
│  │   Font: system(size: 15)                                                     ││
│  │   Color: echoTextPrimary                                                    ││
│  └────────────────────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────────────────────┘
```

| Element | Value |
|---------|-------|
| **Track height** | 6pt |
| **Scrubber knob** | 20×20pt Circle |
| **Knob offset** | -10pt (to center properly) |
| **Note/bookmark markers** | 28×28pt Circles |
| **VStack spacing** | 8pt (between scrubber and time label) |

### Playback Controls

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  ┌──────┐ 12pt  ┌─────────────┐ 12pt  ┌────┐ 12pt  ┌──────┐ 12pt  ┌─────────────┐    │
│  │ ◀ 15 │       │      ▶       │       │1.0x│       │≡  ≡│       │      ◀       │    │
│  │ 48×48 │       │     48×48     │       │48×48│       │48×48│       │     48×48     │    │
│  │       │       │               │       │     │       │     │       │               │    │
│  │Skip   │       │   Play/Pause   │       │Speed│       │Speed│       │  Bookmark     │    │
│  │-15s   │       │               │       │     │       │     │       │               │    │
│  └──────┘       └─────────────┘       └────┘       └──────┘       └─────────────┘    │
│                                                                                  │
│  ↓ 8pt padding (.padding(.bottom, 8))                                               │
│  ↓ 24pt total to Add Note button                                                        │
└────────────────────────────────────────────────────────────────────────────────┘
```

| Element | Size | Spacing |
|---------|------|---------|
| **All buttons** | 48×48pt | 12pt between groups |
| **← Skip button** | 48×48pt | - |
| **Play/Pause** | 48×48pt | - |
| **Speed buttons** | 48×48pt | - |
| **Bookmark button** | 48×48pt | - |
| **Bottom padding** | 8pt | → Add Note button |

### Add Note Button Row

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  Horizontal padding: 16pt                                                           │
│  ┌────────────────────────────────────────────────────────────────────────┐│
│  │  ←─────────────────────────────────────────────────────────────────→  ││
│  │  HStack(spacing: 8)                                                         ││
│  │   80% width                                                                    ││
│  │  ┌───────────────────────────────────────────────────────────────┐     ││
│  │  │ ┌────┐  ┌─────────────────────────────────────────────────────┐│     ││
│  │  │ │ 📝  │  │ Add note at current time                               ││     ││
│  │  │ └────┘  └─────────────────────────────────────────────────────┘│     ││
│  │  │   15pt icon, 8pt spacing                                            ││     ││
│  │  │   Full width, 48pt height                                          ││     ││
│  │  │   Font: bodyRoundedMedium()                                          ││     ││
│  │  │   Foreground: mintButtonText                                         ││     ││
│  │  │   Background: mintButtonBackground                                 ││     ││
│  │  │   Corner radius: 12pt                                               ││     ││
│  │  └───────────────────────────────────────────────────────────────┘     ││
│  │                                                                         8pt  ││
│  │  ┌──────┐                                                                ││
│  │  │ 🔖   │ 20% width                                                      ││
│  │  │ 48×48 │                                                                ││
│  │  │       │                                                                ││
│  │  │       │                                                                ││
│  │  └──────┘                                                                ││
│  └────────────────────────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────────────────────────────┘
```

| Element | Value |
|---------|-------|
| **Total spacing (controls → Add Note)** | **24pt** (16pt VStack + 8pt padding) |
| **Add Note button width** | 80% |
| **Add Note button height** | 48pt |
| **Bookmark button width** | 20% |
| **Bookmark button size** | 48×48pt |
| **Button corner radius** | 12pt |
| **Icon spacing** | 8pt |
| **Icon size** | 15pt |
| **Horizontal padding** | 16pt |

---

## Complete Footer Spacing Summary

| From | To | Spacing |
|------|-----|---------|
| episodeMetadataView | Scrubber | **16pt** |
| Scrubber | Playback controls | **16pt** |
| Playback controls | Add Note button | **24pt** (16pt + 8pt padding) |

---

## Color Specifications

| Element | Color | RGB/Reference |
|---------|-------|---------------|
| **Background** | `Color.echoBackground` | #262626 |
| **Primary text** | `Color.echoTextPrimary` | White |
| **Secondary text** | `Color.echoTextSecondary` | White 85% |
| **Mint accent** | `Color.mintAccent` | Brand color |
| **Mint button text** | `Color.mintButtonText` | - |
| **Mint button background** | `Color.mintButtonBackground` | - |
| **Inactive track** | `Color.white.opacity(0.2)` | - |
| **Scrubber knob** | `Color.white` | - |

---

## Code Reference

**Footer implementation:** `EpisodePlayerView.swift` lines 222-242

```swift
// --- SECTION 3: FOOTER (FIXED HEIGHT: ~290px) ---
VStack(spacing: 16) {
    // Metadata (Always visible, 2 lines max)
    episodeMetadataView

    // Scrubber
    timeProgressWithMarkers

    // Playback controls
    playbackControlButtons
        .padding(.bottom, 8)

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

*Last Updated: March 4, 2026* • *Commit: f333460*
