# T27 — Player Sheet Spacing Adjustments

**Branch:** `t27-player-spacing-adjustments`
**Commit:** `t27: artwork 240pt, marker gap 6pt, scrubber→controls 24pt, footer bottom 24pt`
**File:** `EpisodePlayerView.swift`
**Date:** March 5, 2026

---

## Changes Made

| Property | Before | After |
|---|---|---|
| `albumArtworkView` — `.frame(width:height:)` | 280 × 280 pt | **240 × 240 pt** |
| `noteMarkerView` — `.padding(.bottom)` (gap to scrubber track) | 0 pt | **6 pt** |
| `timeProgressWithMarkers` → `playbackControlButtons` — `VStack spacing` | 16 pt | **24 pt** |
| footer `VStack` — `.padding(.bottom)` | 48 pt | **24 pt** |

---

## Untouched (deferred)

| Property | Value | Notes |
|---|---|---|
| `episodeMetadataView` — `.padding(.horizontal)` | 16 pt | Consider 32 pt for narrower text column |
| `episodeMetadataView` — `.multilineTextAlignment` | `.center` | Keep center for now-playing context |
| `noteMarkerView` — `.frame(width:height:)` | 28 × 28 pt | Consider 20 × 20 pt in future pass |
| `timeLabelsRow` — `.padding(.top)` | 8 pt | Consider 12 pt in future pass |
| `episodeMetadataView` → `timeProgressWithMarkers` — `VStack spacing` | 16 pt | Consider 20 pt in future pass |
| `playbackControlButtons` — `.padding(.bottom)` | 8 pt | Consider 16 pt in future pass |
| `playbackControlButtons` → `addNoteButton` — total gap | 24 pt | Consider 32 pt in future pass |

---

## Context

These were targeted fixes to the bottom section of the Listening tab. The artwork reduction (280→240pt) redistributes vertical space downward. The marker bottom padding introduces a visual gap between note/bookmark circles and the scrubber track, which previously had no separation. The scrubber→controls spacing increase gives the interactive zone more room before the transport buttons. Footer bottom padding was trimmed to compensate for the space freed up elsewhere and avoid the layout feeling bottom-heavy.

The untouched items remain candidates for a future spacing pass — none were urgent enough to change in this round.

---

*Reference: `20260304-individual-sheet.md` (original spec)*
