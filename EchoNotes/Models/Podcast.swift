//
//  Podcast.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import Foundation

/// Represents a podcast show
struct Podcast: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String?
    var podcastDescription: String?
    var artworkURL: String?

    init(
        id: UUID = UUID(),
        title: String,
        author: String? = nil,
        podcastDescription: String? = nil,
        artworkURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.podcastDescription = podcastDescription
        self.artworkURL = artworkURL
    }
}

// MARK: - Sample Data
extension Podcast {
    static let samples: [Podcast] = [
        Podcast(
            title: "The Tim Ferriss Show",
            author: "Tim Ferriss",
            podcastDescription: "Tim Ferriss is a self-experimenter and bestselling author, best known for The 4-Hour Workweek.",
            artworkURL: "https://example.com/ferriss.jpg"
        ),
        Podcast(
            title: "Huberman Lab",
            author: "Andrew Huberman",
            podcastDescription: "Huberman Lab discusses neuroscience and science-based tools for everyday life.",
            artworkURL: "https://example.com/huberman.jpg"
        ),
        Podcast(
            title: "How I Built This",
            author: "Guy Raz",
            podcastDescription: "Guy Raz dives into the stories behind some of the world's best known companies.",
            artworkURL: "https://example.com/hibt.jpg"
        )
    ]
}
