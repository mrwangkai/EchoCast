//
//  ExportService.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import Foundation
import UIKit

class ExportService {
    static let shared = ExportService()

    private init() {}

    // MARK: - Markdown Export

    /// Exports notes to Markdown format
    func exportToMarkdown(notes: [NoteEntity]) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let currentDate = dateFormatter.string(from: Date())

        var markdown = "# EchoNotes Export — \(currentDate)\n\n"

        // Group notes by show
        let grouped = Dictionary(grouping: notes) { $0.showTitle ?? "Unknown Show" }
        let sortedGroups = grouped.sorted { $0.key < $1.key }

        for (show, showNotes) in sortedGroups {
            markdown += "## \(show)\n\n"

            // Further group by episode
            let episodeGrouped = Dictionary(grouping: showNotes) { $0.episodeTitle ?? "Unknown Episode" }
            let sortedEpisodes = episodeGrouped.sorted { $0.key < $1.key }

            for (episode, episodeNotes) in sortedEpisodes {
                if episode != "Unknown Episode" {
                    markdown += "### \(episode)\n\n"
                }

                // Sort notes by timestamp
                let sortedNotes = episodeNotes.sorted {
                    ($0.timestamp ?? "") < ($1.timestamp ?? "")
                }

                for note in sortedNotes {
                    let priorityMarker = note.isPriority ? " (⭐️)" : ""
                    let timestamp = note.timestamp ?? "00:00:00"
                    let text = note.noteText ?? "No content"

                    markdown += "- **\(timestamp)**\(priorityMarker) \(text)\n"
                }

                markdown += "\n"
            }
        }

        markdown += "---\n\n"
        markdown += "*Exported from EchoNotes*\n"

        return markdown
    }

    /// Exports notes to a text file and returns the URL
    func exportToFile(notes: [NoteEntity], filename: String = "EchoNotes_Export") -> URL? {
        let markdown = exportToMarkdown(notes: notes)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let fileName = "\(filename)_\(dateString).md"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Error writing to file: \(error)")
            return nil
        }
    }

    // MARK: - Share Sheet

    /// Creates a share activity view controller for notes
    func shareNotes(notes: [NoteEntity], from viewController: UIViewController? = nil) {
        guard let fileURL = exportToFile(notes: notes) else {
            print("Failed to export notes to file")
            return
        }

        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        // Present from the key window's root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // For iPad - specify source view using window bounds instead of deprecated UIScreen.main
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(
                    x: window.bounds.width / 2,
                    y: window.bounds.height / 2,
                    width: 0,
                    height: 0
                )
                popoverController.permittedArrowDirections = []
            }
            
            var topController = rootViewController
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            topController.present(activityViewController, animated: true)
        }
    }

    // MARK: - Reminders Integration

    /// Formats a note for adding to Reminders
    func formatForReminders(note: NoteEntity) -> String {
        var text = ""

        if let showTitle = note.showTitle {
            text += "\(showTitle)"
            if let episodeTitle = note.episodeTitle {
                text += " - \(episodeTitle)"
            }
            text += "\n"
        }

        if let timestamp = note.timestamp {
            text += "[\(timestamp)] "
        }

        if let noteText = note.noteText {
            text += noteText
        }

        return text
    }

    // MARK: - Quote Card Generation

    /// Generates text for a quote card (image generation would require additional frameworks)
    func formatAsQuote(note: NoteEntity) -> String {
        var quote = "\"\(note.noteText ?? "")\"\n\n"

        if let show = note.showTitle {
            quote += "— \(show)"
            if let episode = note.episodeTitle {
                quote += "\n  \(episode)"
            }
        }

        return quote
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Extension to add export functionality to LibraryView
extension View {
    func shareSheet(isPresented: Binding<Bool>, items: [Any]) -> some View {
        sheet(isPresented: isPresented) {
            ShareSheet(activityItems: items)
        }
    }
}
