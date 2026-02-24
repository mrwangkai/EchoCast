# Continue Listening Refresh Diagnosis

**Date:** February 24, 2026
**Issue:** "Continue Listening" doesn't update on HomeView after minimizing the player

---

## 1. How does HomeView observe PlaybackHistoryManager?

**Answer: HomeView does NOT observe PlaybackHistoryManager directly.**

HomeView.swift:
- Line 38: `@ObservedObject private var player = GlobalPlayerManager.shared`
- Line 46: `@State private var continueListeningEpisodes: [(historyItem: PlaybackHistoryItem, podcast: PodcastEntity)] = []`

HomeView uses its own `@State` array (`continueListeningEpisodes`) to store the data, not a direct binding to `PlaybackHistoryManager.shared.recentlyPlayed`.

---

## 2. Is PlaybackHistoryManager.recentlyPlayed marked @Published?

**Answer: YES**

PlaybackHistoryManager.swift, line 31:
```swift
@Published var recentlyPlayed: [PlaybackHistoryItem] = []
```

The property is `@Published`, but HomeView is not observing it.

---

## 3. When does HomeView load/refresh its continue listening data?

**Answer: HomeView refreshes in 3 scenarios**

HomeView.swift:
- Line 280-282: `.onAppear { loadContinueListeningEpisodes() }`
- Line 283-285: `.onChange(of: allPodcasts.count) { _ in loadContinueListeningEpisodes() }`
- Line 286-288: `.onChange(of: player.currentEpisode?.id) { _ in loadContinueListeningEpisodes() }`

The `loadContinueListeningEpisodes()` function (line 362) manually fetches from PlaybackHistoryManager:
```swift
let historyItems = PlaybackHistoryManager.shared.getRecentlyPlayed(limit: 5)
```

---

## 4. When does savePlaybackHistory() get called in GlobalPlayerManager?

**Answer: Two triggers**

### A. Timer during playback (line 330-355)
- Time observer interval: 0.5 seconds
- History save interval: Every 10 seconds of playback
```swift
let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
    // Update playback history every 10 seconds
    if self.currentTime - self.lastHistoryUpdate >= 10.0 {
        self.savePlaybackHistory()
        self.lastHistoryUpdate = self.currentTime
    }
}
```

### B. Immediate calls on specific events
- Line 442: When `loadEpisodeAndPlay()` is called
- Line 477: When `stop()` is called
- Line 490: When `closeMiniPlayer()` is called

---

## 5. Is there any explicit refresh trigger when sheets dismiss or player minimizes?

**Answer: NO**

### When EpisodePlayerView sheet dismisses:
- No `.onDisappear` handler on the sheet
- No dismissal callback

### When closeMiniPlayer() is called (GlobalPlayerManager.swift, line 487-495):
```swift
func closeMiniPlayer() {
    // Save position but keep episode loaded
    if currentEpisode != nil && currentPodcast != nil {
        savePlaybackHistory()
    }
    player?.pause()
    isPlaying = false
    showMiniPlayer = false
}
```
- This DOES call `savePlaybackHistory()` which updates `PlaybackHistoryManager.shared.recentlyPlayed`
- But HomeView's `.onChange(of: player.currentEpisode?.id)` won't fire because the episode is still loaded
- HomeView has no other trigger to refresh

---

## ROOT CAUSE

**HomeView is not reactive to PlaybackHistoryManager changes.**

1. `PlaybackHistoryManager.shared.recentlyPlayed` is `@Published`
2. HomeView does NOT observe this property (it's not an `@ObservedObject`)
3. HomeView uses its own `@State var continueListeningEpisodes` array
4. HomeView only refreshes when:
   - View appears
   - Podcast count changes
   - Episode ID changes

**When minimizing the player:**
- `closeMiniPlayer()` calls `savePlaybackHistory()` → updates `PlaybackHistoryManager.shared.recentlyPlayed`
- BUT `player.currentEpisode?.id` does NOT change (episode is still loaded)
- Therefore HomeView's `.onChange(of: player.currentEpisode?.id)` does NOT fire
- HomeView continues showing stale `continueListeningEpisodes` data

---

## POTENTIAL FIXES

1. **Make HomeView observe PlaybackHistoryManager directly:**
   - Add `@StateObject private var historyManager = PlaybackHistoryManager.shared`
   - Use `historyManager.recentlyPlayed` directly instead of copying to `@State var continueListeningEpisodes`

2. **Add a refresh trigger when player sheet dismisses:**
   - Add `.onDisappear` to EpisodePlayerView sheet
   - Or use `.interactiveDismiss` callback

3. **Add a refresh trigger when mini player closes:**
   - Watch `player.showMiniPlayer` for changes
   - Add `.onChange(of: player.showMiniPlayer)` to trigger reload

4. **Combine approaches:**
   - Make HomeView observe PlaybackHistoryManager
   - This ensures it updates whenever history is saved (from timer or explicit calls)
