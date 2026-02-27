//
//  BookmarkOverlayCard.swift
//  EchoNotes
//
//  Overlay card for bookmark preview when tapping bookmark markers on timeline
//

import SwiftUI

struct BookmarkOverlayCard: View {
    let bookmark: BookmarkEntity
    let onJump: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.mintAccent)
                    .font(.system(size: 14, weight: .semibold))
                Text("Bookmark")
                    .font(.bodyRoundedMedium())
                    .foregroundColor(.echoTextPrimary)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.echoTextSecondary)
                }
                .buttonStyle(.plain)
            }

            // Timestamp
            Text(formatTime(bookmark.timestamp))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.echoTextSecondary)

            // Jump CTA
            Button {
                onJump()
            } label: {
                Text("Jump to time")
                    .font(.bodyRoundedMedium())
                    .foregroundColor(.mintButtonText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.mintButtonBackground)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.echoBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}
