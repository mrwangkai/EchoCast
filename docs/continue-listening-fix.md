TASK: Fix "Continue Listening" not updating when player is minimized

CONTEXT: 
HomeView uses @State var continueListeningEpisodes (local copy) and only 
refreshes on .onAppear, podcast count changes, or episode ID changes. 
PlaybackHistoryManager.shared.recentlyPlayed IS @Published but HomeView 
never observes it, so changes from savePlaybackHistory() are invisible to HomeView.

CHANGE ONLY: HomeView.swift

STEP 1 - Add ObservedObject for PlaybackHistoryManager
Find the existing property declarations near the top of HomeView (around line 38 
where @ObservedObject private var player = GlobalPlayerManager.shared lives).

Add:
@ObservedObject private var historyManager = PlaybackHistoryManager.shared

STEP 2 - Remove the manual @State copy
Remove this line:
@State private var continueListeningEpisodes: [(historyItem: PlaybackHistoryItem, podcast: PodcastEntity)] = []

STEP 3 - Update loadContinueListeningEpisodes() to write to a local computed result
The function currently populates the @State array. We need to keep the 
PodcastEntity lookup logic (matching history items to Core Data podcasts) 
but store the result differently.

Replace the @State array with a computed property or keep a private helper, 
whichever compiles cleanly. The goal: anywhere continueListeningEpisodes is 
read in the view, it should now derive from historyManager.recentlyPlayed 
so SwiftUI re-renders automatically when recentlyPlayed changes.

Suggested approach — add a computed property:
private var continueListeningEpisodes: [(historyItem: PlaybackHistoryItem, podcast: PodcastEntity)] {
    let historyItems = historyManager.recentlyPlayed.prefix(5)
    return historyItems.compactMap { item in
        // match to PodcastEntity from allPodcasts using existing lookup logic
        guard let podcast = allPodcasts.first(where: { 
            $0.id == item.podcastID || $0.feedURL == item.podcastFeedURL 
        }) else { return nil }
        return (historyItem: item, podcast: podcast)
    }
}

Adapt the field names to match the actual PlaybackHistoryItem and PodcastEntity 
properties — check these in the existing loadContinueListeningEpisodes() 
implementation and replicate the exact matching logic.

STEP 4 - Remove the now-redundant refresh triggers
Remove or simplify:
- The loadContinueListeningEpisodes() function body (or delete it entirely)
- The .onChange(of: player.currentEpisode?.id) that called it
- The .onAppear call to loadContinueListeningEpisodes()
- The .onChange(of: allPodcasts.count) call to it

Keep .onAppear if it does anything else besides loading continue listening data.

STEP 5 - Verify
After changes, the Continue Listening section should use continueListeningEpisodes 
(now a computed property) everywhere it was used before. No other files should need 
to change.

Build and confirm no compiler errors. Do not change any other files.
