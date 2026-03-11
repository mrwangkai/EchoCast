# T43 — "View All" Sheets: Continue Listening & Your Shows
**Claude Code Prompt — branch: `t43-view-all-sheets`**

---

## Preamble

Read `docs/echocast_todo.md` before starting. This work is part of T43.

You are on branch `t43-view-all-sheets`. Confirm before touching any file:

```bash
git branch --show-current
```

If the output is not `t43-view-all-sheets`, stop and report. Do not proceed on any other branch.

When complete, update `docs/echocast_todo.md` with progress notes and commit ID. Discovered issues go to Inbox — do not fix inline.

---

## Context

We are adding two "View all" sheet presentations to `HomeView`:

1. **Continue Listening sheet** — triggered by "View all" in the Continue Listening section header. Shows a vertical scrollable list of all in-progress episodes from `PlaybackHistoryManager.shared.recentlyPlayed`.

2. **Your Shows sheet** — triggered by "View all" in the Your Shows section header. Replaces the current "Find more" or browse link. Shows a vertical list of all followed podcasts read from `UserDefaults`, with a context blurb explaining what "Your Shows" means and an "Add a show" row at the bottom.

Both sheets follow the established EchoCast sheet pattern: presented from `HomeView` body level using `.sheet(isPresented:)`, never from inside a scroll view or subcomponent.

---

## Phase 1 — Diagnosis (read-only, stop and report)

Run the following. Do not make changes. Report all findings before proceeding.

```bash
# 1. Confirm branch
git branch --show-current

# 2. Find how HomeView currently presents sheets — look for existing @State bools and .sheet modifiers
grep -n "@State\|\.sheet\|isPresented\|showingPodcast\|showBrowse\|findMore" EchoNotes/Views/HomeView.swift | head -40

# 3. Confirm how followed podcasts are stored — UserDefaults key and encoding
grep -n "followedPodcasts\|podcast_\\\\\|JSONEncoder\|JSONDecoder\|UserDefaults" EchoNotes/Views/HomeView.swift EchoNotes/Views/PodcastDetailView.swift EchoNotes/Views/NavigationUX-Implementation.swift 2>/dev/null | head -40

# 4. Confirm PlaybackHistoryItem fields available for Continue Listening list
grep -n "struct PlaybackHistoryItem\|var episode\|var podcast\|var currentTime\|var duration\|var artworkURL\|var audioURL\|var title\|var id" EchoNotes/PlaybackHistoryManager.swift | head -30

# 5. Find the current "Find more" / browse link in the Your Shows section of HomeView
grep -n "findMore\|Find more\|browse\|Browse\|showBrowse\|PodcastBrowse\|PodcastDiscovery" EchoNotes/Views/HomeView.swift | head -20

# 6. Confirm how note pips work — how notes are queried per episode for progress bar markers
grep -n "NoteEntity\|episodeTitle\|timestamp\|noteTimestamp\|progressPip\|pip" EchoNotes/Views/HomeView.swift | head -20

# 7. Check what method GlobalPlayerManager exposes for resuming a history item
grep -n "func load\|func resume\|func play\|PlaybackHistoryItem\|recentlyPlayed" EchoNotes/GlobalPlayerManager.swift | head -20
```

**Stop here.** Report:
- All existing `@State` sheet bools in `HomeView` and where `.sheet` modifiers are attached
- The exact `UserDefaults` key for followed podcast IDs and the per-podcast key pattern
- All fields available on `PlaybackHistoryItem`
- What the current "Find more" / browse entry point looks like and which line it's on
- Whether `GlobalPlayerManager` has a method to load a `PlaybackHistoryItem` directly or whether you need to construct episode/podcast from its fields

Do not proceed to Phase 2 until findings are reported.

---

## Phase 2 — Implementation

Proceed only after Phase 1 is confirmed.

---

### Step 1 — Add sheet state vars to HomeView

In `HomeView.swift`, add two new `@State` booleans alongside existing sheet state vars. Do not remove any existing ones.

```swift
@State private var showingContinueListeningSheet = false
@State private var showingYourShowsSheet = false
```

---

### Step 2 — Add "View all" buttons to section headers

#### Continue Listening section header

Find the Continue Listening section header in `HomeView`. Replace the existing header (which likely has just a title) with:

```swift
HStack(alignment: .firstTextBaseline) {
    Text("Continue Listening")
        .font(.system(size: 19, weight: .bold))
        .foregroundColor(.echoTextPrimary)
    Spacer()
    Button {
        showingContinueListeningSheet = true
    } label: {
        HStack(spacing: 3) {
            Text("View all")
                .font(.system(size: 12, weight: .600))
                .foregroundColor(Color.mintAccent.opacity(0.85))
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.mintAccent.opacity(0.85))
        }
    }
    .buttonStyle(.plain)
}
.padding(.horizontal, 20)
```

#### Your Shows section header

Find the Your Shows section header. Replace with the same pattern, wiring to `showingYourShowsSheet = true`. Also find and **remove** the existing "Find more" / browse link row that currently appears at the end of the Your Shows horizontal scroll — it will be replaced by the "Add a show" row inside the sheet.

---

### Step 3 — Attach sheet modifiers to HomeView body

Find the outermost view in `HomeView.body` where other `.sheet` modifiers are already attached (this is the correct level — never inside a `ScrollView` or subview). Add:

```swift
// Continue Listening sheet
.sheet(isPresented: $showingContinueListeningSheet) {
    ContinueListeningSheetView()
}

// Your Shows sheet
.sheet(isPresented: $showingYourShowsSheet) {
    YourShowsSheetView()
}
```

---

### Step 4 — Create ContinueListeningSheetView

Create this as a `private struct` at the bottom of `HomeView.swift`, below the existing private subview structs. Do not create a new file.

```swift
private struct ContinueListeningSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var historyManager = PlaybackHistoryManager.shared
    @ObservedObject private var player = GlobalPlayerManager.shared
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue Listening")
                        .font(.system(size: 17, weight: .700))
                        .foregroundColor(.echoTextPrimary)
                    Text("\(historyManager.recentlyPlayed.count) episodes in progress")
                        .font(.system(size: 12))
                        .foregroundColor(.echoTextTertiary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 15, weight: .600))
                    .foregroundColor(Color.mintAccent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            // List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(historyManager.recentlyPlayed) { item in
                        ContinueListeningSheetRow(item: item)

                        if item.id != historyManager.recentlyPlayed.last?.id {
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(red: 0.118, green: 0.118, blue: 0.118))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden) // we draw our own handle
    }
}
```

#### ContinueListeningSheetRow

Add this immediately below `ContinueListeningSheetView`:

```swift
private struct ContinueListeningSheetRow: View {
    let item: PlaybackHistoryItem
    @ObservedObject private var player = GlobalPlayerManager.shared
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch notes for this episode to show pips
    // Use episodeTitle matching — no new Core Data fields needed
    private var notesForEpisode: [NoteEntity] {
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "episodeTitle == %@", item.episodeTitle)
        return (try? viewContext.fetch(request)) ?? []
    }

    private var progress: Double {
        guard item.duration > 0 else { return 0 }
        return item.currentTime / item.duration
    }

    private var timeRemainingText: String {
        let remaining = item.duration - item.currentTime
        let mins = Int(remaining) / 60
        return mins > 0 ? "\(mins) min left" : "Almost done"
    }

    private var noteCountText: String? {
        let count = notesForEpisode.count
        guard count > 0 else { return nil }
        return "· \(count) \(count == 1 ? "note" : "notes")"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            AsyncImage(url: URL(string: item.artworkURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Image(systemName: "headphones")
                        .font(.system(size: 20))
                        .foregroundColor(.echoTextTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.06))
                }
            }
            .frame(width: 52, height: 52)
            .cornerRadius(9)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.podcastTitle)
                    .font(.system(size: 10, weight: .700))
                    .foregroundColor(Color.mintAccent)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(item.episodeTitle)
                    .font(.system(size: 13, weight: .600))
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(timeRemainingText)
                    if let noteText = noteCountText {
                        Text(noteText)
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(.echoTextTertiary)

                // Progress bar with note pips
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 2)
                            .cornerRadius(1)

                        // Fill
                        Rectangle()
                            .fill(Color.mintAccent.opacity(0.7))
                            .frame(width: geo.size.width * progress, height: 2)
                            .cornerRadius(1)

                        // Note pips
                        ForEach(notesForEpisode, id: \.objectID) { note in
                            if let pipPosition = pipPosition(for: note, width: geo.size.width) {
                                Circle()
                                    .fill(Color(red: 1, green: 0.816, blue: 0.376))
                                    .frame(width: 5, height: 5)
                                    .offset(x: pipPosition - 2.5, y: -1.5)
                            }
                        }
                    }
                }
                .frame(height: 5)
                .padding(.top, 2)
            }

            // Play button
            Button {
                resumePlayback()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.mintAccent)
                        .frame(width: 30, height: 30)
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func pipPosition(for note: NoteEntity, width: CGFloat) -> CGFloat? {
        guard item.duration > 0,
              let timestampString = note.timestamp else { return nil }
        let seconds = parseTimestampToSeconds(timestampString)
        guard seconds > 0 else { return nil }
        return (seconds / item.duration) * width
    }

    private func parseTimestampToSeconds(_ timestamp: String) -> TimeInterval {
        // Handles "MM:SS" and "HH:MM:SS" formats
        let parts = timestamp.split(separator: ":").compactMap { Double($0) }
        switch parts.count {
        case 2: return parts[0] * 60 + parts[1]
        case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
        default: return 0
        }
    }

    private func resumePlayback() {
        // Use whatever method GlobalPlayerManager exposes to load from history.
        // From Phase 1 diagnosis, adapt this call to match the actual API.
        // Common patterns to try in order:
        //   player.loadFromHistory(item)
        //   player.resume(item)
        //   player.loadEpisode(audioURL: item.audioURL, at: item.currentTime)
        // Do NOT invent new methods. Use whichever exists.
        // If none match, log to Inbox and leave button as no-op for now.
    }
}
```

> **Note on `resumePlayback()`**: From the Phase 1 findings, fill in the correct `GlobalPlayerManager` call. Do not guess or invent new methods. If no clean existing method maps to loading a `PlaybackHistoryItem`, add an Inbox note in `docs/echocast_todo.md` and leave the button wired to `player.play()` as a stub.

---

### Step 5 — Create YourShowsSheetView

Add as a `private struct` at the bottom of `HomeView.swift`, below `ContinueListeningSheetRow`.

```swift
private struct YourShowsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var followedShows: [FollowedShowItem] = []
    @State private var showingSearch = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Shows")
                        .font(.system(size: 17, weight: .700))
                        .foregroundColor(.echoTextPrimary)
                    Text("\(followedShows.count) shows saved")
                        .font(.system(size: 12))
                        .foregroundColor(.echoTextTertiary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 15, weight: .600))
                    .foregroundColor(Color.mintAccent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    // Context blurb
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundColor(Color.mintAccent.opacity(0.7))
                            .padding(.top, 1)
                        Text("Shows you save here are easy to come back to — tap any show to jump straight to its latest episodes.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.45))
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .background(Color.mintAccent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mintAccent.opacity(0.18), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    // Show rows
                    ForEach(followedShows) { show in
                        YourShowsSheetRow(show: show, onUnfollow: {
                            unfollowShow(show)
                        })

                        if show.id != followedShows.last?.id {
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }

                    // Add a show row
                    Button {
                        dismiss()
                        // Navigate to search — post notification or set shared state
                        // that HomeView observes to open search
                        NotificationCenter.default.post(name: .openSearch, object: nil)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.25))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add a show")
                                    .font(.system(size: 14, weight: .600))
                                    .foregroundColor(.echoTextSecondary)
                                Text("Search to find a podcast")
                                    .font(.system(size: 11))
                                    .foregroundColor(.echoTextTertiary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(red: 0.118, green: 0.118, blue: 0.118))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { loadFollowedShows() }
    }

    private func loadFollowedShows() {
        // Read from UserDefaults — same pattern used in PodcastDetailView/NavigationUX-Implementation
        let ids = UserDefaults.standard.stringArray(forKey: "followedPodcasts") ?? []
        followedShows = ids.compactMap { id in
            guard let data = UserDefaults.standard.data(forKey: "podcast_\(id)"),
                  let podcast = try? JSONDecoder().decode(FollowedShowItem.self, from: data)
            else { return nil }
            return podcast
        }
        // Note: If the stored type is iTunesPodcast rather than FollowedShowItem,
        // adapt the decode type to match what PodcastDetailView actually encodes.
        // Check Phase 1 findings for the exact encoded type.
    }

    private func unfollowShow(_ show: FollowedShowItem) {
        var ids = UserDefaults.standard.stringArray(forKey: "followedPodcasts") ?? []
        ids.removeAll { $0 == show.id }
        UserDefaults.standard.set(ids, forKey: "followedPodcasts")
        UserDefaults.standard.removeObject(forKey: "podcast_\(show.id)")
        withAnimation { followedShows.removeAll { $0.id == show.id } }
    }
}
```

#### FollowedShowItem

Add this small model struct at the bottom of `HomeView.swift` (outside all view structs, at file scope). It should mirror only the fields that are actually encoded by `PodcastDetailView` when following. From Phase 1 findings, adapt accordingly — if the encoded type is `iTunesPodcast`, use that directly and skip this struct.

```swift
// Lightweight decodable mirror of followed show data stored in UserDefaults.
// Fields must match what PodcastDetailView encodes — verify in Phase 1.
private struct FollowedShowItem: Identifiable, Codable {
    let id: String
    let title: String
    let artworkUrl600: String?
    let feedUrl: String?
}
```

#### YourShowsSheetRow

```swift
private struct YourShowsSheetRow: View {
    let show: FollowedShowItem
    let onUnfollow: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: show.artworkUrl600 ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                default:
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundColor(.echoTextTertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.06))
                }
            }
            .frame(width: 52, height: 52)
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(show.title)
                    .font(.system(size: 14, weight: .600))
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onUnfollow()
            } label: {
                Label("Remove", systemImage: "minus.circle")
            }
        }
    }
}
```

#### Notification for "Add a show"

Add this extension at file scope in `HomeView.swift`:

```swift
extension Notification.Name {
    static let openSearch = Notification.Name("EchoCast.openSearch")
}
```

Then in `HomeView`, observe this notification and trigger the existing search flow:

```swift
.onReceive(NotificationCenter.default.publisher(for: .openSearch)) { _ in
    // Trigger whatever @State bool or action currently opens search in HomeView
    // From Phase 1: find the existing search trigger and wire it here
}
```

> If `Notification.Name.openSearch` already exists elsewhere in the codebase, use that one instead of defining a new one.

---

### Step 6 — Constraints

- Do **not** create any new Swift files. All new structs go at the bottom of `HomeView.swift`.
- Do **not** modify `GlobalPlayerManager`, `PlaybackHistoryManager`, or any player files.
- Do **not** modify Core Data models.
- Do **not** remove any existing `@State` vars or `.sheet` modifiers from `HomeView` — only add.
- The "Find more" / browse link currently in the Your Shows row may be removed — it is replaced by the "Add a show" row inside the sheet.
- Use `Color.echoTextPrimary`, `Color.echoTextSecondary`, `Color.echoTextTertiary`, `Color.mintAccent` from design tokens throughout. Do not hardcode hex values except for the sheet background `Color(red: 0.118, green: 0.118, blue: 0.118)` which matches `#1e1e1e`.
- Use `.sheet(isPresented:)` — not `.sheet(item:)` — for both sheets, as there is no selection item involved.

---

### Step 7 — Build and verify

```bash
xcodebuild -project EchoNotes.xcodeproj -scheme EchoNotes build 2>&1 | grep -E "error:|warning:|BUILD"
```

Fix any compiler errors before committing. Do not commit a broken build.

---

### Step 8 — Commit

```bash
git add EchoNotes/Views/HomeView.swift
git commit -m "T43: Add View All sheets for Continue Listening and Your Shows"
```

---

## When complete

Update `docs/echocast_todo.md`:
- Add commit ID to T43 progress notes
- Add any discovered issues to Inbox

---

## What is explicitly out of scope

Log to Inbox if encountered — do not implement:

- Per-show settings inside the Your Shows sheet (auto-download toggles etc.)
- "New episode" badge on show rows (requires RSS fetch — separate task)
- Tapping a show row to open PodcastDetailView from within the sheet (navigation from sheet is complex — stub with no-op tap for now and log to Inbox)
- Any changes to the Notes tab or player views
