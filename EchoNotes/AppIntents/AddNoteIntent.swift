//
//  AddNoteIntent.swift
//  EchoNotes
//
//  App Intent for adding notes via Siri (Updated for Siri Integration Plan)
//

import Foundation
import AppIntents
import CoreData

/// App Intent that allows users to add a note at the current playback position via Siri
struct AddNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Note at Current Time"
    static var description = IntentDescription(
        "Adds a timestamped note to the currently playing podcast episode in EchoCast."
    )
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let sharedDefaults = UserDefaults(suiteName: "group.com.echonotes.app202601302226.echocast")
        let timestamp = sharedDefaults?.double(forKey: "siri_currentTime") ?? 0
        let episodeTitle = sharedDefaults?.string(forKey: "siri_episodeTitle") ?? ""
        let podcastTitle = sharedDefaults?.string(forKey: "siri_podcastTitle") ?? ""
        let isPlaying = sharedDefaults?.bool(forKey: "siri_isPlaying") ?? false

        guard isPlaying || timestamp > 0 else {
            return .result(dialog: "No podcast is currently playing in EchoCast.")
        }

        // Save note to Core Data
        let context = PersistenceController.shared.container.viewContext
        await context.perform {
            let note = NoteEntity(context: context)
            note.id = UUID()
            note.episodeTitle = episodeTitle
            note.showTitle = podcastTitle
            note.timestamp = self.formatTime(timestamp)
            note.noteText = ""   // blank — user can edit in app
            note.isPriority = false
            note.tags = ""
            note.createdAt = Date()
            note.sourceApp = "Siri"

            do {
                try context.save()
            } catch {
                print("❌ [Siri Intent] Failed to save note: \(error)")
            }
        }

        let formattedTime = formatTime(timestamp)
        return .result(dialog: "Note saved at \(formattedTime) in \(episodeTitle). Open EchoCast to add details.")
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

/// App Shortcuts Provider
struct EchoNotesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddNoteIntent(),
            phrases: [
                "Add a note in \(.applicationName)",
                "Add note at current time in \(.applicationName)",
                "Note this in \(.applicationName)",
                "Capture this in \(.applicationName)",
                "Timestamp this in \(.applicationName)"
            ],
            shortTitle: "Add Podcast Note",
            systemImageName: "note.text.badge.plus"
        )
    }
}
