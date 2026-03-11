TASK: T57 — Restore Continue Listening and MiniPlayer after app termination

Reference: echocast_todo.md (mark T57 in-progress)

Branch: branch t57-continue-listening-disappears

## Context
After iOS terminates the app, GlobalPlayerManager.currentEpisode is nil on relaunch.
HomeView line 112 and ContentView's tabViewBottomAccessory both gate on currentEpisode != nil,
so Continue Listening and the mini player vanish even though PlaybackHistoryManager has valid data.

The fix has two parts:
1. Rehydrate GlobalPlayerManager on launch from the most recent history item (no auto-play)
2. Fix the HomeView section guard so it also shows when history data exists (independent of in-memory player state)

## PART 1: Add rehydration to GlobalPlayerManager

File: EchoNotes/Managers/GlobalPlayerManager.swift

### Step A — Add a restoreLastPlayedEpisode() method

After the existing init() body (lines 38-43), add this method.
Do NOT call play() — only set currentEpisode, currentPodcast, and currentTime.
```swift
func restoreLastPlayedEpisode() {
    let history = PlaybackHistoryManager.shared.recentlyPlayed
    guard let mostRecent = history.first(where: { !$0.isFinished }) else {
        print("🏠 [T57] No unfinished history to restore")
        return
    }

    print("🏠 [T57] Restoring last played: \(mostRecent.episodeTitle)")

    // Reconstruct RSSEpisode from persisted history fields
    let episode = RSSEpisode(
        title: mostRecent.episodeTitle,
        audioURL: mostRecent.audioURL,
        description: nil,
        pubDate: nil,
        duration: mostRecent.duration > 0 ? formatDuration(mostRecent.duration) : nil,
        episodeNumber: nil,
        artworkURL: mostRecent.artworkURL
    )

    // Fetch the PodcastEntity from Core Data by podcastID
    let context = PersistenceController.shared.container.viewContext
    let fetchRequest: NSFetchRequest<PodcastEntity> = PodcastEntity.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "id == %@", mostRecent.podcastID)
    fetchRequest.fetchLimit = 1

    var podcastEntity: PodcastEntity?
    do {
        let results = try context.fetch(fetchRequest)
        podcastEntity = results.first
    } catch {
        print("❌ [T57] Failed to fetch PodcastEntity: \(error)")
    }

    // If no Core Data match, construct a minimal PodcastEntity stub
    if podcastEntity == nil {
        let stub = PodcastEntity(context: context)
        stub.id = mostRecent.podcastID
        stub.title = mostRecent.podcastTitle
        stub.artworkUrl600 = mostRecent.artworkURL
        podcastEntity = stub
        // Do NOT save context — this is a transient stub
    }

    guard let podcast = podcastEntity else {
        print("❌ [T57] Could not construct podcast for restoration")
        return
    }

    // Restore state WITHOUT playing
    DispatchQueue.main.async {
        self.currentEpisode = episode
        self.currentPodcast = podcast
        self.currentTime = mostRecent.currentTime
        self.duration = mostRecent.duration
        print("✅ [T57] Restored — episode: \(episode.title ?? "?"), time: \(Int(mostRecent.currentTime))s")
    }
}
```

### Step B — Check what RSSEpisode's init signature looks like before writing

Run: grep -n "init\|struct RSSEpisode\|var title\|var audioURL\|var artworkURL\|var duration" EchoNotes/Models/RSSFeedParser.swift | head -30

Adjust the RSSEpisode constructor fields to match the actual struct definition exactly. Only use fields that exist on the struct.

### Step C — Add a formatDuration helper if not already present

Check: grep -n "func formatDuration" EchoNotes/Managers/GlobalPlayerManager.swift

If missing, add:
```swift
private func formatDuration(_ seconds: TimeInterval) -> String {
    let mins = Int(seconds) / 60
    let secs = Int(seconds) % 60
    return String(format: "%d:%02d", mins, secs)
}
```

### Step D — Call restoreLastPlayedEpisode() from EchoNotesApp

File: EchoNotes/EchoNotesApp.swift

Find the App struct's init() or the first .onAppear on the root view.
Add the call AFTER the app has fully initialized (not before PersistenceController is ready):

Option A — in App init():
```swift
init() {
    // ... existing init code ...
    GlobalPlayerManager.shared.restoreLastPlayedEpisode()
}
```

Option B — in ContentView's .onAppear if App init() is unavailable:
```swift
.onAppear {
    GlobalPlayerManager.shared.restoreLastPlayedEpisode()
}
```

Check which pattern already exists: grep -n "init\|onAppear\|GlobalPlayerManager" EchoNotes/EchoNotesApp.swift | head -20

Use whichever is cleaner. Do NOT add a second .onAppear if one already exists — add the line inside the existing one.

---

## PART 2: Fix HomeView section guard

File: EchoNotes/Views/HomeView.swift

### Find line 112:
```swift
if player.currentEpisode != nil || !recentNotes.isEmpty {
    continueListeningSection
}
```

### Replace with:
```swift
if player.currentEpisode != nil || !continueListeningEpisodes.isEmpty || !recentNotes.isEmpty {
    continueListeningSection
}
```

This ensures the section is visible from history data alone, even before the player is rehydrated. It's a belt-and-suspenders fix on top of Part 1.

Confirm that `continueListeningEpisodes` is already declared in HomeView (it should be, from lines 53-65 per the diagnosis). If the property name is different, use the correct name.

---

## PART 3: Verify PlaybackHistoryItem field names

Before writing any code, run: