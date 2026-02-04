# Phase 2: Create Model Adapter

## Purpose
Convert iTunes search results (`PodcastEpisode`, `iTunesPodcast`) into RSS/Core Data models (`RSSEpisode`, `PodcastEntity`) so we can use `EpisodePlayerView` everywhere.

## Step 1: Create ModelAdapter.swift

**Create new file:** `/Services/ModelAdapter.swift`

```swift
//
//  ModelAdapter.swift
//  EchoNotes
//
//  Converts iTunes API models to RSS/Core Data models
//

import Foundation
import CoreData

// MARK: - Model Adapter

class ModelAdapter {
    static let shared = ModelAdapter()
    
    private let rssService = PodcastRSSService()
    private let persistence = PersistenceController.shared
    
    // MARK: - Main Conversion Function
    
    /// Convert iTunes search result to RSS/Core Data models
    func convertToRSSModels(
        episode: PodcastEpisode,
        podcast: iTunesPodcast
    ) async throws -> (RSSEpisode, PodcastEntity) {
        
        // 1. Get feed URL from iTunes podcast
        guard let feedURL = podcast.feedUrl, !feedURL.isEmpty else {
            throw ModelAdapterError.missingFeedURL
        }
        
        // 2. Parse RSS feed to get episodes
        let (podcastInfo, episodes) = try await rssService.parseFeed(from: feedURL)
        
        // 3. Find matching episode by title (case-insensitive)
        let episodeTitle = episode.trackName ?? ""
        guard let rssEpisode = episodes.first(where: { rssEp in
            rssEp.title.lowercased().contains(episodeTitle.lowercased()) ||
            episodeTitle.lowercased().contains(rssEp.title.lowercased())
        }) else {
            // If no exact match, return first episode
            guard let firstEpisode = episodes.first else {
                throw ModelAdapterError.noEpisodesFound
            }
            print("⚠️ No exact match for '\(episodeTitle)', using first episode: '\(firstEpisode.title)'")
            return try await (firstEpisode, getOrCreatePodcastEntity(from: podcast, feedURL: feedURL, podcastInfo: podcastInfo))
        }
        
        // 4. Get or create PodcastEntity in Core Data
        let podcastEntity = try await getOrCreatePodcastEntity(
            from: podcast,
            feedURL: feedURL,
            podcastInfo: podcastInfo
        )
        
        return (rssEpisode, podcastEntity)
    }
    
    // MARK: - Core Data Helper
    
    /// Get existing podcast from Core Data or create new one
    private func getOrCreatePodcastEntity(
        from iTunesPodcast: iTunesPodcast,
        feedURL: String,
        podcastInfo: (title: String, description: String?, imageURL: String?, author: String?)?
    ) async throws -> PodcastEntity {
        
        let context = persistence.container.viewContext
        
        return await context.perform {
            // Try to find existing podcast by feed URL
            let fetchRequest: NSFetchRequest<PodcastEntity> = PodcastEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "feedURL == %@", feedURL)
            fetchRequest.fetchLimit = 1
            
            if let existing = try? context.fetch(fetchRequest).first {
                return existing
            }
            
            // Create new podcast entity
            let newPodcast = PodcastEntity(context: context)
            newPodcast.id = iTunesPodcast.collectionId.description
            newPodcast.title = podcastInfo?.title ?? iTunesPodcast.collectionName
            newPodcast.author = podcastInfo?.author ?? iTunesPodcast.artistName
            newPodcast.podcastDescription = podcastInfo?.description
            newPodcast.artworkURL = podcastInfo?.imageURL ?? iTunesPodcast.artworkUrl600
            newPodcast.feedURL = feedURL
            newPodcast.dateAdded = Date()
            
            // Save context
            do {
                try context.save()
                print("✅ Created new PodcastEntity: \(newPodcast.title ?? "")")
            } catch {
                print("❌ Failed to save PodcastEntity: \(error)")
            }
            
            return newPodcast
        }
    }
}

// MARK: - Errors

enum ModelAdapterError: LocalizedError {
    case missingFeedURL
    case noEpisodesFound
    case conversionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .missingFeedURL:
            return "Podcast is missing RSS feed URL"
        case .noEpisodesFound:
            return "No episodes found in RSS feed"
        case .conversionFailed(let reason):
            return "Conversion failed: \(reason)"
        }
    }
}
```

## Step 2: Add ModelAdapter to Xcode Project

1. **Right-click on `/Services/` folder in Xcode Project Navigator**
2. **New File... → Swift File**
3. **Name it: `ModelAdapter.swift`**
4. **Paste the code above**
5. **Ensure Target: "EchoNotes" is checked**
6. **Save**

## Step 3: Test the Adapter (Optional)

Add this test helper to verify the adapter works:

```swift
// In ModelAdapter.swift, add this at the bottom

#if DEBUG
extension ModelAdapter {
    /// Test conversion with a sample podcast
    func testConversion() async {
        // Example: Convert a sample iTunes podcast
        let samplePodcast = iTunesPodcast(
            collectionId: 1535809341,
            collectionName: "The Daily",
            artistName: "The New York Times",
            feedUrl: "https://feeds.simplecast.com/54nAGcIl",
            artworkUrl600: "https://example.com/artwork.jpg",
            genreIds: ["1489"],
            primaryGenreName: "News"
        )
        
        let sampleEpisode = PodcastEpisode(
            trackId: 123,
            trackName: "Sample Episode",
            releaseDate: "2024-01-01",
            trackTimeMillis: 3600000
        )
        
        do {
            let (rssEpisode, podcastEntity) = try await convertToRSSModels(
                episode: sampleEpisode,
                podcast: samplePodcast
            )
            print("✅ Conversion successful!")
            print("   RSS Episode: \(rssEpisode.title)")
            print("   Podcast: \(podcastEntity.title ?? "")")
        } catch {
            print("❌ Conversion failed: \(error)")
        }
    }
}
#endif
```

## Verification

After creating `ModelAdapter.swift`:

1. **Build the project** (`Cmd + B`)
2. **Check for errors** - Should compile successfully
3. **No need to test yet** - We'll test in Phase 4 when integrating

---

## What We Built

The `ModelAdapter` does three things:

1. **Takes iTunes models** → Fetches RSS feed from `feedUrl`
2. **Finds matching episode** → Compares titles to find the right episode
3. **Creates/fetches Core Data entity** → Returns `PodcastEntity` for persistence

This allows ContentView (which uses iTunes search) to seamlessly work with `EpisodePlayerView` (which expects RSS models).

---

## Next Step
Proceed to **Phase 3: Create RSS-based AddNoteSheet**
