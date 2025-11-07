//
//  SiriShortcutsManager.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import Foundation
import Intents
import UIKit
import CoreSpotlight
import UniformTypeIdentifiers

/// Manages Siri Shortcuts integration for EchoNotes
class SiriShortcutsManager {
    static let shared = SiriShortcutsManager()

    private init() {}

    // MARK: - Shortcut Donation

    /// Donates the "Capture Note" activity to Siri
    func donateCaptureNoteActivity() {
        let activity = NSUserActivity(activityType: "com.echonotes.captureNote")
        activity.title = "Capture Note"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = "captureNote"

        // Set suggested invocation phrase
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.contentDescription = "Quickly capture a podcast note"
        activity.contentAttributeSet = attributes

        // Add to current activity
        self.currentActivity = activity
        activity.becomeCurrent()
    }

    private var currentActivity: NSUserActivity?

    /// Registers shortcuts with the system
    func registerShortcuts() {
        // Create capture note shortcut
        let captureIntent = createCaptureNoteIntent()

        // Donate the interaction
        let interaction = INInteraction(intent: captureIntent, response: nil)
        interaction.donate { error in
            if let error = error {
                print("Failed to donate interaction: \(error)")
            } else {
                print("Successfully donated capture note shortcut")
            }
        }
    }

    private func createCaptureNoteIntent() -> INIntent {
        // Note: In a real implementation, you would create a custom intent
        // defined in an Intents.intentdefinition file
        // For this prototype, we'll use a generic intent
        return INIntent()
    }

    // MARK: - Handling Shortcuts

    /// Handles incoming user activity from Siri or Shortcuts
    func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == "com.echonotes.captureNote" else {
            return false
        }

        // Post notification to show note capture view
        NotificationCenter.default.post(
            name: .showNoteCaptureView,
            object: nil
        )

        return true
    }

    /// Handles voice shortcut phrase
    func handleVoiceShortcut(withText text: String?) {
        let persistence = PersistenceController.shared

        // Create a note with the transcribed text
        persistence.createNote(
            showTitle: nil,
            episodeTitle: nil,
            timestamp: nil,
            noteText: text,
            isPriority: false,
            tags: ["voice"],
            sourceApp: "Siri"
        )

        // Show confirmation
        provideFeedback()
    }

    private func provideFeedback() {
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let showNoteCaptureView = Notification.Name("showNoteCaptureView")
}
