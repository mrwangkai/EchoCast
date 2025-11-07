//
//  AddNoteIntent.swift
//  EchoNotes
//
//  App Intent for adding notes via Siri
//

import Foundation
import AppIntents

/// App Intent that allows users to add a note at the current playback position via Siri
struct AddNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Note"
    static var description = IntentDescription("Add a note at the current timestamp while listening to a podcast.")

    static var openAppWhenRun: Bool = true

    @Parameter(title: "Note Content", description: "The text content of the note", requestValueDialog: "What would you like to note?")
    var noteContent: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get the current episode and playback state
        let player = GlobalPlayerManager.shared

        guard let episode = player.currentEpisode,
              let podcast = player.currentPodcast else {
            return .result(dialog: "No podcast is currently playing. Please start playing a podcast first.")
        }

        // Get current timestamp
        let currentTime = player.currentTime
        let timestamp = formatTime(currentTime)

        // If note content was provided via parameter, save it directly
        if let content = noteContent, !content.isEmpty {
            // Save the note
            await saveNote(
                content: content,
                timestamp: timestamp,
                episodeTitle: episode.title,
                podcastTitle: podcast.title ?? "Unknown Podcast",
                podcast: podcast
            )

            return .result(dialog: "Note saved at \(timestamp): \(content)")
        } else {
            // Open the app to the note capture sheet
            // We'll set a flag that the app can check to show the note capture sheet
            UserDefaults.standard.set(true, forKey: "shouldShowNoteCaptureFromSiri")
            UserDefaults.standard.set(timestamp, forKey: "siriNoteTimestamp")

            return .result(dialog: "Opening note capture at \(timestamp)")
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    @MainActor
    private func saveNote(content: String, timestamp: String, episodeTitle: String, podcastTitle: String, podcast: PodcastEntity) async {
        let context = PersistenceController.shared.container.viewContext

        let note = NoteEntity(context: context)
        note.id = UUID()
        note.noteText = content
        note.timestamp = timestamp
        note.episodeTitle = episodeTitle
        note.showTitle = podcastTitle
        note.createdAt = Date()
        note.isPriority = false
        note.podcast = podcast

        do {
            try context.save()
        } catch {
            print("Error saving note from Siri: \(error)")
        }
    }
}

/// App Shortcuts Provider
struct EchoNotesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddNoteIntent(),
            phrases: [
                "Add a note in \(.applicationName)",
                "Add note in \(.applicationName)",
                "Take a note in \(.applicationName)",
                "Note this in \(.applicationName)",
                "Save a note in \(.applicationName)"
            ],
            shortTitle: "Add Note",
            systemImageName: "note.text.badge.plus"
        )
    }
}
