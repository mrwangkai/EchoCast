TASK: Create NoteRowView and use it in the episode player Notes tab.
Do NOT modify NoteCardView.

── STEP 1: Create NoteRowView ──────────────────────────────────────

Add a new struct NoteRowView in ContentView.swift, placed just above NoteCardView.

struct NoteRowView: View {
    let note: NoteEntity
    var onTap: (() -> Void)? = nil
    @State private var isExpanded: Bool = false

    private var hasMoreContent: Bool {
        (note.noteText?.count ?? 0) > 120
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 32) {
                // LEFT: timestamp
                Text(note.timestamp ?? "")
                    .font(.system(.footnote).weight(.semibold))
                    .foregroundColor(.mintAccent)
                    .frame(width: 54, alignment: .leading)

                // RIGHT: note text + More/Less
                VStack(alignment: .leading, spacing: 4) {
                    if let noteText = note.noteText, !noteText.isEmpty {
                        Text(noteText)
                            .font(.system(.footnote))
                            .foregroundColor(.echoTextPrimary)
                            .lineLimit(isExpanded ? nil : 4)
                            .lineSpacing(3)
                            .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                    if hasMoreContent {
                        Button(action: { isExpanded.toggle() }) {
                            Text(isExpanded ? "Less" : "More")
                                .font(.system(.footnote))
                                .foregroundColor(.mintAccent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }

            // Tags (if any)
            if !note.tagsArray.isEmpty {
                let visibleTags = Array(note.tagsArray.prefix(3))
                let extra = max(0, note.tagsArray.count - 3)
                HStack(spacing: 6) {
                    ForEach(visibleTags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2Medium())
                            .foregroundColor(.echoTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                            .lineLimit(1)
                    }
                    if extra > 0 {
                        Text("+\(extra)")
                            .font(.caption2Medium())
                            .foregroundColor(.echoTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                    }
                }
                .padding(.bottom, 12)
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
        }
    }
}

── STEP 2: Use NoteRowView in the episode player Notes tab ──────────

Find the notesListView or notesTabContent in the episode player section
of ContentView.swift (the ForEach that renders notes inside the player sheet).

Replace NoteCardView with NoteRowView there, passing the onTap seek closure:

NoteRowView(note: note) {
    // existing seek + tab switch logic, unchanged
}

The VStack spacing around this ForEach should be 0 (dividers handle separation).
Remove any .padding(.horizontal) on the ForEach container — 
horizontal padding should come from the parent ScrollView or enclosing VStack only.

── STEP 3: Do NOT change ────────────────────────────────────────────

- NoteCardView — untouched
- HomeView NoteCardView usage — untouched  
- LibraryView NoteCardView usage — untouched

After changes, do NOT run. Commit:
"t37: add NoteRowView for episode player notes tab"