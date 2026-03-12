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

    private func parseDurationString(_ durationString: String?) -> TimeInterval {
        guard let durationString = durationString, !durationString.isEmpty else {
            return 0
        }

        // Parse duration string in formats: "HH:MM:SS" or "MM:SS"
        let components = durationString.split(separator: ":").compactMap { Int($0) }

        switch components.count {
        case 3:
            // HH:MM:SS
            return TimeInterval(components[0] * 3600 + components[1] * 60 + components[2])
        case 2:
            // MM:SS
            return TimeInterval(components[0] * 60 + components[1])
        case 1:
            // Just seconds
            return TimeInterval(components[0])
        default:
            return 0
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
        var sections: [CPListSection] = [CPListSection(items: [continueListeningItem])]

        // Section 2: Latest Episodes (up to 5, excluding the one shown in Continue Listening)
        let remainingEpisodes = Array(history.dropFirst().prefix(5))
        if !remainingEpisodes.isEmpty {
            let latestEpisodesItems = remainingEpisodes.map { createEpisodeItem(from: $0) }
            sections.append(CPListSection(items: latestEpisodesItems))
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
                // Load artwork synchronously (CarPlay doesn't support async image updates)
                var artworkImage: UIImage?
                if let artworkURL = podcast.artworkURL, let url = URL(string: artworkURL) {
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        artworkImage = image
                    }
                }
                let placeholderImage = artworkImage ?? UIImage(systemName: "headphones")

                let listItem = CPListItem(
                    text: podcast.title ?? "Unknown Podcast",
                    detailText: "Followed podcast",
                    image: placeholderImage
                )
                listItem.handler = { [weak self] _, completion in
                    guard let self = self else {
                        completion()
                        return
                    }

                    // (a) Fetch the podcast's RSS feed URL
                    guard let feedURL = podcast.feedURL, !feedURL.isEmpty else {
                        print("❌ [CarPlay] No feed URL for podcast: \(podcast.title ?? "Unknown")")
                        completion()
                        return
                    }

                    // (b) Fetch episodes via RSS
                    Task {
                        do {
                            let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: feedURL)
                            let episodes = rssPodcast.episodes

                            // (c) Build episode list template
                            let episodeItems = episodes.map { episode -> CPListItem in
                                let detailText: String?
                                if let duration = episode.duration {
                                    detailText = duration
                                } else if let pubDate = episode.pubDate {
                                    detailText = self.formatDate(pubDate)
                                } else {
                                    detailText = nil
                                }

                                let item = CPListItem(
                                    text: episode.title,
                                    detailText: detailText
                                )

                                // (d) Episode row handler calls handleEpisodeTap
                                item.handler = { [weak self] _, completion in
                                    guard let self = self else {
                                        completion()
                                        return
                                    }

                                    // Create PlaybackHistoryItem from episode data
                                    let playbackItem = PlaybackHistoryItem(
                                        id: episode.id,
                                        episodeTitle: episode.title,
                                        podcastTitle: podcast.title ?? "Unknown Podcast",
                                        podcastID: podcast.id ?? "",
                                        audioURL: episode.audioURL ?? "",
                                        artworkURL: podcast.artworkURL ?? "",
                                        currentTime: 0,
                                        duration: self.parseDurationString(episode.duration),
                                        lastPlayed: Date(),
                                        isFinished: false
                                    )

                                    self.handleEpisodeTap(item: playbackItem)
                                    completion()
                                }

                                return item
                            }

                            // Create episode list section
                            let episodeSection: CPListSection
                            if episodeItems.isEmpty {
                                let emptyItem = CPListItem(text: "No episodes available", detailText: nil)
                                episodeSection = CPListSection(items: [emptyItem])
                            } else {
                                episodeSection = CPListSection(items: episodeItems)
                            }

                            // Create episode list template with podcast name as title
                            let episodeListTemplate = CPListTemplate(
                                title: podcast.title ?? "Episodes",
                                sections: [episodeSection]
                            )

                            // (e) Push the episode list template
                            await MainActor.run {
                                self.interfaceController?.pushTemplate(
                                    episodeListTemplate,
                                    animated: true,
                                    completion: nil
                                )
                            }

                        } catch {
                            print("❌ [CarPlay] Failed to fetch episodes: \(error)")
                        }
                        completion()
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

    // MARK: - Helper Methods

    private func createEpisodeItem(from item: PlaybackHistoryItem) -> CPListItem {
        let isPlaying = GlobalPlayerManager.shared.currentEpisode?.id == item.id
        // lastPlayed is Date, not Date?, so use it directly
        let detailText: String
        if item.duration > 0 {
            detailText = "\(formatDate(item.lastPlayed)) · \(formatDurationText(item.duration, isPlaying: isPlaying))"
        } else {
            detailText = formatDate(item.lastPlayed)
        }

        // Load artwork synchronously (CarPlay doesn't support async image updates)
        var artworkImage: UIImage?
        if !item.artworkURL.isEmpty, let url = URL(string: item.artworkURL) {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                artworkImage = image
            }
        }
        let placeholderImage = artworkImage ?? UIImage(systemName: "headphones")

        let listItem = CPListItem(
            text: item.episodeTitle,
            detailText: detailText,
            image: placeholderImage
        )
        listItem.handler = { [weak self] _, completion in
            self?.handleEpisodeTap(item: item)
            completion()
        }
        return listItem
    }
}
