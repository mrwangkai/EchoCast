Branch: t113-tag-filter-system
git checkout -b t113-tag-filter-system

Phase 1 — Read only. Do not change any code yet.
Read these files and confirm you have them before proceeding:

EchoNotes/ViewModels/NoteViewModel.swift
EchoNotes/Views/LibraryView.swift
EchoNotes/Views/Player/EpisodePlayerView.swift

Stop here and confirm.

Phase 2 — Implementation
Do not create new files. Do not modify any file not listed below.

File 1: NoteViewModel.swift (T113)
Add the following — do not remove or modify anything existing:
After @Published var sortOrder: SortOrder = .dateDescending, add:
swift@Published var activeTagFilter: String? = nil
After the closing } of groupedNotes(), add:
swiftvar allTags: [String] {
    var tagFrequency: [String: Int] = [:]
    for note in notes {
        let tags = (note.tags ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        for tag in tags {
            tagFrequency[tag, default: 0] += 1
        }
    }
    return tagFrequency.sorted { $0.value > $1.value }.map { $0.key }
}
Inside fetchNotes(), inside the var predicates block, after the filterPriority block, add:
swiftif let tagFilter = activeTagFilter {
    let tagPredicate = NSPredicate(format: "tags CONTAINS[cd] %@", tagFilter)
    predicates.append(tagPredicate)
}
Inside setupSearchSubscription(), after the $sortOrder subscription, add:
swift$activeTagFilter
    .sink { [weak self] _ in
        self?.fetchNotes()
    }
    .store(in: &cancellables)

File 2: LibraryView.swift (T114, T115)
2a. Add to the @State properties block:
swift@State private var showingTagOverflow = false
2b. In searchAndFilterSection, insert between the search field HStack and the note count HStack:
swiftif !viewModel.allTags.isEmpty {
    tagFilterBar
}
2c. Replace the entire emptyStateView computed var with this version:
swiftprivate var emptyStateView: some View {
    Group {
        if let activeTag = viewModel.activeTagFilter {
            VStack(spacing: 12) {
                Image(systemName: "tag")
                    .font(.system(size: 36))
                    .foregroundColor(.echoTextTertiary)
                Text("No notes tagged \"#\(activeTag)\"")
                    .font(.title2Echo())
                    .foregroundColor(.echoTextPrimary)
                Button("Clear filter") {
                    viewModel.activeTagFilter = nil
                }
                .font(.bodyEcho())
                .foregroundColor(.mintAccent)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            VStack(spacing: 16) {
                if followedPodcasts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 36))
                            .foregroundColor(.echoTextTertiary)
                        Text("Your notes live here")
                            .font(.title2Echo())
                            .foregroundColor(.echoTextPrimary)
                        Text("Play any episode and tap the note button to capture ideas as you listen.")
                            .font(.bodyEcho())
                            .foregroundColor(.echoTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button(action: {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("navigateToBrowse"),
                                object: nil
                            )
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 15, weight: .medium))
                                Text("Browse podcasts")
                                    .font(.bodyRoundedMedium())
                            }
                            .foregroundColor(.mintButtonText)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, EchoSpacing.screenPadding)
                            .padding(.vertical, 16)
                            .background(Color.mintButtonBackground)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, EchoSpacing.screenPadding)
                        .buttonStyle(.plain)
                    }
                } else {
                    HStack(spacing: 12) {
                        Text("Play an episode and capture what stays with you")
                            .font(.bodyEcho())
                            .foregroundColor(.echoTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(action: {
                            showingContinueListeningSheet = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.mintAccent.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.mintAccent)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.mintAccent.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mintAccent.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal, EchoSpacing.screenPadding)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
            .sheet(isPresented: $showingContinueListeningSheet) {
                ContinueListeningSheetView()
            }
        }
    }
}
2d. Add these private views at the bottom of the LibraryView struct, before the closing }:
swift// MARK: - Tag Filter Bar

private var tagFilterBar: some View {
    let visibleTags = Array(viewModel.allTags.prefix(4))
    let overflowCount = viewModel.allTags.count - visibleTags.count

    return HStack(spacing: 8) {
        tagChip(label: "All", isActive: viewModel.activeTagFilter == nil) {
            viewModel.activeTagFilter = nil
        }
        ForEach(visibleTags, id: \.self) { tag in
            tagChip(label: "#\(tag)", isActive: viewModel.activeTagFilter == tag) {
                viewModel.activeTagFilter = (viewModel.activeTagFilter == tag) ? nil : tag
            }
        }
        if overflowCount > 0 {
            tagChip(label: "+\(overflowCount) more", isActive: false) {
                showingTagOverflow = true
            }
        }
        Spacer()
    }
    .sheet(isPresented: $showingTagOverflow) {
        tagOverflowSheet
    }
}

private func tagChip(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.caption2Medium())
            .foregroundColor(isActive ? Color.black : Color.echoTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.mintAccent : Color.clear)
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.mintAccent : Color.echoTextTertiary.opacity(0.4), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
    .buttonStyle(.plain)
}

private var tagOverflowSheet: some View {
    NavigationStack {
        List {
            Button(action: {
                viewModel.activeTagFilter = nil
                showingTagOverflow = false
            }) {
                HStack {
                    Text("All notes")
                        .font(.bodyEcho())
                        .foregroundColor(.echoTextPrimary)
                    Spacer()
                    if viewModel.activeTagFilter == nil {
                        Image(systemName: "checkmark")
                            .foregroundColor(.mintAccent)
                    }
                }
            }
            .listRowBackground(Color.noteCardBackground)

            ForEach(viewModel.allTags, id: \.self) { tag in
                Button(action: {
                    viewModel.activeTagFilter = tag
                    showingTagOverflow = false
                }) {
                    HStack {
                        Text("#\(tag)")
                            .font(.bodyEcho())
                            .foregroundColor(.echoTextPrimary)
                        Spacer()
                        if viewModel.activeTagFilter == tag {
                            Image(systemName: "checkmark")
                                .foregroundColor(.mintAccent)
                        }
                    }
                }
                .listRowBackground(Color.noteCardBackground)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.echoBackground)
        .navigationTitle("Filter by tag")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { showingTagOverflow = false }
                    .foregroundColor(.mintAccent)
            }
        }
    }
    .preferredColorScheme(.dark)
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
}

File 3: EpisodePlayerView.swift (T116)
This file contains two structs that need identical tag input upgrades: NoteCaptureSheetWrapper and EditNoteSheetWrapper. Apply the same changes to both.
3a. In NoteCaptureSheetWrapper:
Replace:
swift@State private var tags: String = ""
With:
swift@State private var selectedTags: [String] = []
@State private var tagInput: String = ""
Also add a parameter for existing tags to suggest against. Add to the struct's let properties:
swiftlet existingTags: [String]
Update the call site in EpisodePlayerView.body where NoteCaptureSheetWrapper is instantiated — add existingTags: []. Then update it to pass real tags once NoteViewModel is accessible. For now pass an empty array — we will wire real allTags in a follow-up.
Replace the entire tags VStack section (from Text("Tags") through the hint text) with:
swiftVStack(alignment: .leading, spacing: 6) {
    Text("Tags")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.primary)

    // Selected tag chips
    if !selectedTags.isEmpty {
        FlowLayout(spacing: 6) {
            ForEach(selectedTags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Text("#\(tag)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.mintAccent)
                    Button(action: { selectedTags.removeAll { $0 == tag } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.mintAccent.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.mintAccent.opacity(0.12))
                .overlay(
                    Capsule().stroke(Color.mintAccent.opacity(0.3), lineWidth: 1)
                )
                .clipShape(Capsule())
            }
        }
    }

    // Tag input field
    if selectedTags.count < 5 {
        TextField("Add a tag...", text: $tagInput)
            .font(.system(size: 15))
            .padding(12)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(12)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onSubmit { commitTagInput() }

        // Suggestions
        let suggestions = tagSuggestions
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: { addTag(suggestion) }) {
                        HStack {
                            Text(suggestion.hasPrefix("Create") ? suggestion : "#\(suggestion)")
                                .font(.system(size: 14))
                                .foregroundColor(suggestion.hasPrefix("Create") ? .echoTextSecondary : .echoTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    if suggestion != suggestions.last {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(12)
        }

        Text("Up to 5 tags")
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .padding(.leading, 2)
    }
}
Add these private helpers inside NoteCaptureSheetWrapper:
swiftprivate var tagSuggestions: [String] {
    guard !tagInput.isEmpty else { return [] }
    let input = tagInput.lowercased().trimmingCharacters(in: .whitespaces)
    let matches = existingTags
        .filter { $0.lowercased().contains(input) && !selectedTags.contains($0) }
        .prefix(4)
    var results = Array(matches)
    if !selectedTags.contains(input) && !existingTags.contains(input) && results.isEmpty {
        results.append("Create \"\(input)\"")
    }
    return results
}

private func commitTagInput() {
    let input = tagInput.lowercased()
        .trimmingCharacters(in: .whitespaces)
        .prefix(20)
        .description
    guard !input.isEmpty,
          !selectedTags.contains(input),
          selectedTags.count < 5 else { return }
    selectedTags.append(input)
    tagInput = ""
}

private func addTag(_ suggestion: String) {
    let tag: String
    if suggestion.hasPrefix("Create \"") {
        tag = tagInput.lowercased().trimmingCharacters(in: .whitespaces)
    } else {
        tag = suggestion
    }
    guard !tag.isEmpty,
          !selectedTags.contains(tag),
          selectedTags.count < 5 else { return }
    selectedTags.append(tag)
    tagInput = ""
}
In saveNote(), replace:
swiftlet tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
newNote.tags = tagList.joined(separator: ",")
With:
swiftnewNote.tags = selectedTags.joined(separator: ",")

3b. In EditNoteSheetWrapper, apply the identical changes:
Replace @State private var tags: String = "" with:
swift@State private var selectedTags: [String] = []
@State private var tagInput: String = ""
Add parameter:
swiftlet existingTags: [String]
Replace the tags VStack with the same chip input block as above (same tagSuggestions, commitTagInput, addTag helpers).
In .onAppear, replace:
swifttags = existingNote.tagsArray.joined(separator: ", ")
With:
swiftselectedTags = existingNote.tagsArray
In updateNote(), replace:
swiftexistingNote.tags = tags
    .split(separator: ",")
    .map { $0.trimmingCharacters(in: .whitespaces) }
    .filter { !$0.isEmpty }
    .joined(separator: ",")
With:
swiftexistingNote.tags = selectedTags.joined(separator: ",")
```

Find the call site where `EditNoteSheetWrapper` is instantiated elsewhere in the codebase and add `existingTags: []` — we will wire real allTags in a follow-up.

---

### Validation checklist

- [ ] Library: tag chips appear below search when notes have tags
- [ ] Tapping a chip filters notes; tapping active chip deselects
- [ ] "+N more" opens sheet; selecting closes sheet and applies filter
- [ ] Filtered empty state shows tag name and "Clear filter"
- [ ] Add Note: typing a tag shows suggestions from existing tags
- [ ] Selecting suggestion adds chip; typing new tag + submit creates it
- [ ] Chip × button removes tag from selection
- [ ] Max 5 tags enforced — input field hides after 5
- [ ] Tags saved as lowercase comma-separated string
- [ ] Edit Note: existing tags pre-populate as chips on `.onAppear`
- [ ] Build passes with zero errors

---

### Commit + merge
```
feat: tagging system — filter bar, ViewModel, chip input (T113–T116)
bashgit checkout main
git merge --squash t113-tag-filter-system
git commit -m "feat: tagging system — filter bar, ViewModel, chip input (T113–T116)"
git branch -D t113-tag-filter-system