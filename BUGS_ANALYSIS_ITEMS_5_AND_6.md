# Bug Analysis: Episodes Never Load & Downloads Not Persisting

## Bug #5: Episodes/Notes Never Load (Stuck on "Loading..." Screen)

### Current Behavior
When tapping on a recently played episode or saved note, the player sheet opens but shows "Loading..." screen indefinitely and never actually loads the episode.

### Code Analysis

**Location**: `ContentView.swift` lines 356-408 (`recentEpisodePlayerSheet`)

```swift
private var recentEpisodePlayerSheet: some View {
    Group {
        if let episode = selectedRecentEpisode, let podcast = selectedRecentPodcast {
            PlayerSheetWrapper(...)  // ✅ This works
        } else {
            // ❌ STUCK HERE - Shows "Loading podcast..."
            VStack {
                ProgressView()
                Text("Loading podcast...")
            }
        }
    }
}
```

**Tap Handler**: `ContentView.swift` lines 602-642 (`handleRecentEpisodeTap`)

```swift
private func handleRecentEpisodeTap(_ item: PlaybackHistoryItem) {
    // 1. Find podcast
    guard let podcast = podcasts.first(where: { $0.id == item.podcastID }) else {
        return  // ❌ EARLY RETURN - Episode never loads
    }

    // 2. Create episode from history item
    let episode = RSSEpisode(
        title: item.episodeTitle,
        audioURL: item.audioURL,
        // ... other fields
    )

    // 3. Reset state
    selectedRecentEpisode = nil
    selectedRecentPodcast = nil
    showRecentEpisodePlayer = false

    // 4. Set state in nested async
    DispatchQueue.main.async {
        self.selectedRecentEpisode = episode
        self.selectedRecentPodcast = podcast
        self.selectedRecentTimestamp = item.currentTime

        DispatchQueue.main.async {
            self.showRecentEpisodePlayer = true
        }
    }
}
```

### Possible Root Causes

#### 1. **Podcast ID Mismatch** (Most Likely)
**Problem**: `item.podcastID` stored in PlaybackHistoryItem doesn't match any `podcast.id` in Core Data

**Why This Happens**:
- PlaybackHistoryItem stores `podcastID` when episode starts playing
- Podcast IDs might be generated differently (feedURL vs title hash vs UUID)
- If podcast is deleted and re-added, ID changes
- ID format inconsistency between storage and lookup

**Evidence**:
- Line 606: `guard let podcast = podcasts.first(where: { $0.id == item.podcastID })`
- If this guard fails, function returns early silently
- No podcast found = loading screen shows forever

**How to Verify**:
- Check console logs: "❌ Could not find podcast with ID: ..."
- If this message appears, podcast lookup is failing

#### 2. **Async State Setting Race Condition**
**Problem**: Triple-nested async state changes with reset in between

**Why This Happens**:
```swift
// Reset to nil
selectedRecentEpisode = nil
selectedRecentPodcast = nil
showRecentEpisodePlayer = false

// Then set in async
DispatchQueue.main.async {
    self.selectedRecentEpisode = episode  // Might still be nil when sheet checks
    self.selectedRecentPodcast = podcast
}
```

**Evidence**:
- Sheet checks `if let episode = selectedRecentEpisode` immediately
- If async hasn't completed yet, both are still nil
- Shows loading screen
- Async completes but sheet doesn't re-evaluate (view not re-rendered)

#### 3. **Sheet Presentation Timing Issue**
**Problem**: Sheet opens before state is set

```swift
// State set in first async
DispatchQueue.main.async {
    self.selectedRecentEpisode = episode
    self.selectedRecentPodcast = podcast

    // Sheet shown in second async
    DispatchQueue.main.async {
        self.showRecentEpisodePlayer = true  // Opens sheet
    }
}
```

**Why This Fails**:
- Both async blocks might execute out of order
- Sheet might open before episode/podcast are set
- SwiftUI evaluates `recentEpisodePlayerSheet` immediately when `showRecentEpisodePlayer = true`
- If episode/podcast still nil → loading screen

#### 4. **State Not Triggering View Update**
**Problem**: Setting `selectedRecentEpisode` and `selectedRecentPodcast` doesn't cause sheet content to re-render

**Why This Happens**:
- Sheet is already open showing loading view
- State changes but SwiftUI doesn't re-evaluate the `if let` condition
- No `@Published` or explicit view refresh
- View thinks it's already rendered correctly

### Recommended Fixes (Ordered by Priority)

#### Fix #1: Use Direct Episode/Podcast Passing (Cleanest)
**Approach**: Don't rely on intermediate state variables

```swift
// Create a new state variable
@State private var recentEpisodeSheetData: (episode: RSSEpisode, podcast: PodcastEntity, timestamp: TimeInterval)?

// In handleRecentEpisodeTap
guard let podcast = podcasts.first(where: { $0.id == item.podcastID }) else {
    print("❌ Could not find podcast")
    // Show alert to user
    return
}

let episode = RSSEpisode(...)
recentEpisodeSheetData = (episode, podcast, item.currentTime)

// Sheet presentation
.sheet(item: $recentEpisodeSheetData) { data in
    PlayerSheetWrapper(
        episode: data.episode,
        podcast: data.podcast,
        dismiss: { recentEpisodeSheetData = nil },
        seekToTime: data.timestamp
    )
}
```

**Advantages**:
- No timing issues - data is ready before sheet opens
- No async complexity
- No nil checks needed
- `.sheet(item:)` only opens when data is non-nil

#### Fix #2: Better Podcast ID Matching
**Approach**: Use multiple matching strategies

```swift
private func findPodcast(for historyItem: PlaybackHistoryItem) -> PodcastEntity? {
    // Try ID match first
    if let podcast = podcasts.first(where: { $0.id == historyItem.podcastID }) {
        return podcast
    }

    // Fallback: Try title match
    if let podcast = podcasts.first(where: { $0.title == historyItem.podcastTitle }) {
        print("⚠️ Found podcast by title match (ID mismatch)")
        return podcast
    }

    // Fallback: Try feedURL match
    if let feedURL = historyItem.podcastFeedURL,
       let podcast = podcasts.first(where: { $0.feedURL == feedURL }) {
        print("⚠️ Found podcast by feedURL match")
        return podcast
    }

    return nil
}
```

**Advantages**:
- More resilient to ID changes
- Can find podcasts even if IDs don't match
- Logs when fallback is used

#### Fix #3: Remove Async Wrapping
**Approach**: Set state synchronously

```swift
private func handleRecentEpisodeTap(_ item: PlaybackHistoryItem) {
    guard let podcast = podcasts.first(where: { $0.id == item.podcastID }) else {
        print("❌ Podcast not found")
        return
    }

    let episode = RSSEpisode(...)

    // Set state SYNCHRONOUSLY
    selectedRecentEpisode = episode
    selectedRecentPodcast = podcast
    selectedRecentTimestamp = item.currentTime
    showRecentEpisodePlayer = true
}
```

**Advantages**:
- No race conditions
- State ready before sheet evaluates
- Simpler code

#### Fix #4: Add Logging and Error Handling
**Approach**: Show user-friendly error instead of infinite loading

```swift
@State private var showRecentEpisodeError = false
@State private var recentEpisodeErrorMessage = ""

private func handleRecentEpisodeTap(_ item: PlaybackHistoryItem) {
    guard let podcast = podcasts.first(where: { $0.id == item.podcastID }) else {
        recentEpisodeErrorMessage = "Podcast not found. It may have been deleted."
        showRecentEpisodeError = true
        return
    }
    // ... rest
}

// Add alert
.alert("Error", isPresented: $showRecentEpisodeError) {
    Button("OK") { }
} message: {
    Text(recentEpisodeErrorMessage)
}
```

---

## Bug #6: Downloads Not Persisting (Shows as Downloaded but Isn't in Settings)

### Current Behavior
When user clicks download icon on episode:
1. Progress shows (0%, 50%, 100%)
2. Shows "Downloaded" label in episode row
3. BUT: Episode doesn't appear in Settings > Downloaded Episodes list

### Code Analysis

**Download Manager**: `GlobalPlayerManager.swift` lines 439-678

**Download Flow**:
```swift
func downloadEpisode(_ episode: RSSEpisode, ...) {
    // 1. Store pending metadata
    pendingMetadata[episodeID] = metadata

    // 2. Start download
    let task = session.downloadTask(with: url)
    task.taskDescription = episodeID
    activeDownloads[episodeID] = task

    // 3. Set progress to 0
    downloadProgress[episodeID] = 0.0

    task.resume()
}

// When download completes
func urlSession(..., didFinishDownloadingTo location: URL) {
    // 1. Move file to permanent location
    try FileManager.default.moveItem(at: location, to: destinationURL)

    // 2. Update state
    downloadedEpisodes.insert(episodeID)  // ✅ Add to set
    downloadProgress.removeValue(forKey: episodeID)

    // 3. Save metadata
    if let metadata = pendingMetadata[episodeID] {
        episodeMetadata[episodeID] = metadata
        saveEpisodeMetadata()
    }

    // 4. Persist to UserDefaults
    saveDownloadedEpisodes()
}
```

**Downloaded Episodes View**: Likely in `SettingsView.swift`

### Possible Root Causes

#### 1. **Episode ID Mismatch Between Download and Display** (Most Likely)
**Problem**: Episode ID used for download differs from ID used to display in Settings

**Why This Happens**:
```swift
// When downloading
let episodeID = episode.id  // Uses RSSEpisode.id

// RSSEpisode.id definition (PodcastRSSService.swift)
var id: String {
    if let audioURL = audioURL, !audioURL.isEmpty {
        return audioURL  // ✅ ID = full audio URL
    } else {
        return title.hashValue.description  // ⚠️ Fallback
    }
}

// In Settings
// If Settings queries by different ID format → won't find downloads
```

**Evidence**:
- `downloadedEpisodes` is a `Set<String>` of episode IDs
- If Settings view queries with different ID → won't match
- Episode shows as "not downloaded" in Settings

#### 2. **Download Completes But State Not Saved**
**Problem**: File downloads successfully but `saveDownloadedEpisodes()` fails silently

**Why This Happens**:
```swift
private func saveDownloadedEpisodes() {
    UserDefaults.standard.set(Array(downloadedEpisodes), forKey: "downloadedEpisodes")
}
```

**Possible Failures**:
- UserDefaults quota exceeded
- Encoding fails silently
- App terminated before save completes
- Background session doesn't trigger save

**Evidence**:
- `downloadedEpisodes.insert(episodeID)` succeeds in memory
- UI shows "Downloaded" (reads from in-memory set)
- App restart → UserDefaults load returns empty → downloads lost
- Settings reads from UserDefaults → shows no downloads

#### 3. **File Not Actually Saved**
**Problem**: `moveItem` fails but error is caught and ignored partially

**Code**:
```swift
do {
    try FileManager.default.moveItem(at: location, to: destinationURL)

    // Only adds to downloadedEpisodes if move succeeds
    downloadedEpisodes.insert(episodeID)
    saveDownloadedEpisodes()
} catch {
    print("Error moving downloaded file: \(error)")
    // ❌ Error logged but download still marked in progress UI
}
```

**Why This Happens**:
- Background download completes → temporary file created
- `moveItem` fails (permissions, disk space, path too long)
- Download marked as failed in logs
- But `downloadProgress` might still show 100% briefly before being removed
- UI briefly shows "Downloaded" before state corrects

**Evidence**:
- Check console for "Error moving downloaded file"
- File doesn't exist at `getLocalFileURL(for: episodeID)`
- `downloadedEpisodes` doesn't actually contain episode

#### 4. **Settings View Querying Wrong Data Source**
**Problem**: Settings view not observing `EpisodeDownloadManager.shared`

**Why This Happens**:
```swift
// In SettingsView
@ObservedObject private var downloadManager = EpisodeDownloadManager.shared

// Should show:
ForEach(Array(downloadManager.downloadedEpisodes), id: \.self) { episodeID in
    // Display episode
}

// If Settings doesn't observe properly or queries different source
// → Won't see downloads
```

**Evidence**:
- Downloads exist in `downloadManager.downloadedEpisodes`
- Settings view shows empty list
- Not observing the singleton properly

#### 5. **Episode Metadata Missing**
**Problem**: Download succeeds but metadata isn't saved

**Code**:
```swift
// Save metadata
if let metadata = pendingMetadata[episodeID] {
    episodeMetadata[episodeID] = metadata
    saveEpisodeMetadata()
}
```

**Why This Happens**:
- `pendingMetadata[episodeID]` is nil when download completes
- Metadata was removed or never added
- Settings view needs metadata (title, podcast name) to display
- No metadata = can't display in list

**Evidence**:
- `downloadedEpisodes` contains episodeID
- `episodeMetadata[episodeID]` is nil
- Settings can't render row without title/podcast info

### Recommended Fixes (Ordered by Priority)

#### Fix #1: Add Comprehensive Logging
**Approach**: Log every step of download process

```swift
func downloadEpisode(_ episode: RSSEpisode, ...) {
    print("📥 DOWNLOAD START")
    print("   Episode ID: \(episodeID)")
    print("   Episode Title: \(episode.title)")
    print("   Audio URL: \(episode.audioURL ?? "nil")")
    // ... existing code
}

func urlSession(..., didFinishDownloadingTo location: URL) {
    print("📥 DOWNLOAD FINISHED")
    print("   Episode ID: \(episodeID)")
    print("   Temp location: \(location)")
    print("   Destination: \(destinationURL)")

    do {
        try FileManager.default.moveItem(at: location, to: destinationURL)
        print("   ✅ File moved successfully")

        // Verify file exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("   ✅ File verified at destination")
        }

        downloadedEpisodes.insert(episodeID)
        print("   ✅ Added to downloadedEpisodes set")
        print("   Total downloads: \(downloadedEpisodes.count)")

        if let metadata = pendingMetadata[episodeID] {
            episodeMetadata[episodeID] = metadata
            print("   ✅ Metadata saved")
        } else {
            print("   ⚠️ No pending metadata found!")
        }

        saveDownloadedEpisodes()
        print("   ✅ Saved to UserDefaults")
    } catch {
        print("   ❌ ERROR: \(error)")
    }
}
```

#### Fix #2: Verify Settings View Implementation
**Approach**: Ensure Settings properly observes download manager

```swift
// SettingsView.swift
struct DownloadedEpisodesView: View {
    @ObservedObject private var downloadManager = EpisodeDownloadManager.shared

    var body: some View {
        List {
            if downloadManager.downloadedEpisodes.isEmpty {
                Text("No downloaded episodes")
            } else {
                ForEach(Array(downloadManager.downloadedEpisodes), id: \.self) { episodeID in
                    if let metadata = downloadManager.getMetadata(for: episodeID) {
                        DownloadedEpisodeRow(metadata: metadata)
                    } else {
                        Text("Episode ID: \(episodeID) (no metadata)")
                    }
                }
            }
        }
        .onAppear {
            print("📋 Downloaded Episodes View Appeared")
            print("   Total downloads: \(downloadManager.downloadedEpisodes.count)")
            print("   Episode IDs: \(downloadManager.downloadedEpisodes)")
        }
    }
}
```

#### Fix #3: Add File Verification
**Approach**: Verify file actually exists before marking as downloaded

```swift
func urlSession(..., didFinishDownloadingTo location: URL) {
    guard let episodeID = downloadTask.taskDescription,
          let destinationURL = getLocalFileURL(for: episodeID) else {
        return
    }

    do {
        // Move file
        try FileManager.default.moveItem(at: location, to: destinationURL)

        // VERIFY file exists
        guard FileManager.default.fileExists(atPath: destinationURL.path) else {
            print("❌ File move reported success but file doesn't exist!")
            return
        }

        // Get file size
        let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        print("   ✅ File size: \(fileSize) bytes")

        // Only mark as downloaded if file verified
        DispatchQueue.main.async {
            self.downloadedEpisodes.insert(episodeID)
            // ... rest
        }
    } catch {
        print("❌ Error: \(error)")
    }
}
```

#### Fix #4: Fix Destination Path Generation
**Approach**: Ensure `getLocalFileURL` returns valid path

```swift
func getLocalFileURL(for episodeID: String) -> URL? {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let episodesFolder = documentsPath.appendingPathComponent("episodes", isDirectory: true)

    // Create folder if doesn't exist
    if !FileManager.default.fileExists(atPath: episodesFolder.path) {
        try? FileManager.default.createDirectory(at: episodesFolder, withIntermediateDirectories: true)
    }

    // IMPORTANT: Sanitize episodeID for use as filename
    // Episode ID might be full URL which is invalid filename
    let sanitizedID = episodeID
        .addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? episodeID
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: ":", with: "_")
        .prefix(200) // Limit filename length

    return episodesFolder.appendingPathComponent("\(sanitizedID).mp3")
}
```

**Why This Matters**:
- Episode ID = audioURL (full HTTP URL)
- Using full URL as filename = invalid path
- `moveItem` fails
- Download never persists

#### Fix #5: Add Download Verification UI
**Approach**: Add debug button to verify downloads

```swift
// In SettingsView
Button("Verify Downloads") {
    let manager = EpisodeDownloadManager.shared
    print("=== DOWNLOAD VERIFICATION ===")
    print("In-memory count: \(manager.downloadedEpisodes.count)")
    print("Episode IDs: \(manager.downloadedEpisodes)")

    for episodeID in manager.downloadedEpisodes {
        if let fileURL = manager.getLocalFileURL(for: episodeID) {
            let exists = FileManager.default.fileExists(atPath: fileURL.path)
            print("  \(episodeID): \(exists ? "EXISTS" : "MISSING")")

            if exists {
                let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
                let size = attrs?[.size] as? Int64 ?? 0
                print("    Size: \(size) bytes")
            }
        }
    }
}
```

---

## Summary

### Bug #5 (Episodes Never Load):
**Most Likely**: Podcast ID mismatch causing early return in `handleRecentEpisodeTap`
**Best Fix**: Use `.sheet(item:)` with direct episode/podcast data passing

### Bug #6 (Downloads Not Persisting):
**Most Likely**: Episode ID (full URL) being used as filename causing file move to fail
**Best Fix**: Sanitize episode ID when creating file paths + add verification logging
