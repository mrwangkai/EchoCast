// this is from claude.ai on how to connect the existing data in your app to this new component (https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1696-3902&t=SU77v8sJhvfLAWBE-4). Let me create a clear specification for Claude Code

Please create an integration layer to connect the existing app data to the new ContinueListeningCard component.

Reference Figma design: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1696-3902&t=SU77v8sJhvfLAWBE-4

Current Situation:
- We have a working ContinueListeningCard component (ContinueListeningCard.swift)
- We have existing data models: DownloadedEpisode, RSSEpisode, PodcastEpisode
- We need to map these to ContinueListeningEpisode for display

Tasks:

1. Create data mapping extensions in a new file: ContinueListeningCard+DataMapping.swift

Add these extensions:

a) Extension for DownloadedEpisode → ContinueListeningEpisode
   - Map title, podcastName, artworkUrl, progress, audioUrl
   - Calculate notesCount by querying Core Data for notes matching this episode
   - Calculate timeRemaining from duration and progress
   - Handle edge cases (nil values, missing data)

b) Extension for RSSEpisode → ContinueListeningEpisode
   - Similar mapping but from RSS data
   - Get progress from PlaybackHistoryManager
   - Get notesCount from Core Data

c) Helper function to query notes count:
   - Query NoteEntity where episodeTitle matches
   - Return count

2. Update HomeView.swift to use the new component:

In the "Continue Playing Section" (around line 228):
- Replace ContinuePlayingCard with ContinueListeningCard
- Use the extension methods to convert DownloadedEpisode to ContinueListeningEpisode
- Wire up onTap and onPlayTap actions to existing sheet presentation

Example usage should be:
```swift
ForEach(downloadedEpisodes) { episode in
    ContinueListeningCard(
        episode: episode.toContinueListeningEpisode(),
        onTap: {
            selectedEpisode = episode
            showPlayerSheet = true
        },
        onPlayTap: {
            // Existing play logic
        }
    )
    .frame(width: 327)
}
```

3. Ensure the conversion handles:
   - Notes count: Query Core Data for notes matching episode title
   - Time remaining: Format as "MM:SS left" or "H:MM:SS left"
   - Progress: Convert from 0.0-1.0 range
   - Missing artwork: Return nil so placeholder shows

Reference these existing files:
- HomeView.swift (lines 228-242) for current implementation
- PlaybackHistoryManager.swift for progress data
- PersistenceController.swift for notes queries
- TimeIntervalFormatting.swift for time formatting

Build and ensure no errors. The Continue Playing section should now use the new pixel-perfect card design.
