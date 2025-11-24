# 🛠️ Recommended Code Fixes for Podcast App Bugs

This document outlines the high-priority fixes for Bug #5 (Episodes Never Load) and Bug #6 (Downloads Not Persisting), based on the provided analysis.

## 🐞 Bug #5: Episodes Never Load (Stuck on "Loading...")

The root cause is a **race condition** and complex state management using multiple `DispatchQueue.main.async` calls, coupled with a highly likely **Podcast ID mismatch**.

### Fix 1: Implement Direct Data Passing (Eliminating Race Conditions)

We will switch from using a separate boolean (`showRecentEpisodePlayer`) and optional data variables to a single, optional state variable that holds all necessary data. This uses the `.sheet(item:)` modifier, which automatically handles presentation when the variable is non-nil.

#### 1. Update State Variables (`ContentView.swift` - near line 356)

Replace the old state variables for the sheet with this single, new one.

```swift
// Remove these (or similar):
// @State private var selectedRecentEpisode: RSSEpisode? = nil
// @State private var selectedRecentPodcast: PodcastEntity? = nil
// @State private var showRecentEpisodePlayer = false

// Add this new combined state variable:
@State private var recentEpisodeSheetData: (episode: RSSEpisode, podcast: PodcastEntity, timestamp: TimeInterval)? = nil

2. Update Tap Handler (ContentView.swift - near line 602 - handleRecentEpisodeTap)

Replace the old implementation of handleRecentEpisodeTap with this synchronous logic. (Note: This assumes you implement the findPodcast helper function from Fix 2).

private func handleRecentEpisodeTap(_ item: PlaybackHistoryItem) {
    // 1. Find podcast (Use the resilient lookup helper)
    guard let podcast = findPodcast(for: item) else {
        print("❌ Could not find podcast with ID: \(item.podcastID). Showing error to user.")
        // TODO: Implement user alert here (or error message notification)
        return
    }

    // 2. Create episode from history item (Synchronously)
    let episode = RSSEpisode(
        title: item.episodeTitle,
        audioURL: item.audioURL,
        // ... include all required fields for RSSEpisode initialization
        pubDate: item.pubDate // Assuming this is available
    )

    // 3. Set the single state variable to trigger the sheet presentation
    self.recentEpisodeSheetData = (episode, podcast, item.currentTime)
}

3. Update Sheet Presentation (ContentView.swift - near end of body)

Replace the recentEpisodePlayerSheet view and its usage with a simple .sheet(item:) modifier.

// REMOVE the entire private var recentEpisodePlayerSheet: some View { ... } block

// Add the sheet modifier to the root view (or main ZStack/VStack)
.sheet(item: $recentEpisodeSheetData) { data in
    PlayerSheetWrapper(
        episode: data.episode,
        podcast: data.podcast,
        dismiss: { recentEpisodeSheetData = nil }, // Clears data to dismiss sheet
        seekToTime: data.timestamp
    )
}

Fix 2: Implement Resilient Podcast Lookup

This helper function should be placed in ContentView.swift or your relevant data manager to make the lookup resilient against ID changes/mismatches.

private func findPodcast(for historyItem: PlaybackHistoryItem) -> PodcastEntity? {
    // 1. Try ID match (Primary method)
    if let podcast = podcasts.first(where: { $0.id == historyItem.podcastID }) {
        return podcast
    }

    // 2. Fallback: Try feedURL match (More stable identifier)
    if let feedURL = historyItem.podcastFeedURL,
       let podcast = podcasts.first(where: { $0.feedURL == feedURL }) {
        print("⚠️ Found podcast by feedURL match (ID mismatch for \(historyItem.episodeTitle))")
        return podcast
    }

    // 3. Fallback: Try title match (Least reliable, but better than nothing)
    if let podcast = podcasts.first(where: { $0.title == historyItem.podcastTitle }) {
        print("⚠️ Found podcast by title match (ID mismatch for \(historyItem.episodeTitle))")
        return podcast
    }

    return nil
}

Bug #6: Downloads Not Persisting

The root cause is likely the Episode ID (a full URL) being used as an invalid filename, causing the file move operation to fail silently.

Fix 4: Sanitize Episode ID for File Path Generation

The function responsible for creating the local file URL needs to be updated to ensure the filename is valid and safe for the file system.

1. Update Path Generation (GlobalPlayerManager.swift or relevant Download Manager)

Modify the getLocalFileURL(for:) function to include sanitization logic.

func getLocalFileURL(for episodeID: String) -> URL? {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let episodesFolder = documentsPath.appendingPathComponent("episodes", isDirectory: true)

    // Ensure the folder exists
    if !FileManager.default.fileExists(atPath: episodesFolder.path) {
        // Use do/catch here if you want to log failure, but try? is often fine for setup
        try? FileManager.default.createDirectory(at: episodesFolder, withIntermediateDirectories: true)
    }

    // ⭐ IMPORTANT: Sanitize episodeID which is likely a full URL
    // 1. Replace illegal path characters
    // 2. Use base64 encoding or SHA hashing for complex IDs if replacing fails
    let sanitizedID = episodeID
        // Replace URL-specific characters with underscores
        .replacingOccurrences(of: "https://", with: "")
        .replacingOccurrences(of: "http://", with: "")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: ":", with: "_")
        .replacingOccurrences(of: "?", with: "_")
        .replacingOccurrences(of: "=", with: "_")
        .replacingOccurrences(of: "&", with: "_")
        // Ensure path length limit is respected (optional but good practice)
        .prefix(200)

    // Ensure we still have a valid string
    let finalFileName = String(sanitizedID)
    if finalFileName.isEmpty { return nil } // Guard against empty filename

    return episodesFolder.appendingPathComponent("\(finalFileName).mp3")
}

Fix 1: Add Comprehensive Logging and Verification

Insert extensive logging into the download completion delegate method (urlSession(..., didFinishDownloadingTo location: URL)) to confirm that the file move succeeded and the state was saved.

2. Update Download Completion Logic (GlobalPlayerManager.swift - urlSession(..., didFinishDownloadingTo))

func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard let episodeID = downloadTask.taskDescription,
          let destinationURL = getLocalFileURL(for: episodeID) else {
        print("❌ DOWNLOAD ERROR: Task description or destination URL failed for unknown download.")
        return
    }

    print("📥 DOWNLOAD FINISHED for ID: \(episodeID)")
    print("   Destination URL: \(destinationURL.path)")

    do {
        // Attempt to move file
        try FileManager.default.moveItem(at: location, to: destinationURL)
        print("   ✅ File moved successfully.")

        // VERIFY file exists and has size
        let attributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0

        guard fileSize > 0 else {
            print("   ❌ CRITICAL: File move succeeded but file size is zero!")
            // Clean up: delete file and don't mark as downloaded
            try? FileManager.default.removeItem(at: destinationURL)
            return
        }

        print("   ✅ File verified at destination with size: \(fileSize) bytes.")

        // Update state on the main thread (Crucial for state changes)
        DispatchQueue.main.async {
            self.downloadedEpisodes.insert(episodeID)
            self.downloadProgress.removeValue(forKey: episodeID)

            if let metadata = self.pendingMetadata[episodeID] {
                self.episodeMetadata[episodeID] = metadata
                self.saveEpisodeMetadata()
            }
            
            self.saveDownloadedEpisodes() // Saves the updated set to UserDefaults
            print("   ✅ State and UserDefaults updated successfully.")
        }
        
    } catch {
        print("   ❌ ERROR moving downloaded file for \(episodeID): \(error)")
        // Ensure UI reflects failed state if possible
    }
}
