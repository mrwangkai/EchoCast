import CarPlay
import Combine
import CoreData

class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {

    private var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        CarPlayNowPlayingController.shared.setup(interfaceController: interfaceController)

        let listTemplate = buildRecentlyPlayedTemplate()
        interfaceController.setRootTemplate(listTemplate, animated: false, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        CarPlayNowPlayingController.shared.teardown()
        self.interfaceController = nil
    }

    private func buildRecentlyPlayedTemplate() -> CPListTemplate {
        let history = PlaybackHistoryManager.shared.recentlyPlayed.prefix(10)

        let items: [CPListItem] = history.map { item in
            let listItem = CPListItem(
                text: item.episodeTitle,
                detailText: item.podcastTitle
            )
            listItem.handler = { [weak self] _, completion in
                self?.handleEpisodeTap(item: item)
                completion()
            }
            return listItem
        }

        let section: CPListSection
        if items.isEmpty {
            let emptyItem = CPListItem(text: "No recent episodes", detailText: nil)
            section = CPListSection(items: [emptyItem])
        } else {
            section = CPListSection(items: items)
        }

        let template = CPListTemplate(title: "EchoCast", sections: [section])
        return template
    }

    private func handleEpisodeTap(item: PlaybackHistoryItem) {
        // Load into GlobalPlayerManager and push Now Playing
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Fetch podcast from Core Data using podcastID
            let context = PersistenceController.shared.container.viewContext
            let fetchRequest: NSFetchRequest<PodcastEntity> = PodcastEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", item.podcastID)
            fetchRequest.fetchLimit = 1

            do {
                let podcasts = try context.fetch(fetchRequest)
                guard let podcast = podcasts.first else {
                    print("❌ [CarPlay] Podcast not found for ID: \(item.podcastID)")
                    return
                }

                // Construct RSSEpisode from PlaybackHistoryItem
                let episode = RSSEpisode(
                    title: item.episodeTitle,
                    description: nil,
                    pubDate: nil,
                    duration: self.formatDuration(item.duration),
                    audioURL: item.audioURL,
                    imageURL: podcast.artworkURL
                )

                // Load and play the episode
                GlobalPlayerManager.shared.loadEpisodeAndPlay(episode, podcast: podcast, seekTo: item.currentTime)

                // Push CPNowPlayingTemplate
                CPNowPlayingTemplate.shared.isUpNextButtonEnabled = false
                CPNowPlayingTemplate.shared.isAlbumArtistButtonEnabled = false
                self.interfaceController?.pushTemplate(
                    CPNowPlayingTemplate.shared,
                    animated: true,
                    completion: nil
                )
            } catch {
                print("❌ [CarPlay] Failed to fetch podcast: \(error)")
            }
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let mins = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }
}
