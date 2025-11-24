# TODO: 6 Items Summary & Implementation Plan

## Overview

6 bugs/features identified for implementation:

1. ✅ **Add tags to new notes forms** - New Feature (Simple)
2. ✅ **Fix onboarding "Get Started" dead end** - Bug Fix (Simple)
3. ✅ **Add shadow for mini player in dark mode** - UI Enhancement (Simple)
4. ✅ **Fix mini player album art from previous episode** - Bug Fix (Simple)
5. ⚠️ **Episodes/notes never load (Loading screen stuck)** - Bug Fix (Medium - Requires Investigation)
6. ⚠️ **Downloads show as complete but don't persist** - Bug Fix (Medium - Requires Investigation)

---

## Implementation Priority

### Tier 1: Quick Wins (Items 1-4)
These are straightforward fixes that can be implemented immediately without deep investigation.

### Tier 2: Investigated Issues (Items 5-6)
These require debugging and verification before implementing fixes. Analysis completed in `BUGS_ANALYSIS_ITEMS_5_AND_6.md`.

---

## Detailed Implementation Plan

### 1. Add Tags to New Notes Forms ✅

**Status**: Ready to implement
**Complexity**: Low
**Files to Modify**:
- `QuickNoteCaptureView.swift` (or wherever note capture UI is)
- Core Data model if tags not already in schema

**Implementation**:
```swift
// Add to note capture form
@State private var selectedTags: [String] = []
@State private var newTag: String = ""

// UI
VStack {
    // Existing note fields...

    // Tag input
    HStack {
        TextField("Add tag", text: $newTag)
        Button("Add") {
            if !newTag.isEmpty {
                selectedTags.append(newTag)
                newTag = ""
            }
        }
    }

    // Tag chips
    ScrollView(.horizontal) {
        HStack {
            ForEach(selectedTags, id: \.self) { tag in
                TagChip(tag: tag, onRemove: {
                    selectedTags.removeAll { $0 == tag }
                })
            }
        }
    }
}

// Save tags
note.tags = selectedTags.joined(separator: ",")
```

**Testing**:
- Add note with tags
- Verify tags save to Core Data
- Verify tags display in note detail
- Verify tags can be edited

---

### 2. Fix Onboarding "Get Started" Dead End ✅

**Status**: Ready to implement
**Complexity**: Low
**Files to Modify**:
- `OnboardingView.swift` (likely in Views/)

**Current Behavior**:
- User navigates Settings > Show Onboarding
- Goes through onboarding flow
- Clicks "Get Started" → Dead end, stuck in onboarding

**Implementation**:
```swift
// In OnboardingView
@Environment(\.dismiss) private var dismiss

// On "Get Started" button
Button("Get Started") {
    // Save onboarding completion
    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

    // Dismiss back to Settings
    dismiss()
}
```

**Alternative** (if onboarding is presented as sheet):
```swift
// In SettingsView
.sheet(isPresented: $showOnboarding) {
    OnboardingView(dismiss: {
        showOnboarding = false
    })
}

// In OnboardingView
let dismiss: () -> Void

Button("Get Started") {
    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    dismiss()
}
```

**Testing**:
- Go to Settings > Show Onboarding
- Complete onboarding flow
- Click "Get Started"
- Should return to Settings view

---

### 3. Add Shadow for Mini Player in Dark Mode ✅

**Status**: Ready to implement
**Complexity**: Low
**Files to Modify**:
- `MiniPlayerView.swift` (lines ~145-147)

**Current Code**:
```swift
.shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 3)
```

**Problem**:
- Black shadow on dark background is invisible
- Need lighter shadow in dark mode

**Implementation**:
```swift
@Environment(\.colorScheme) private var colorScheme

// Replace existing shadow with:
.shadow(
    color: colorScheme == .dark
        ? Color.white.opacity(0.1)  // Light shadow in dark mode
        : Color.black.opacity(0.15), // Dark shadow in light mode
    radius: 4,
    x: 0,
    y: 3
)
```

**Alternative** (stronger dark mode shadow):
```swift
.shadow(
    color: colorScheme == .dark
        ? Color.white.opacity(0.15)
        : Color.black.opacity(0.15),
    radius: colorScheme == .dark ? 8 : 4,  // Stronger in dark mode
    x: 0,
    y: colorScheme == .dark ? 4 : 3
)
```

**Testing**:
- Test in light mode (should look same as before)
- Test in dark mode (should have visible shadow)
- Test appearance toggle

---

### 4. Fix Mini Player Album Art from Previous Episode ✅

**Status**: Ready to implement
**Complexity**: Low
**Files to Modify**:
- `MiniPlayerView.swift` (lines ~37-52)

**Current Code** (line 38):
```swift
CachedAsyncImage(url: episode.imageURL ?? player.currentPodcast?.artworkURL)
```

**Problem**:
- Image cache retains previous image
- New episode loads but old image shows briefly or persists
- Cache key might be wrong

**Likely Root Cause**:
```swift
// In CachedAsyncImage.swift
if let cachedImage = ImageCache.shared.get(urlString) {
    loadedImage = cachedImage  // Returns old image immediately
    return
}
```

**Implementation**:

**Option A**: Add explicit ID to force refresh
```swift
// In MiniPlayerView
CachedAsyncImage(url: episode.imageURL ?? player.currentPodcast?.artworkURL) { image in
    // ... image view
}
.id(episode.id)  // Force view recreation on episode change
```

**Option B**: Clear image when episode changes
```swift
// In MiniPlayerView
@State private var currentEpisodeID: String?

var body: some View {
    // ...
    CachedAsyncImage(url: episode.imageURL ?? player.currentPodcast?.artworkURL) { image in
        // ... image view
    }
    .onChange(of: episode.id) { _, newID in
        // Force image reload
        currentEpisodeID = newID
    }
    .id(currentEpisodeID)
}
```

**Option C**: Fix CachedAsyncImage to check URL change
```swift
// In CachedAsyncImage.swift
@State private var currentURL: String?

private func loadImage() {
    guard let urlString = url, !urlString.isEmpty, !isLoading else {
        return
    }

    // Clear if URL changed
    if currentURL != urlString {
        loadedImage = nil
        currentURL = urlString
    }

    // Check cache
    if let cachedImage = ImageCache.shared.get(urlString) {
        loadedImage = cachedImage
        return
    }

    // Download...
}
```

**Recommended**: Option A (simplest)

**Testing**:
- Play episode A with artwork
- Close to mini player
- Play episode B with different artwork
- Mini player should immediately show episode B artwork

---

### 5. Episodes/Notes Never Load ⚠️

**Status**: Analysis complete (see `BUGS_ANALYSIS_ITEMS_5_AND_6.md`)
**Complexity**: Medium
**Root Cause**: Likely podcast ID mismatch causing early return

**Recommended Fix**: Use `.sheet(item:)` pattern instead of `.sheet(isPresented:)`

**Implementation**:
```swift
// ContentView.swift

// Replace state variables
@State private var recentEpisodeSheetData: RecentEpisodeSheetData?

struct RecentEpisodeSheetData: Identifiable {
    let id = UUID()
    let episode: RSSEpisode
    let podcast: PodcastEntity
    let timestamp: TimeInterval
}

// Replace handleRecentEpisodeTap
private func handleRecentEpisodeTap(_ item: PlaybackHistoryItem) {
    // Try multiple matching strategies
    guard let podcast = findPodcast(for: item) else {
        // Show error alert
        print("❌ Podcast not found for: \(item.podcastTitle)")
        return
    }

    let episode = RSSEpisode(
        title: item.episodeTitle,
        audioURL: item.audioURL,
        // ... other fields
    )

    // Set data directly
    recentEpisodeSheetData = RecentEpisodeSheetData(
        episode: episode,
        podcast: podcast,
        timestamp: item.currentTime
    )
}

// Replace sheet presentation
.sheet(item: $recentEpisodeSheetData) { data in
    PlayerSheetWrapper(
        episode: data.episode,
        podcast: data.podcast,
        dismiss: { recentEpisodeSheetData = nil },
        autoPlay: true,
        seekToTime: data.timestamp
    )
}

// Add multi-strategy podcast finder
private func findPodcast(for item: PlaybackHistoryItem) -> PodcastEntity? {
    // Try ID
    if let podcast = podcasts.first(where: { $0.id == item.podcastID }) {
        return podcast
    }

    // Try feedURL
    if let feedURL = item.podcastFeedURL,
       let podcast = podcasts.first(where: { $0.feedURL == feedURL }) {
        print("⚠️ Found podcast by feedURL (ID mismatch)")
        return podcast
    }

    // Try title
    if let podcast = podcasts.first(where: { $0.title == item.podcastTitle }) {
        print("⚠️ Found podcast by title (ID mismatch)")
        return podcast
    }

    return nil
}
```

**Testing**:
- Tap recently played episode
- Should load immediately (no Loading screen)
- If podcast deleted → should show error alert
- Test with different podcast ID formats

---

### 6. Downloads Don't Persist ⚠️

**Status**: Analysis complete (see `BUGS_ANALYSIS_ITEMS_5_AND_6.md`)
**Complexity**: Medium
**Root Cause**: Likely episode ID (full URL) used as filename causing invalid path

**Recommended Fix**: Sanitize episode ID for filesystem use

**Implementation**:

**Step 1: Fix getLocalFileURL**
```swift
// GlobalPlayerManager.swift

func getLocalFileURL(for episodeID: String) -> URL? {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let episodesFolder = documentsPath.appendingPathComponent("episodes", isDirectory: true)

    // Create folder if needed
    if !FileManager.default.fileExists(atPath: episodesFolder.path) {
        try? FileManager.default.createDirectory(at: episodesFolder, withIntermediateDirectories: true)
    }

    // CRITICAL: Sanitize episode ID for use as filename
    // Episode ID is often the full audio URL
    let sanitizedID = sanitizeForFilename(episodeID)

    return episodesFolder.appendingPathComponent("\(sanitizedID).mp3")
}

private func sanitizeForFilename(_ string: String) -> String {
    // Hash long URLs to create valid filename
    if string.hasPrefix("http://") || string.hasPrefix("https://") {
        // Use SHA256 hash of URL as filename
        return string.sha256Hash()  // Implement SHA256
    }

    // For non-URLs, replace invalid characters
    let invalidChars = CharacterSet(charactersIn: "/:\\*?\"<>|")
    let sanitized = string.components(separatedBy: invalidChars).joined(separator: "_")

    // Limit length
    return String(sanitized.prefix(200))
}
```

**Step 2: Add comprehensive logging**
```swift
func urlSession(..., didFinishDownloadingTo location: URL) {
    print("📥 DOWNLOAD FINISHED")
    print("   Episode ID: \(episodeID)")
    print("   Temp: \(location.path)")

    guard let destinationURL = getLocalFileURL(for: episodeID) else {
        print("   ❌ Could not create destination URL")
        return
    }

    print("   Dest: \(destinationURL.path)")

    do {
        // Remove existing
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
            print("   ℹ️ Removed existing file")
        }

        // Move
        try FileManager.default.moveItem(at: location, to: destinationURL)
        print("   ✅ File moved")

        // Verify
        guard FileManager.default.fileExists(atPath: destinationURL.path) else {
            print("   ❌ Move succeeded but file doesn't exist!")
            return
        }

        let attrs = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let size = attrs[.size] as? Int64 ?? 0
        print("   ✅ Verified: \(size) bytes")

        // Update state
        DispatchQueue.main.async {
            self.downloadedEpisodes.insert(episodeID)
            print("   ✅ Added to set (total: \(self.downloadedEpisodes.count))")

            if let metadata = self.pendingMetadata[episodeID] {
                self.episodeMetadata[episodeID] = metadata
                self.saveEpisodeMetadata()
                print("   ✅ Metadata saved")
            } else {
                print("   ⚠️ No metadata!")
            }

            self.saveDownloadedEpisodes()
            print("   ✅ Saved to UserDefaults")
        }
    } catch {
        print("   ❌ ERROR: \(error.localizedDescription)")
    }
}
```

**Step 3: Add verification in Settings**
```swift
// SettingsView.swift - DownloadedEpisodesView

.onAppear {
    print("📋 Downloaded Episodes View")
    print("   Count: \(downloadManager.downloadedEpisodes.count)")

    for episodeID in downloadManager.downloadedEpisodes {
        if let url = downloadManager.getLocalFileURL(for: episodeID) {
            let exists = FileManager.default.fileExists(atPath: url.path)
            print("   \(episodeID): \(exists ? "✅" : "❌")")
        }
    }
}
```

**Testing**:
- Download episode
- Check console logs for each step
- Verify file exists at destination path
- Check Settings > Downloaded Episodes
- Should appear in list
- App restart → should still be there

---

## Implementation Order

### Phase 1: Quick Wins (30 min total)
1. Item 3: Mini player shadow in dark mode (5 min)
2. Item 4: Album art fix (10 min)
3. Item 2: Onboarding dismiss fix (5 min)
4. Item 1: Add tags to notes (10 min)

### Phase 2: Bug Investigation & Fixes (2-3 hours)
5. Item 5: Episodes never load
   - Add logging first (30 min)
   - Test and identify exact failure point
   - Implement fix (1 hour)
   - Test thoroughly

6. Item 6: Downloads not persisting
   - Add logging to download process (30 min)
   - Test download and check logs
   - Implement filename sanitization (1 hour)
   - Verify downloads persist across app restart

---

## Success Criteria

### Item 1: Tags ✅
- [ ] Can add tags during note creation
- [ ] Tags save to Core Data
- [ ] Tags display in note detail view
- [ ] Can remove tags

### Item 2: Onboarding ✅
- [ ] "Get Started" dismisses onboarding
- [ ] Returns to Settings view
- [ ] Onboarding completion saved

### Item 3: Shadow ✅
- [ ] Shadow visible in dark mode
- [ ] Shadow appropriate in light mode
- [ ] Smooth transition between modes

### Item 4: Album Art ✅
- [ ] Album art updates immediately when episode changes
- [ ] No flicker of previous episode's art
- [ ] Works in both mini player and full player

### Item 5: Episode Loading ✅
- [ ] No "Loading..." screen when tapping recently played
- [ ] Episode loads immediately
- [ ] Error alert shown if podcast not found
- [ ] Same fix works for note taps

### Item 6: Downloads ✅
- [ ] Downloads show in Settings > Downloaded Episodes
- [ ] Files actually saved to disk
- [ ] Downloads persist after app restart
- [ ] Download count matches actual files
- [ ] Can play downloaded episodes offline

---

## Files to Modify Summary

1. **Tags**: `QuickNoteCaptureView.swift`, `NoteEntity` (Core Data)
2. **Onboarding**: `OnboardingView.swift`, `SettingsView.swift`
3. **Shadow**: `MiniPlayerView.swift`
4. **Album Art**: `MiniPlayerView.swift` or `CachedAsyncImage.swift`
5. **Episode Loading**: `ContentView.swift` (HomeView section)
6. **Downloads**: `GlobalPlayerManager.swift`, `SettingsView.swift`
