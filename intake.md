CARPLAY UI REDESIGN — branch: t55-carplay-ui-redesign
Create branch t55-carplay-ui-redesign from current main. Add a new ticket to echocast_todo.md Inbox for this work.
Edit EchoNotes/CarPlay/CarPlaySceneDelegate.swift only. Do not touch CarPlayNowPlayingController.swift, any SwiftUI views, or Core Data models.

Goal: Replace the current single CPListTemplate with a CPTabBarTemplate containing two tabs: Home and My Podcasts.

Tab 1 — Home
Replace buildRecentlyPlayedTemplate() with a new method buildHomeTemplate() -> CPListTemplate that returns a list with two sections:
Section 1 — "Continue Listening": the most recent 1 episode from PlaybackHistoryManager.shared.recentlyPlayed (the episode currently in progress or last played).
Section 2 — "Latest Episodes": up to 5 recent episodes from PlaybackHistoryManager.shared.recentlyPlayed, skipping the one already shown in Continue Listening.
Each CPListItem should be built with:

text: episode title
detailText: formatted string combining publication date + duration, e.g. "Mar 10, 2026 · 3h 3m". Use the episode's pubDate (formatted as MMM d, yyyy) and duration. If an episode is currently playing (GlobalPlayerManager.shared.currentEpisode?.id == episode.id), append " · Playing" instead of duration.
image: series artwork loaded from the episode's podcast artworkURL. Use CPListItem's image parameter. Load asynchronously with URLSession and update the item via CPListItem.update(_:) after the image downloads. Use a placeholder SF Symbol (headphones) while loading.

Keep the existing tap handler pattern (push CPNowPlayingTemplate + trigger playback).

Tab 2 — My Podcasts
New method buildMyPodcastsTemplate() -> CPListTemplate.
Fetch followed podcasts from Core Data. Use the existing PersistenceController.shared.container.viewContext to fetch PodcastEntity objects — filter to only those where isFollowing == true (or whatever the follow flag is called on PodcastEntity — read the model before assuming the property name).
Each CPListItem:

text: podcast series title
detailText: episode count, e.g. "12 episodes"
image: series artwork, same async loading pattern as above

Tapping a podcast row should push a new CPListTemplate showing that podcast's recent episodes (fetch from Core Data EpisodeEntity where podcast == selectedPodcast, limit 10, sorted by pubDate descending). Each episode item in that drill-down uses the same text/detailText/image format as the Home tab. Tapping an episode starts playback.

Tab bar assembly
swiftlet tabBarTemplate = CPTabBarTemplate(templates: [homeTemplate, myPodcastsTemplate])
interfaceController.setRootTemplate(tabBarTemplate, animated: false, completion: nil)
Set tabBarTemplate as the root in didConnect, replacing the current setRootTemplate call.

Important constraints:

Read PodcastEntity and EpisodeEntity Core Data model properties before referencing any field names — do not guess property names
Read PlaybackHistoryManager.swift to understand the recentlyPlayed data type before using it
Read GlobalPlayerManager.swift to confirm the playback trigger API
Do not modify any file outside CarPlaySceneDelegate.swift
Do not restructure or rename existing methods — add new ones alongside
Commit with message: t55-carplay-ui-redesign: CPTabBarTemplate with Home and My Podcasts tabs