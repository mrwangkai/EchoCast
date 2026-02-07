# Mini Player Implementation Guide for Claude Code

**Reference:** `/mnt/project/miniPlayerBehavior.md`  
**Target File:** `MiniPlayerView.swift`  
**Date:** February 6, 2026

---

## Task Overview

Update `MiniPlayerView.swift` to match the Figma design with two distinct states and proper interaction behaviors.

---

## Implementation Checklist

### 1. State Management Setup

Add these state variables to `MiniPlayerView`:

```swift
@ObservedObject private var player = GlobalPlayerManager.shared
@State private var showingFullPlayer = false
@State private var showingAddNote = false
@Environment(\.dismiss) private var dismiss
```

### 2. Two-State Body Structure

Replace the current `body` with this pattern (reference: lines 73-103 in miniPlayerBehavior.md):

```swift
var body: some View {
    if let episode = player.currentEpisode {
        // STATE: Episode playing
        HStack(spacing: 12) {
            artworkView(for: episode)
            episodeInfoView(for: episode)
            Spacer()
            HStack(spacing: 8) {
                addNoteButton
                playPauseButton
            }
        }
        .padding(12)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        .cornerRadius(12, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: -2)
        .onTapGesture {
            showingFullPlayer = true
        }
    } else {
        // STATE: No episode - hide mini player
        EmptyView()
    }
}
```

### 3. Build the Artwork View

Create this supporting view (reference: lines 40-43 in miniPlayerBehavior.md):

```swift
private func artworkView(for episode: RSSEpisode) -> some View {
    Group {
        if let imageURL = episode.imageURL ?? player.currentPodcast?.artworkURL,
           let url = URL(string: imageURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "podcast.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .padding(8)
            }
        } else {
            Image(systemName: "podcast.fill")
                .resizable()
                .foregroundColor(.gray)
                .padding(8)
        }
    }
    .frame(width: 48, height: 48)
    .cornerRadius(8)
    .clipped()
}
```

### 4. Build the Episode Info View

Create this supporting view (reference: lines 45-48 in miniPlayerBehavior.md):

```swift
private func episodeInfoView(for episode: RSSEpisode) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(episode.title)
            .font(.custom("SF Pro Rounded", size: 15).weight(.medium))
            .foregroundColor(.white)
            .lineLimit(1)
        
        if let podcastTitle = player.currentPodcast?.title {
            Text(podcastTitle)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
        }
    }
}
```

### 5. Build the Add Note Button

Create this button (reference: lines 126-137 in miniPlayerBehavior.md):

```swift
private var addNoteButton: some View {
    Button(action: {
        showingAddNote = true
    }) {
        Image(systemName: "note.text.badge.plus")
            .font(.system(size: 20))
            .foregroundColor(Color(red: 0.0, green: 0.784, blue: 0.702)) // Mint #00c8b3
    }
    .frame(width: 40, height: 40)
    .buttonStyle(.plain)
}
```

### 6. Build the Play/Pause Button

Create this button (reference: lines 50-54 in miniPlayerBehavior.md):

```swift
private var playPauseButton: some View {
    Button(action: {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }) {
        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: 20))
            .foregroundColor(Color(red: 0.0, green: 0.784, blue: 0.702)) // Mint #00c8b3
    }
    .frame(width: 40, height: 40)
    .buttonStyle(.plain)
}
```

### 7. Add Sheet Modifiers

Add these sheet presentations at the end of the body (reference: lines 107-122 in miniPlayerBehavior.md):

```swift
var body: some View {
    // ... existing body code ...
    .sheet(isPresented: $showingAddNote) {
        if let episode = player.currentEpisode,
           let podcast = player.currentPodcast {
            AddNoteSheet(
                playerState: player,
                episode: episode,
                podcast: podcast
            )
        }
    }
    .sheet(isPresented: $showingFullPlayer) {
        if let episode = player.currentEpisode,
           let podcast = player.currentPodcast {
            EpisodePlayerView(episode: episode, podcast: podcast)
        }
    }
}
```

---

## Design Specifications Reference

| Element | Specification |
|---------|--------------|
| **Container Background** | `Color(red: 0.2, green: 0.2, blue: 0.2)` (#333) |
| **Corner Radius** | 12pt (top corners only) |
| **Container Padding** | 12pt |
| **Container Height** | ~72pt when playing |
| **Artwork Size** | 48x48pt |
| **Artwork Corner Radius** | 8pt |
| **Episode Title Font** | SF Pro Rounded Medium 15pt, white |
| **Podcast Name Font** | SF Pro Regular 13pt, white 70% opacity |
| **Text Spacing** | 4pt between title and name |
| **Button Tap Area** | 40x40pt |
| **Button Icon Size** | 20pt |
| **Accent Color** | Mint #00c8b3 (rgb: 0.0, 0.784, 0.702) |
| **Button Spacing** | 8pt between buttons |

---

## Critical Behaviors to Implement

### Interaction Behaviors (reference: lines 56-68 in miniPlayerBehavior.md)

✅ **KEEP THESE:**
- Tapping mini player background opens full player sheet (`showingFullPlayer = true`)
- Playback continues when transitioning between mini/full
- Mini player hides when full player opens
- Mini player shows when full player dismisses (if episode exists)

✅ **ADD THESE:**
- "Add note" button tap: Opens `AddNoteSheet` with current timestamp
- Play/Pause button tap: Toggles playback (`player.play()` / `player.pause()`)
- Show `EmptyView()` when `player.currentEpisode == nil`
- Buttons use `.buttonStyle(.plain)` to prevent tap interference with background gesture

### Touch Target Separation

**CRITICAL:** Buttons must NOT trigger the background tap gesture:
- Use `.buttonStyle(.plain)` on both buttons
- Background tap should only work when tapping the artwork or episode info area
- Test: Tapping play/pause should NOT open full player

---

## Testing Checklist (reference: lines 139-149 in miniPlayerBehavior.md)

After implementation, verify:

- [ ] Mini player hidden when no episode playing
- [ ] Album artwork displays correctly (48x48pt with 8pt corner radius)
- [ ] Episode title and podcast name truncate properly to 1 line each
- [ ] Add note button opens `AddNoteSheet` (not full player)
- [ ] Play/Pause button toggles playback (not full player)
- [ ] Tapping background (artwork/episode info) opens full player
- [ ] Playback continues during all transitions
- [ ] Layout matches Figma design specifications
- [ ] Both sheets (AddNoteSheet and EpisodePlayerView) present correctly

---

## Key Files to Reference

1. **`miniPlayerBehavior.md`** - Full specification (this is your source of truth)
2. **`GlobalPlayerManager.swift`** - For player state (`isPlaying`, `currentEpisode`, `currentPodcast`, `play()`, `pause()`)
3. **`AddNoteSheet.swift`** - For sheet integration
4. **`EpisodePlayerView.swift`** - For full player sheet
5. **`EchoCast-Development-Guide.md`** - For design tokens (if needed)

---

## Common Pitfalls to Avoid

❌ **DON'T:**
- Hardcode colors - use exact RGB values from spec
- Make buttons trigger full player - only background should
- Show mini player when `currentEpisode == nil`
- Use different corner radius values
- Skip `.buttonStyle(.plain)` on buttons

✅ **DO:**
- Use `GlobalPlayerManager.shared` as single source of truth
- Keep exact spacing values from spec (12pt, 8pt, 4pt)
- Test both button taps AND background tap separately
- Ensure smooth transitions between states
- Match artwork size and corner radius exactly

---

## Expected File Structure

```
MiniPlayerView.swift
├── Properties (@ObservedObject player, @State variables)
├── body: Two-state conditional
│   ├── STATE: Episode playing
│   │   ├── HStack layout
│   │   ├── Background tap gesture
│   │   └── Shadow/corner radius styling
│   └── STATE: No episode (EmptyView)
├── Supporting Views
│   ├── artworkView(for:)
│   ├── episodeInfoView(for:)
│   ├── addNoteButton
│   └── playPauseButton
└── Sheet Modifiers
    ├── .sheet(isPresented: $showingAddNote)
    └── .sheet(isPresented: $showingFullPlayer)
```

---

## Success Criteria

The implementation is complete when:

1. ✅ Two distinct states render correctly
2. ✅ All design specs match exactly (sizes, colors, spacing)
3. ✅ Background tap opens full player
4. ✅ Add note button opens AddNoteSheet only
5. ✅ Play/pause button toggles playback only
6. ✅ Playback continues across all transitions
7. ✅ No compile errors or warnings
8. ✅ All 8 testing checklist items pass

---

**Ready to implement!** Follow this guide step-by-step and reference `miniPlayerBehavior.md` lines as noted for additional context.
