import SwiftUI

// Siri snippet view — must be lightweight, no async loading, no @State
struct NoteSnippetView: View {
    let noteContent: String
    let timestamp: String        // pre-formatted e.g. "4:32"
    let episodeTitle: String
    let podcastTitle: String
    let isSaved: Bool            // false = confirming, true = saved

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Podcast context header
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#00c8b3"))
                Text(podcastTitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Episode title
            Text(episodeTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)

            // Timestamp badge
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text(timestamp)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(Color(hex: "#00c8b3"))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(hex: "#00c8b3").opacity(0.15))
            .cornerRadius(6)

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 1)

            // Note content
            Text(noteContent.isEmpty ? "Tap to add details..." : noteContent)
                .font(.system(size: 15))
                .foregroundColor(noteContent.isEmpty ? .secondary : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)

            // Footer status
            HStack(spacing: 4) {
                Spacer()
                if isSaved {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "#00c8b3"))
                        .font(.system(size: 12))
                    Text("Saved to EchoCast")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                } else {
                    Text("Saving to EchoCast...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
