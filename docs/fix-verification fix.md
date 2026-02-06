TASK: Fix Two Critical Issues Found in Testing

Issue 1: Sheet Opens Before Podcast is Set
- User taps podcast
- showingPodcastDetail = true (sheet opens)
- THEN selectedPodcast = podcast (too late!)
- Result: Blank sheet on first attempt

Issue 2: Play Button Not Connected
- User taps play button in player
- Nothing happens - play() never called
- ▶️ [Player] Play called NEVER appears in console
- Result: Audio never starts

═══════════════════════════════════════════════════════════

FIX 1: Ensure Podcast is Set BEFORE Opening Sheet

Find all locations where showingPodcastDetail = true

FILE: PodcastDiscoveryView.swift (browse view)

Find this pattern (around line 100):
```swift
.onTapGesture {
    selectedPodcast = podcast
    showingPodcastDetail = true
}
```

If order is wrong, ensure selectedPodcast is set FIRST:
```swift
.onTapGesture {
    print("🔓 [Browse] Podcast tapped: \(podcast.title ?? "Unknown")")
    print("🔓 [Browse] Setting selectedPodcast BEFORE opening sheet")
    
    selectedPodcast = podcast
    
    // Small delay to ensure state is set
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        print("🔓 [Browse] Opening sheet for: \(podcast.title ?? "Unknown")")
        showingPodcastDetail = true
    }
}
```

Also check CategoryCarouselSection onPodcastTap callback:
```swift
CategoryCarouselSection(
    genre: genre,
    podcasts: ...,
    onViewAll: { ... },
    onPodcastTap: { podcast in
        print("🎧 [Browse] Carousel podcast tapped: \(podcast.displayName)")
        selectedPodcast = podcast
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            showingPodcastDetail = true
        }
    }
)
```

═══════════════════════════════════════════════════════════

FIX 2: Connect Play Button to GlobalPlayerManager

FILE: EpisodePlayerView.swift or wherever play button is

Find the play button (search for "play.fill" or similar):

WRONG (not connected):
```swift
Button(action: {
    // Nothing or local state only
}) {
    Image(systemName: "play.fill")
}
```

CORRECT (connected to GlobalPlayerManager):
```swift
Button(action: {
    print("🎮 [PlayerUI] Play button tapped")
    if player.isPlaying {
        print("⏸️ [PlayerUI] Calling pause()")
        player.pause()
    } else {
        print("▶️ [PlayerUI] Calling play()")
        player.play()
    }
}) {
    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
}
```

Check that player is defined as:
```swift
@ObservedObject private var player = GlobalPlayerManager.shared
```

NOT:
```swift
var player = GlobalPlayerManager.shared  // ← Missing @ObservedObject
```

═══════════════════════════════════════════════════════════

FIX 3: Add Debug Logging to Play Button

In play button action, add comprehensive logging:
```swift
Button(action: {
    print("🎮 [PlayerUI] Play button TAPPED")
    print("🎮 [PlayerUI] Player exists: \(player != nil)")
    print("🎮 [PlayerUI] Current isPlaying: \(player.isPlaying)")
    print("🎮 [PlayerUI] Current episode: \(player.currentEpisode?.title ?? "nil")")
    
    if player.isPlaying {
        print("⏸️ [PlayerUI] Calling player.pause()")
        player.pause()
    } else {
        print("▶️ [PlayerUI] Calling player.play()")
        player.play()
    }
    
    print("🎮 [PlayerUI] Action completed")
}) {
    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
        .font(.system(size: 24))
}
```

═══════════════════════════════════════════════════════════

TESTING:

After Fix 1:
1. Tap podcast ONCE
2. Check console:
   🔓 [Browse] Setting selectedPodcast BEFORE opening sheet
   🔓 [Browse] Opening sheet for: NPR News
   📊 [PodcastDetail] Task started for: NPR News  ← Should appear on 1st tap!

After Fix 2:
1. Tap episode
2. Player opens
3. Tap play button
4. Check console:
   🎮 [PlayerUI] Play button TAPPED
   ▶️ [PlayerUI] Calling player.play()
   ▶️ [Player] Play called  ← Should finally appear!

═══════════════════════════════════════════════════════════

Commit when both work:
"Fix: Ensure state set before sheets open, connect play button to player"