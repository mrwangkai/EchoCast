CARPLAY CRASH FIX — add to echocast_todo.md Inbox as a new ticket, then implement
Files to edit: EchoNotes/CarPlay/CarPlaySceneDelegate.swift and EchoNotes/CarPlay/CarPlayNowPlayingController.swift only. Do not touch SwiftUI views, player files, or Core Data models.

Fix 1: Actually start playback when a row is tapped
This is the primary crash cause. handleEpisodeTap pushes CPNowPlayingTemplate but never loads or plays an episode. Fix it:
First, check what type item is in handleEpisodeTap(item:). If it already carries the episode data needed to call GlobalPlayerManager.shared.loadEpisode(), use it directly. If item is only a CPListItem with text, look up the matching episode from PlaybackHistoryManager.shared.recentlyPlayed by title.
Then inside handleEpisodeTap, before pushing CPNowPlayingTemplate:
GlobalPlayerManager.shared.loadEpisode(episode, podcast: podcast)
GlobalPlayerManager.shared.play()

Use whatever the correct method signatures are on GlobalPlayerManager — do not invent new methods. Read GlobalPlayerManager.swift to confirm the exact API before writing this call.

Fix 2: Guard against uninitialized AVPlayer on cold CarPlay launch
GlobalPlayerManager.shared always exists, but its internal player (AVPlayer) and currentEpisode are nil until loadEpisode() is called. CarPlayNowPlayingController.setup() subscribes to $currentEpisode via Combine — that's safe since it's just observing a @Published optional.
The risk is in buildRecentlyPlayedTemplate() accessing PlaybackHistoryManager.shared.recentlyPlayed on cold start before Core Data is ready. Wrap that access defensively:
let episodes = PlaybackHistoryManager.shared.recentlyPlayed ?? []

If recentlyPlayed is non-optional, check whether it can return an empty array safely before Core Data loads. If it force-unwraps a Core Data context internally, add a do/catch or verify the persistence controller is initialized before calling it. Read PlaybackHistoryManager.swift to confirm — do not guess.

Sequence:

1. Add ticket to echocast_todo.md Inbox
2. Read GlobalPlayerManager.swift to confirm loadEpisode and play method signatures
3. Read PlaybackHistoryManager.swift to check if recentlyPlayed is crash-safe on cold start
4. Implement Fix 1
5. Implement Fix 2 only if the audit shows cold-start access is unsafe
6. Do not modify any files outside EchoNotes/CarPlay/