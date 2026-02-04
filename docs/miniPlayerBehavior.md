// guidance from claude to mimick the figma design for individual notes card

Please update the MiniPlayerView to match the design and behavior requirements.

Reference Figma design: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects (mini player at bottom of screen)

Current Issues to Fix:
1. Mini player should show "No episode selected" state when player.currentEpisode == nil
2. Need to add album artwork display
3. Need to add "Add note" button
4. Layout needs to match Figma design

Requirements:

1. Two States for Mini Player:

STATE A - No Episode Playing:
- Display: "No episode selected" centered text
- Background: Same dark card background
- Height: Minimal (maybe 60pt)

STATE B - Episode Playing:
- Left: Album artwork (48x48pt, 8pt corner radius)
- Center: Episode metadata (VStack)
  - Episode title (1 line, truncated)
  - Podcast name (1 line, truncated, secondary color)
- Right: Two buttons (HStack)
  - "Add note" button (icon: doc.text.badge.plus or note.text.badge.plus)
  - Play/Pause button (icon: play.fill or pause.fill)

2. Layout Specifications:

Container:
- Background: Color(red: 0.2, green: 0.2, blue: 0.2) // #333
- Corner radius: 12pt (top corners only)
- Padding: 12pt
- Shadow: Subtle shadow above
- Height: ~72pt when playing

Artwork:
- Size: 48x48pt
- Corner radius: 8pt
- Placeholder: podcast.fill icon if artwork fails to load

Episode Info:
- Episode title: SF Pro Rounded Medium 15pt, white, 1 line
- Podcast name: SF Pro Regular 13pt, white 70% opacity, 1 line
- Spacing: 4pt between title and name

Buttons:
- Size: 40x40pt tap area
- Icon size: 20pt
- Color: Mint accent #00c8b3 for active state
- Spacing: 8pt between buttons

3. Behavior (Keep Existing + Add):

KEEP THESE:
- Tapping mini player opens full player sheet (showFullPlayer = true)
- Playback continues when transitioning between mini/full
- Mini player hides when full player opens
- Mini player shows when full player dismisses (if episode exists)

ADD THESE:
- "Add note" button tap: Opens AddNoteSheet with current timestamp
- Play/Pause button tap: Toggles playback (player.play() / player.pause())
- Show "No episode selected" when player.currentEpisode == nil
- Hide mini player entirely when no episode (player.showMiniPlayer = false)

4. Implementation in MiniPlayerView.swift:

Update the body view to:
```swift
var body: some View {
    if let episode = player.currentEpisode {
        // STATE B: Episode playing
        HStack(spacing: 12) {
            // Artwork
            artworkView(for: episode)
            
            // Episode info
            episodeInfoView(for: episode)
            
            Spacer()
            
            // Action buttons
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
            showFullPlayer = true
        }
    } else {
        // STATE A: No episode (optional - can just hide entirely)
        EmptyView()
    }
}
```

5. Add Note Sheet Integration:

Add state variable:
```swift
@State private var showingAddNote = false
```

Add sheet modifier:
```swift
.sheet(isPresented: $showingAddNote) {
    AddNoteSheet(
        playerState: player,
        episode: player.currentEpisode,
        podcast: player.currentPodcast
    )
}
```

Wire up button:
```swift
private var addNoteButton: some View {
    Button(action: {
        showingAddNote = true
    }) {
        Image(systemName: "note.text.badge.plus")
            .font(.system(size: 20))
            .foregroundColor(Color(red: 0.0, green: 0.784, blue: 0.702))
    }
    .frame(width: 40, height: 40)
    .buttonStyle(.plain)
}
```

6. Testing:

After implementation, verify:
- [ ] Mini player hidden when no episode playing
- [ ] Album artwork displays correctly (48x48pt)
- [ ] Episode title and podcast name truncate properly
- [ ] Add note button opens AddNoteSheet
- [ ] Play/Pause button toggles playback
- [ ] Tapping background (not buttons) opens full player
- [ ] Playback continues during all transitions
- [ ] Layout matches Figma design

Reference existing files:
- MiniPlayerView.swift (current implementation)
- AddNoteSheet.swift (for sheet integration)
- GlobalPlayerManager.shared (for player state)
- EchoCast-Development-Guide.md (for design tokens)

Build and ensure no errors. The mini player should now match the Figma design with full functionality.
