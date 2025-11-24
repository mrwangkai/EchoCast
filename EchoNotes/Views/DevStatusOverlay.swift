//
//  DevStatusOverlay.swift
//  EchoNotes
//
//  Developer debug status overlay with color indicators
//

import SwiftUI
import CoreData

// MARK: - Dev Status Manager

@MainActor
class DevStatusManager: ObservableObject {
    static let shared = DevStatusManager()

    @Published var isEnabled = false
    @Published var rssLoadingStatus: LoadingStatus = .idle
    @Published var downloadStatus: LoadingStatus = .idle
    @Published var playerStatus: LoadingStatus = .idle
    @Published var networkStatus: LoadingStatus = .idle
    @Published var statusMessages: [String] = []

    enum LoadingStatus {
        case idle
        case loading
        case success
        case error(String)

        var color: Color {
            switch self {
            case .idle: return .gray
            case .loading: return .yellow
            case .success: return .green
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .idle: return "circle"
            case .loading: return "circle.dotted"
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }

    private init() {}

    func addMessage(_ message: String) {
        DispatchQueue.main.async {
            self.statusMessages.insert("[\(self.timestamp())] \(message)", at: 0)
            if self.statusMessages.count > 20 {
                self.statusMessages.removeLast()
            }
        }
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Dev Status Overlay

struct DevStatusOverlay: View {
    @ObservedObject var statusManager = DevStatusManager.shared
    @State private var isExpanded = false
    @State private var showClearConfirmation = false
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        if statusManager.isEnabled {
            VStack {
                HStack {
                    Spacer()

                    VStack(spacing: 0) {
                        // Collapsed status bar
                        HStack(spacing: 8) {
                            StatusDot(status: statusManager.rssLoadingStatus, label: "RSS")
                            StatusDot(status: statusManager.playerStatus, label: "Player")
                            StatusDot(status: statusManager.downloadStatus, label: "DL")
                            StatusDot(status: statusManager.networkStatus, label: "Net")

                            Button(action: { withAnimation { isExpanded.toggle() } }) {
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(20)

                        // Expanded details
                        if isExpanded {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(statusManager.statusMessages.prefix(10), id: \.self) { message in
                                    Text(message)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                }

                                Divider()
                                    .background(Color.white.opacity(0.3))

                                // Clear Cache Button
                                Button(action: {
                                    showClearConfirmation = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                            .font(.caption)
                                        Text("Clear All Cache")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.red)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(8)
                            .frame(maxWidth: 300)
                            .background(Color.black.opacity(0.9))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 8)

                Spacer()
            }
            .alert("Clear All Cache?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    clearAllCache()
                }
            } message: {
                Text("This will delete all podcasts, notes, playback history, and downloaded files. This action cannot be undone.")
            }
        }
    }

    private func clearAllCache() {
        // Stop player and clear state
        GlobalPlayerManager.shared.stop()

        // Delete all Core Data entities
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = PodcastEntity.fetchRequest()
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)

        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = NoteEntity.fetchRequest()
        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)

        do {
            try viewContext.execute(deleteRequest1)
            try viewContext.execute(deleteRequest2)
            try viewContext.save()
            statusManager.addMessage("✅ Core Data cleared")
        } catch {
            statusManager.addMessage("❌ Core Data error: \(error.localizedDescription)")
        }

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "playbackHistory")
        UserDefaults.standard.removeObject(forKey: "downloadedEpisodes")
        statusManager.addMessage("✅ UserDefaults cleared")

        // Clear downloaded files
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
            do {
                if FileManager.default.fileExists(atPath: downloadsPath.path) {
                    try FileManager.default.removeItem(at: downloadsPath)
                    statusManager.addMessage("✅ Downloaded files cleared")
                }
            } catch {
                statusManager.addMessage("❌ File deletion error: \(error.localizedDescription)")
            }
        }

        // Reset managers
        PlaybackHistoryManager.shared.recentlyPlayed.removeAll()
        EpisodeDownloadManager.shared.downloadedEpisodes.removeAll()
        EpisodeDownloadManager.shared.downloadProgress.removeAll()

        statusManager.addMessage("🎉 Cache cleared! App reset to zero state")
    }
}

struct StatusDot: View {
    let status: DevStatusManager.LoadingStatus
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: status.icon)
                .font(.system(size: 12))
                .foregroundColor(status.color)
            Text(label)
                .font(.system(size: 8))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Dev Status Toggle Button

struct DevStatusToggleButton: View {
    @ObservedObject var statusManager = DevStatusManager.shared

    var body: some View {
        Button(action: {
            withAnimation {
                statusManager.isEnabled.toggle()
            }
        }) {
            Image(systemName: statusManager.isEnabled ? "ant.circle.fill" : "ant.circle")
                .font(.title3)
                .foregroundColor(statusManager.isEnabled ? .green : .gray)
        }
    }
}

// MARK: - Debug Console Sheet View

struct DebugConsoleView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var statusManager = DevStatusManager.shared
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Status indicators
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System Status")
                            .font(.headline)

                        HStack(spacing: 20) {
                            StatusIndicator(status: statusManager.rssLoadingStatus, label: "RSS")
                            StatusIndicator(status: statusManager.playerStatus, label: "Player")
                            StatusIndicator(status: statusManager.downloadStatus, label: "Downloads")
                            StatusIndicator(status: statusManager.networkStatus, label: "Network")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Log messages
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity Log")
                            .font(.headline)

                        if statusManager.statusMessages.isEmpty {
                            Text("No activity yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(statusManager.statusMessages, id: \.self) { message in
                                Text(message)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Clear cache button
                    Button(action: {
                        showClearConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clear All Cache")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Clear All Cache?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    clearAllCache()
                }
            } message: {
                Text("This will delete all podcasts, notes, playback history, and downloaded files. This action cannot be undone.")
            }
        }
    }

    private func clearAllCache() {
        // Stop player and clear state
        GlobalPlayerManager.shared.stop()

        // Delete all Core Data entities
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = PodcastEntity.fetchRequest()
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)

        let fetchRequest2: NSFetchRequest<NSFetchRequestResult> = NoteEntity.fetchRequest()
        let deleteRequest2 = NSBatchDeleteRequest(fetchRequest: fetchRequest2)

        do {
            try viewContext.execute(deleteRequest1)
            try viewContext.execute(deleteRequest2)
            try viewContext.save()
            statusManager.addMessage("✅ Core Data cleared")
        } catch {
            statusManager.addMessage("❌ Core Data error: \(error.localizedDescription)")
        }

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "playbackHistory")
        UserDefaults.standard.removeObject(forKey: "downloadedEpisodes")
        statusManager.addMessage("✅ UserDefaults cleared")

        // Clear downloaded files
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
            do {
                if FileManager.default.fileExists(atPath: downloadsPath.path) {
                    try FileManager.default.removeItem(at: downloadsPath)
                    statusManager.addMessage("✅ Downloaded files cleared")
                }
            } catch {
                statusManager.addMessage("❌ File deletion error: \(error.localizedDescription)")
            }
        }

        // Reset managers
        PlaybackHistoryManager.shared.recentlyPlayed.removeAll()
        EpisodeDownloadManager.shared.downloadedEpisodes.removeAll()
        EpisodeDownloadManager.shared.downloadProgress.removeAll()

        statusManager.addMessage("🎉 Cache cleared! App reset to zero state")
    }
}

struct StatusIndicator: View {
    let status: DevStatusManager.LoadingStatus
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: status.icon)
                .font(.title2)
                .foregroundColor(status.color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        DevStatusOverlay()
            .onAppear {
                DevStatusManager.shared.isEnabled = true
                DevStatusManager.shared.rssLoadingStatus = .loading
                DevStatusManager.shared.playerStatus = .success
                DevStatusManager.shared.downloadStatus = .error("Failed")
                DevStatusManager.shared.networkStatus = .success
                DevStatusManager.shared.addMessage("Testing message 1")
                DevStatusManager.shared.addMessage("Testing message 2")
            }
    }
}
