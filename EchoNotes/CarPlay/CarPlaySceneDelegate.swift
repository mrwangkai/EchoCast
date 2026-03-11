import CarPlay
import Combine
import CoreData

class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {

    private var interfaceController: CPInterfaceController?
    private var imageCache: [String: UIImage] = [:]

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        CarPlayNowPlayingController.shared.setup(interfaceController: interfaceController)

        let tabBarTemplate = CPTabBarTemplate(templates: [buildHomeTemplate(), buildMyPodcastsTemplate()])
        interfaceController.setRootTemplate(tabBarTemplate, animated: false, completion: nil)
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatDurationText(_ duration: TimeInterval, isPlaying: Bool) -> String {
        if isPlaying {
            return "Playing"
        }
        let hours = Int(duration) / 3600
        let mins = Int(duration) / 60 % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        } else {
            return "\(mins)m"
        }
    }

    // MARK: - Home Template

    private func buildHomeTemplate() -> CPListTemplate {
        let history = Array(PlaybackHistoryManager.shared.recentlyPlayed)
        guard !history.isEmpty else {
            let emptyItem = CPListItem(text: "No recent episodes", detailText: nil)
            return CPListTemplate(title: "Home", sections: [CPListSection(items: [emptyItem])])
        }

        // Section 1: Continue Listening (most recent 1)
        let continueListeningItem = createEpisodeItem(from: history[0])
        var sections: [CPListSection] = [CPListSection(title: "Continue Listening", items: [continueListeningItem])]

        // Section 2: Latest Episodes (up to 5, excluding the one shown in Continue Listening)
        let remainingEpisodes = Array(history.dropFirst().prefix(5))
        if !remainingEpisodes.isEmpty {
            let latestEpisodesItems = remainingEpisodes.map { createEpisodeItem(from: $0) }
            sections.append(CPListSection(title: "Latest Episodes", items: latestEpisodesItems))
        }

        return CPListTemplate(title: "Home", sections: sections)
    }

    // MARK: - My Podcasts Template

    private func buildMyPodcastsTemplate() -> CPListTemplate {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<PodcastEntity> = PodcastEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isFollowing == YES")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        do {
            let podcasts = try context.fetch(fetchRequest)
            let items = podcasts.map { podcast in
                // Set placeholder image (headphones SF Symbol)
                let placeholderImage = UIImage(systemName: "headphones")
                let listItem = CPListItem(
                    text: podcast.title ?? "Unknown Podcast",
                    detailText: "\(getEpisodeCount(for: podcast)) episodes",
                    image: placeholderImage
                )
                listItem.handler = { [weak self] _, completion in
                    self?.handlePodcastTap(podcast: podcast)
                    completion()
                }
                // Load actual artwork asynchronously
                listItem.listen { [weak self] _ in
                    self?.loadAndCacheImage(urlString: podcast.artworkURL) { image in
                        if let image = image {
                            listItem.update(image)
                        }
                    }
                }
                return listItem
            }

            if items.isEmpty {
                let emptyItem = CPListItem(text: "No followed podcasts", detailText: "Follow podcasts in the app to see them here")
                return CPListTemplate(title: "My Podcasts", sections: [CPListSection(items: [emptyItem])])
            }

            return CPListTemplate(title: "My Podcasts", sections: [CPListSection(items: items)])
        } catch {
            print("❌ [CarPlay] Failed to fetch podcasts: \(error)")
            let errorItem = CPListItem(text: "Error loading podcasts", detailText: nil)
            return CPListTemplate(title: "My Podcasts", sections: [CPListSection(items: [errorItem])])
        }
    }

    // MARK: - Podcast Episodes Template

    private func buildPodcastEpisodesTemplate(podcast: PodcastEntity) -> CPListTemplate {
        let podcastTitle = podcast.title ?? "Podcast"
        let podcastArtworkURL = podcast.artworkURL ?? ""
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<EpisodeEntity> = EpisodeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "podcast == %@", podcast)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "pubDate", ascending: false)]
        fetchRequest.fetchLimit = 10

        do {
            let episodes = try context.fetch(fetchRequest)
            let items = episodes.compactMap { episode -> CPListItem? in
                guard let title = episode.title,
                      let audioURL = episode.audioURL else {
                    return nil
                }

                let item = createPlaybackHistoryItem(from: episode, podcastTitle: podcastTitle, artworkURL: podcastArtworkURL)
                let listItem = createEpisodeItem(from: item)
                return listItem
            }

            if items.isEmpty {
                let emptyItem = CPListItem(text: "No episodes found", detailText: nil)
                return CPListTemplate(title: podcastTitle, sections: [CPListSection(items: [emptyItem])])
            }

            return CPListTemplate(title: podcastTitle, sections: [CPListSection(items: items)])
        } catch {
            print("❌ [CarPlay] Failed to fetch episodes: \(error)")
            let errorItem = CPListItem(text: "Error loading episodes", detailText: nil)
            return CPListTemplate(title: podcastTitle, sections: [CPListSection(items: [errorItem])])
        }
    }

    // MARK: - Helper Methods

    private func createEpisodeItem(from item: PlaybackHistoryItem) -> CPListItem {
        let isPlaying = GlobalPlayerManager.shared.currentEpisode?.id == item.id
        let detailText: String
        if let pubDate = item.lastPlayed {
            detailText = "\(formatDate(pubDate)) · \(formatDurationText(item.duration, isPlaying: isPlaying))"
        } else {
            detailText = formatDurationText(item.duration, isPlaying: isPlaying)
        }

        // Set placeholder image (headphones SF Symbol)
        let placeholderImage = UIImage(systemName: "headphones")
        let listItem = CPListItem(
            text: item.episodeTitle,
            detailText: detailText,
            image: placeholderImage
        )
        listItem.handler = { [weak self] _, completion in
            self?.handleEpisodeTap(item: item)
            completion()
        }
        // Load actual artwork asynchronously
        listItem.listen { [weak self] _ in
            self?.loadAndCacheImage(urlString: item.artworkURL) { image in
                if let image = image {
                    listItem.update(image)
                }
            }
        }
        return listItem
    }

    private func handlePodcastTap(podcast: PodcastEntity) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let episodesTemplate = self.buildPodcastEpisodesTemplate(podcast: podcast)
            self.interfaceController?.pushTemplate(episodesTemplate, animated: true, completion: nil)
        }
    }

    private func getEpisodeCount(for podcast: PodcastEntity) -> String {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<EpisodeEntity> = EpisodeEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "podcast == %@", podcast)

        do {
            let episodes = try context.fetch(fetchRequest)
            return "\(episodes.count)"
        } catch {
            return "0"
        }
    }

    private func createPlaybackHistoryItem(from episode: EpisodeEntity, podcastTitle: String, artworkURL: String = "") -> PlaybackHistoryItem {
        let duration: TimeInterval
        if let durationStr = episode.duration, let durationDouble = Double(durationStr) {
            duration = durationDouble
        } else {
            duration = 0
        }

        return PlaybackHistoryItem(
            id: episode.id ?? UUID().uuidString,
            episodeTitle: episode.title ?? "Unknown Episode",
            podcastTitle: podcastTitle,
            podcastID: episode.podcast?.id ?? "",
            audioURL: episode.audioURL ?? "",
            artworkURL: artworkURL,
            currentTime: 0,
            duration: duration,
            lastPlayed: episode.pubDate ?? Date(),
            isFinished: false
        )
    }

    // MARK: - Async Image Loading

    private func loadAndCacheImage(urlString: String?, completion: @escaping (UIImage?) -> Void) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        // Check cache first
        if let cachedImage = imageCache[urlString] {
            completion(cachedImage)
            return
        }

        // Load image asynchronously
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            DispatchQueue.main.async {
                self?.imageCache[urlString] = image
                completion(image)
            }
        }.resume()
    }
}
