//
//  DevStatusOverlay.swift
//  EchoNotes
//
//  Developer debug status overlay with color indicators
//

import SwiftUI

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
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(statusManager.statusMessages.prefix(10), id: \.self) { message in
                                    Text(message)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                }
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
        }
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
