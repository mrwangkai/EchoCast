TASK: Revert NoteCardView in ContentView.swift back to its original 
card-style design. NoteRowView (created in T35 -- corrected) should remain untouched.

The NoteCardView body should be restored to exactly this structure:

VStack(alignment: .leading, spacing: 0) {
    // TOP: Note content + metadata
    VStack(alignment: .leading, spacing: 12) {
        // Note text
        if let noteText = note.noteText, !noteText.isEmpty {
            Text(noteText)
                .font(.system(size: 17, weight: .regular, design: .serif))
                .foregroundColor(.echoTextPrimary)
                .lineLimit(4)
                .lineSpacing(4)
        }

        // Timestamp (left) + Tags (right)
        HStack(alignment: .top) {
            if let timestamp = note.timestamp {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text(timestamp)
                        .font(.caption2Medium())
                }
                .foregroundColor(.mintAccent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.mintAccent.opacity(0.15))
                .cornerRadius(6)
            }

            Spacer()

            if !note.tagsArray.isEmpty {
                HStack(spacing: 6) {
                    ForEach(visibleTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2Medium())
                            .foregroundColor(.echoTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.noteCardBackground)
                            .cornerRadius(6)
                            .lineLimit(1)
                    }
                    if additionalTagsCount > 0 {
                        Text("+\(additionalTagsCount)")
                            .font(.caption2Medium())
                            .foregroundColor(.echoTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.noteCardBackground)
                            .cornerRadius(6)
                    }
                }
                .frame(maxWidth: 225)
            }
        }
    }
    .padding(16)

    // SEPARATOR
    Rectangle()
        .fill(Color.white.opacity(0.08))
        .frame(height: 1)
        .padding(.horizontal, 16)

    // BOTTOM: Podcast metadata
    HStack(spacing: 8) {
        CachedAsyncImage(url: URL(string: note.podcast?.artworkURL ?? "")) {
            $0
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 32, height: 32)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.echoTextTertiary.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(.echoTextTertiary)
                }
        }
        .frame(width: 32, height: 32)
        .cornerRadius(6)
        .padding(.trailing, 8)

        VStack(alignment: .leading, spacing: 4) {
            if let episodeTitle = note.episodeTitle {
                Text(episodeTitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(2)
            }
            if let showTitle = note.showTitle {
                Text(showTitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.echoTextSecondary)
                    .lineLimit(1)
            }
        }

        Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 12)
    .padding(.bottom, 16)
}
.background(Color.noteCardBackground)
.cornerRadius(12)
.overlay {
    RoundedRectangle(cornerRadius: 12)
        .stroke(Color.white.opacity(0.15), lineWidth: 1)
}
.shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)

Also remove @State private var isExpanded from NoteCardView — 
it was added in T35 and is no longer needed there.
The visibleTags and additionalTagsCount computed properties should remain.

NoteRowView — do NOT touch.
EpisodePlayerView.swift — do NOT touch.
HomeView.swift — do NOT touch.
LibraryView.swift — do NOT touch.

Commit: "t35 (corrected): revert NoteCardView to original card style (row style is player-only)"