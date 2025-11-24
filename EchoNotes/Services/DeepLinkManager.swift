//
//  DeepLinkManager.swift
//  EchoNotes
//
//  Deep link handling for episode sharing with timestamps
//

import Foundation
import SwiftUI
import Combine

enum DeepLinkDestination: Equatable {
    case episode(episodeID: String, timestamp: TimeInterval?)

    static func == (lhs: DeepLinkDestination, rhs: DeepLinkDestination) -> Bool {
        switch (lhs, rhs) {
        case (.episode(let lhsID, let lhsTime), .episode(let rhsID, let rhsTime)):
            return lhsID == rhsID && lhsTime == rhsTime
        }
    }
}

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    @Published var pendingDeepLink: DeepLinkDestination?
    @Published var isHandlingDeepLink = false

    private init() {}

    /// Parse a URL and extract episode ID and timestamp
    /// Supports formats like:
    /// - customdomain.com/episodeID?t=123
    /// - customdomain.com/episodeID?t=123.5
    /// - echonotes://episode/episodeID?t=123
    func handleURL(_ url: URL) -> Bool {
        print("🔗 Deep link received: \(url.absoluteString)")

        // Extract episode ID from path
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        guard let episodeID = pathComponents.last, !episodeID.isEmpty else {
            print("❌ No episode ID found in URL path")
            return false
        }

        // Extract timestamp from query parameters
        var timestamp: TimeInterval?

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            // Look for 't' parameter (time in seconds)
            if let timeString = queryItems.first(where: { $0.name == "t" })?.value,
               let timeValue = Double(timeString) {
                timestamp = timeValue
                print("⏰ Timestamp found: \(timeValue)s")
            }
        }

        print("✅ Parsed deep link - Episode: \(episodeID), Timestamp: \(timestamp?.description ?? "none")")

        // Store the deep link for processing
        DispatchQueue.main.async {
            self.pendingDeepLink = .episode(episodeID: episodeID, timestamp: timestamp)
            self.isHandlingDeepLink = true
        }

        return true
    }

    /// Clear the pending deep link after it's been handled
    func clearPendingDeepLink() {
        DispatchQueue.main.async {
            self.pendingDeepLink = nil
            self.isHandlingDeepLink = false
        }
    }

    /// Generate a shareable URL for an episode with optional timestamp
    /// Format: customdomain.com/episodeID?t=seconds
    static func generateShareURL(episodeID: String, timestamp: TimeInterval?, customDomain: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = customDomain
        components.path = "/\(episodeID)"

        if let timestamp = timestamp {
            components.queryItems = [
                URLQueryItem(name: "t", value: String(format: "%.1f", timestamp))
            ]
        }

        return components.url
    }

    /// Format timestamp as human-readable string (MM:SS or HH:MM:SS)
    static func formatTimestamp(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
