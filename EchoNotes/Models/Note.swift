//
//  Note.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import Foundation

/// Represents a single note captured during podcast listening
struct Note: Identifiable, Codable {
    let id: UUID
    var showTitle: String?
    var episodeTitle: String?
    var timestamp: String?  // Format: "HH:MM:SS"
    var noteText: String?
    var isPriority: Bool
    var tags: [String]
    var createdAt: Date
    var sourceApp: String?  // e.g., "Overcast", "Apple Podcasts"

    init(
        id: UUID = UUID(),
        showTitle: String? = nil,
        episodeTitle: String? = nil,
        timestamp: String? = nil,
        noteText: String? = nil,
        isPriority: Bool = false,
        tags: [String] = [],
        createdAt: Date = Date(),
        sourceApp: String? = nil
    ) {
        self.id = id
        self.showTitle = showTitle
        self.episodeTitle = episodeTitle
        self.timestamp = timestamp
        self.noteText = noteText
        self.isPriority = isPriority
        self.tags = tags
        self.createdAt = createdAt
        self.sourceApp = sourceApp
    }

    /// Formatted timestamp for display
    var formattedTimestamp: String {
        timestamp ?? "00:00:00"
    }

    /// Display title combining show and episode
    var displayTitle: String {
        if let show = showTitle, let episode = episodeTitle {
            return "\(show) - \(episode)"
        } else if let show = showTitle {
            return show
        } else if let episode = episodeTitle {
            return episode
        } else {
            return "Untitled Note"
        }
    }
}

// MARK: - Sample Data
extension Note {
    static let sample = Note(
        showTitle: "The Tim Ferriss Show",
        episodeTitle: "How to Think Clearly",
        timestamp: "00:32:14",
        noteText: "Great point about designing for failure",
        isPriority: true,
        tags: ["productivity", "design"],
        sourceApp: "Overcast"
    )

    static let samples: [Note] = [
        Note(
            showTitle: "The Tim Ferriss Show",
            episodeTitle: "How to Think Clearly",
            timestamp: "00:32:14",
            noteText: "Great point about designing for failure",
            isPriority: true,
            tags: ["productivity"],
            sourceApp: "Overcast"
        ),
        Note(
            showTitle: "Huberman Lab",
            episodeTitle: "Sleep Science",
            timestamp: "01:15:30",
            noteText: "Sunlight exposure in first hour of waking",
            isPriority: false,
            tags: ["health", "sleep"],
            sourceApp: "Apple Podcasts"
        ),
        Note(
            showTitle: "How I Built This",
            episodeTitle: "Airbnb: Joe Gebbia",
            timestamp: "00:45:12",
            noteText: "Add to reminders: Book recommendation on design thinking",
            isPriority: true,
            tags: ["entrepreneurship", "follow-up"],
            sourceApp: "Overcast"
        )
    ]
}
