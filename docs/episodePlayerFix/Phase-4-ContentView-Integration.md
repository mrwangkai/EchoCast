# Phase 4: Update ContentView Integration

## Problem
ContentView has 5 references to deleted `AudioPlayerView`:
- Line 737: Podcasts view sheet
- Line 1671: PlayerSheetData sheet
- Line 2142: PlayerSheetWrapper NavigationStack
- Line 2471: Note edit sheet
- Line 3605: Downloaded episodes sheet

## Solution
Create a conversion wrapper view that handles iTunes → RSS model conversion, then use `EpisodePlayerView`.

---

## Step 1: Create ConversionWrapper View

**Add this to the BOTTOM of ContentView.swift** (after the main ContentView struct):

```swift
// MARK: - Conversion Wrapper for iTunes Models

/// Wrapper that converts iTunes models to RSS models and presents EpisodePlayerView
struct iTunesPlayerAdapter: View {
    let episode: PodcastEpisode
    let podcast: iTunesPodcast
    let autoPlay: Bool
    let seekToTime: TimeInterval?
    
    @State private var rssModels: (RSSEpisode, PodcastEntity)?
    @State private var isLoading = true
    @State private var loadError: Error?
    
    @ObservedObject private var player = GlobalPlayerManager.shared
    
    init(
        episode: PodcastEpisode,
        podcast: iTunesPodcast,
        autoPlay: Bool = true,
        seekToTime: TimeInterval? = nil
    ) {
        self.episode = episode
        self.podcast = podcast
        self.autoPlay = autoPlay
        self.seekToTime = seekToTime
    }
    
    var body: some View {
        Group {
            if let (rssEpisode, podcastEntity) = rssModels {
                EpisodePlayerView(episode: rssEpisode, podcast: podcastEntity)
                    .onAppear {
                        if autoPlay {
                            player.loadEpisode(rssEpisode, podcast: podcastEntity)
                            if let seekTime = seekToTime {
                                // Delay seek to allow player to load
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    player.seek(to: seekTime)
                                }
                            }
                        }
                    }
            } else if let error = loadError {
                errorView(error: error)
            } else {
                loadingView
            }
        }
        .task {
            await loadRSSData()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
            
            Text("Loading episode...")
                .font(.bodyEcho())
                .foregroundColor(.echoTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.echoBackground)
    }
    
    // MARK: - Error View
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)
            
            Text("Failed to load episode")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
            
            Text(error.localizedDescription)
                .font(.bodyEcho())
                .foregroundColor(.echoTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.echoBackground)
    }
    
    // MARK: - Load RSS Data
    
    private func loadRSSData() async {
        do {
            let models = try await ModelAdapter.shared.convertToRSSModels(
                episode: episode,
                podcast: podcast
            )
            
            await MainActor.run {
                self.rssModels = models
                self.isLoading = false
            }
            
        } catch {
            print("❌ Failed to convert iTunes models to RSS: \(error)")
            await MainActor.run {
                self.loadError = error
                self.isLoading = false
            }
        }
    }
}
```

---

## Step 2: Replace AudioPlayerView References

Now replace all 5 AudioPlayerView references with `iTunesPlayerAdapter`.

### Reference 1: Line 737 (Podcasts view sheet)

**Find:**
```swift
.sheet(isPresented: $showEpisodePlayer) {
    if let episode = selectedEpisode, let podcast = selectedPodcast {
        AudioPlayerView(
            episode: episode,
            podcast: podcast,
            autoPlay: true
        )
    }
}
```

**Replace with:**
```swift
.sheet(isPresented: $showEpisodePlayer) {
    if let episode = selectedEpisode, let podcast = selectedPodcast {
        iTunesPlayerAdapter(
            episode: episode,
            podcast: podcast,
            autoPlay: true
        )
    }
}
```

---

### Reference 2: Line 1671 (PlayerSheetData sheet)

**Find:**
```swift
.sheet(item: $playerSheetData) { data in
    let tempContext = PersistenceController.preview.container.viewContext
    let tempPodcast = createTempPodcast(from: data.podcast, context: tempContext)

    AudioPlayerView(
        episode: data.episode,
        podcast: tempPodcast,
        autoPlay: true
    )
}
```

**Replace with:**
```swift
.sheet(item: $playerSheetData) { data in
    iTunesPlayerAdapter(
        episode: data.episode,
        podcast: data.podcast,
        autoPlay: true
    )
}
```

**Note:** We removed the `tempContext` and `createTempPodcast` calls - no longer needed since ModelAdapter handles Core Data.

---

### Reference 3: Line 2142 (PlayerSheetWrapper)

**Find:**
```swift
NavigationStack {
    AudioPlayerView(
        episode: episode,
        podcast: podcast,
        autoPlay: autoPlay,
        seekToTime: seekToTime
    )
    .navigationBarTitleDisplayMode(.inline)
}
```

**Replace with:**
```swift
iTunesPlayerAdapter(
    episode: episode,
    podcast: podcast,
    autoPlay: autoPlay,
    seekToTime: seekToTime
)
```

**Note:** NavigationStack is removed - `EpisodePlayerView` doesn't need it.

---

### Reference 4: Line 2471 (Note edit sheet)

**Find:**
```swift
.sheet(isPresented: $showPlayer) {
    if let episode = loadedEpisode, let podcast = loadedPodcast {
        AudioPlayerView(
            episode: episode,
            podcast: podcast,
            autoPlay: true,
            seekToTime: parseTimestamp(note.timestamp ?? "")
        )
    }
}
```

**Replace with:**
```swift
.sheet(isPresented: $showPlayer) {
    if let episode = loadedEpisode, let podcast = loadedPodcast {
        iTunesPlayerAdapter(
            episode: episode,
            podcast: podcast,
            autoPlay: true,
            seekToTime: parseTimestamp(note.timestamp ?? "")
        )
    }
}
```

---

### Reference 5: Line 3605 (Downloaded episodes sheet)

**Find:**
```swift
.sheet(item: $episodePlayerData) { playerData in
    AudioPlayerView(
        episode: playerData.episode,
        podcast: playerData.podcast,
        autoPlay: true,
        seekToTime: playerData.seekToTime
    )
}
```

**Replace with:**
```swift
.sheet(item: $episodePlayerData) { playerData in
    iTunesPlayerAdapter(
        episode: playerData.episode,
        podcast: playerData.podcast,
        autoPlay: true,
        seekToTime: playerData.seekToTime
    )
}
```

---

## Step 3: Build and Fix Remaining Errors

**Build the project** (`Cmd + B`)

### Expected Outcome:

1. **All AudioPlayerView errors GONE** ✅
2. **Possible new errors:**
   - `createTempPodcast` function no longer needed (can be deleted)
   - Any other iTunes model references we missed

### If you see `createTempPodcast` not found error:

**Find the function definition** (search for `func createTempPodcast`) and **delete it** - it's no longer needed.

---

## Step 4: Test Basic Flow

1. **Run the app** (`Cmd + R`)
2. **Navigate to podcast browse/search**
3. **Tap an episode**
4. **Verify:**
   - ✅ Loading spinner appears briefly
   - ✅ EpisodePlayerView opens
   - ✅ Episode plays correctly
   - ✅ All 3 tabs work (Listening, Notes, Episode Info)
   - ✅ Player controls remain sticky

---

## Troubleshooting Common Issues

### Issue: "Loading episode..." never completes

**Possible causes:**
1. Feed URL is invalid
2. Network request is blocked
3. RSS parsing failed

**Debug:**
```swift
// In iTunesPlayerAdapter.loadRSSData(), add more logging:
print("🔍 Converting: \(episode.trackName ?? "Unknown")")
print("🔍 Feed URL: \(podcast.feedUrl ?? "None")")

// After try await:
print("✅ Conversion successful!")
```

### Issue: "Failed to load episode" error appears

**Check:**
1. Is the podcast's `feedUrl` valid?
2. Is RSS feed accessible?
3. Check Xcode console for specific error message

---

## Verification Checklist

After Phase 4, verify these are all ✅:

- [ ] Project builds without errors
- [ ] Can tap episode from browse/search → Opens EpisodePlayerView
- [ ] Episode plays correctly
- [ ] All 3 tabs work (Listening, Notes, Episode Info)
- [ ] Player controls remain sticky across tabs
- [ ] Can add notes from "Add note at current time" button
- [ ] Can tap note in Notes tab → Seeks to timestamp
- [ ] Mini player works correctly
- [ ] Home screen "Continue listening" works

---

## What We Accomplished in Phase 4

1. ✅ Created `iTunesPlayerAdapter` - Handles iTunes → RSS conversion
2. ✅ Replaced all 5 AudioPlayerView references
3. ✅ App now uses single player component (`EpisodePlayerView`) everywhere
4. ✅ Eliminated dual model system - everything uses RSS models internally

---

## Next Step
Proceed to **Phase 5: Final Testing & Cleanup**
