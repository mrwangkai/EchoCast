//
//  PodcastRSSService.swift
//  EchoNotes
//
//  RSS feed parser for podcast feeds with thumbnail extraction
//

import Foundation
import UIKit

struct RSSPodcast: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let author: String?
    let imageURL: String?
    let feedURL: String
    let episodes: [RSSEpisode]
}

struct RSSEpisode: Identifiable {
    var id: String {
        // Use audio URL as stable identifier, fallback to title hash
        if let audioURL = audioURL, !audioURL.isEmpty {
            return audioURL
        } else {
            return title.hashValue.description
        }
    }

    let title: String
    let description: String?
    let pubDate: Date?
    let duration: String?
    let audioURL: String?
    let imageURL: String?
}

class PodcastRSSService {
    static let shared = PodcastRSSService()

    private init() {}

    // MARK: - Fetch and Parse RSS Feed

    func fetchPodcast(from urlString: String) async throws -> RSSPodcast {
        await MainActor.run {
            DevStatusManager.shared.rssLoadingStatus = .loading
            DevStatusManager.shared.networkStatus = .loading
            DevStatusManager.shared.addMessage("Fetching RSS: \(urlString)")
        }

        guard let url = URL(string: urlString) else {
            await MainActor.run {
                DevStatusManager.shared.rssLoadingStatus = .error("Invalid URL")
                DevStatusManager.shared.addMessage("RSS Error: Invalid URL")
            }
            throw RSSError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            await MainActor.run {
                DevStatusManager.shared.addMessage("RSS data received, parsing...")
            }
            let parser = RSSParser(data: data, feedURL: urlString)
            let podcast = try parser.parse()
            await MainActor.run {
                DevStatusManager.shared.rssLoadingStatus = .success
                DevStatusManager.shared.networkStatus = .success
                DevStatusManager.shared.addMessage("RSS parsed: \(podcast.title)")
            }
            return podcast
        } catch {
            await MainActor.run {
                DevStatusManager.shared.rssLoadingStatus = .error(error.localizedDescription)
                DevStatusManager.shared.networkStatus = .error("Failed")
                DevStatusManager.shared.addMessage("RSS Error: \(error.localizedDescription)")
            }
            throw error
        }
    }

    // MARK: - Download Image

    func downloadImage(from urlString: String?) async -> UIImage? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
}

// MARK: - RSS Parser

private class RSSParser: NSObject, XMLParserDelegate {
    private let data: Data
    private let feedURL: String

    private var currentElement = ""
    private var currentAttributes: [String: String] = [:]

    // Podcast-level properties
    private var podcastTitle = ""
    private var podcastDescription = ""
    private var podcastAuthor: String?
    private var podcastImageURL: String?

    // Episode-level properties
    private var episodes: [RSSEpisode] = []
    private var currentEpisode: EpisodeBuilder?

    private var currentText = ""

    init(data: Data, feedURL: String) {
        self.data = data
        self.feedURL = feedURL
    }

    func parse() throws -> RSSPodcast {
        let parser = XMLParser(data: data)
        parser.delegate = self

        guard parser.parse() else {
            throw RSSError.parsingFailed
        }

        return RSSPodcast(
            title: podcastTitle,
            description: podcastDescription,
            author: podcastAuthor,
            imageURL: podcastImageURL,
            feedURL: feedURL,
            episodes: episodes
        )
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentAttributes = attributeDict
        currentText = ""

        if elementName == "item" {
            currentEpisode = EpisodeBuilder()
        }

        // Handle iTunes image
        if elementName == "itunes:image" {
            if let href = attributeDict["href"] {
                if currentEpisode != nil {
                    currentEpisode?.imageURL = href
                } else {
                    podcastImageURL = href
                }
            }
        }

        // Handle media:content for images
        if elementName == "media:content" {
            if let medium = attributeDict["medium"], medium == "image",
               let url = attributeDict["url"] {
                if currentEpisode != nil {
                    currentEpisode?.imageURL = url
                } else {
                    podcastImageURL = url
                }
            }
        }

        // Handle enclosure for audio
        if elementName == "enclosure" {
            if let type = attributeDict["type"], type.contains("audio"),
               let url = attributeDict["url"] {
                currentEpisode?.audioURL = url
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if currentEpisode != nil {
            // Parsing episode
            switch elementName {
            case "title":
                currentEpisode?.title = text
            case "description", "itunes:summary":
                if currentEpisode?.description == nil || !text.isEmpty {
                    currentEpisode?.description = text
                }
            case "pubDate":
                currentEpisode?.pubDate = parseDateString(text)
            case "itunes:duration":
                currentEpisode?.duration = text
            case "item":
                if let episode = currentEpisode?.build() {
                    episodes.append(episode)
                }
                currentEpisode = nil
            default:
                break
            }
        } else {
            // Parsing podcast metadata
            switch elementName {
            case "title":
                if podcastTitle.isEmpty {
                    podcastTitle = text
                }
            case "description", "itunes:summary":
                if podcastDescription.isEmpty || !text.isEmpty {
                    podcastDescription = text
                }
            case "itunes:author", "author":
                if podcastAuthor == nil {
                    podcastAuthor = text
                }
            case "image":
                if let url = currentAttributes["href"] {
                    podcastImageURL = url
                }
            default:
                break
            }
        }

        currentText = ""
    }

    private func parseDateString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        // Try RFC 822 format (standard for RSS)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        if let date = formatter.date(from: string) {
            return date
        }

        // Try ISO 8601
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: string)
    }
}

// MARK: - Episode Builder

private class EpisodeBuilder {
    var title = ""
    var description: String?
    var pubDate: Date?
    var duration: String?
    var audioURL: String?
    var imageURL: String?

    func build() -> RSSEpisode? {
        guard !title.isEmpty else { return nil }

        return RSSEpisode(
            title: title,
            description: description,
            pubDate: pubDate,
            duration: duration,
            audioURL: audioURL,
            imageURL: imageURL
        )
    }
}

// MARK: - Errors

enum RSSError: LocalizedError {
    case invalidURL
    case parsingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RSS feed URL"
        case .parsingFailed:
            return "Failed to parse RSS feed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
