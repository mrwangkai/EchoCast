# T42 — Activity-Driven Home Screen
**Claude Code Implementation Prompt**

---

## Preamble

Read `docs/echocast_todo.md` before starting. This task is T42.

When complete, mark T42 as complete in `docs/echocast_todo.md` with the commit ID.
If you discover any issues unrelated to this task, add them to the Inbox section of `docs/echocast_todo.md` — do not fix them inline.

---

## Context

We are refactoring `HomeView` so the home screen is driven by **user activity** (listening history, notes taken) rather than **intent** (following podcasts). The home screen should come alive after the very first play — no setup required.

Reference designs are in `docs/screenshots/` if available. The three target states are:

- **State A — Empty**: No activity at all. Single centered CTA. No sections rendered.
- **State B — Listening, no notes**: `Continue Listening` section visible. Note nudge card in place of empty notes section. Soft follow prompt below.
- **State C — Listening + notes**: `Continue Listening` and `Recent Notes` sections visible. Follow prompt is quieter, further down.
- **State D — Full**: All sections including `Your Podcasts` (only renders when ≥1 podcast is followed).

---

## Phase 1 — Diagnosis (read-only, stop and report)

Before writing any code, run the following targeted greps and report findings. **Do not make any changes in this phase.**

```bash
# 1. Where does HomeView currently live and what sections does it render?
grep -n "section\|Section\|VStack\|@FetchRequest\|@ObservedObject\|player\." EchoNotes/Views/HomeView.swift | head -60

# 2. What does PlaybackHistoryManager expose?
grep -n "var \|func \|struct \|class " EchoNotes/PlaybackHistoryManager.swift | head -40

# 3. What does GlobalPlayerManager expose that HomeView can observe?
grep -n "var \|@Published" EchoNotes/GlobalPlayerManager.swift | head -40

# 4. How is "following" currently determined? (UserDefaults or Core Data?)
grep -rn "followedPodcasts\|isFollowed\|PodcastEntity" EchoNotes/Views/HomeView.swift | head -20

# 5. What NoteEntity fields are available?
grep -n "var \|attribute\|relationship" EchoNotes/Models/EchoNotes.xcdatamodeld/EchoNotes*.xcdatamodel/contents 2>/dev/null || grep -rn "NoteEntity" EchoNotes/Models/ | head -20

# 6. Confirm PlaybackHistoryManager persists to disk
grep -n "UserDefaults\|save\|load\|encode\|decode" EchoNotes/PlaybackHistoryManager.swift | head -20
```

**Stop here.** Report what you found for each of the 6 checks, especially:
- What sections HomeView currently renders and what data drives each
- Whether `PlaybackHistoryManager.recentlyPlayed` survives app relaunch
- How "followed" state is stored (UserDefaults key vs Core Data `PodcastEntity`)
- What fields `NoteEntity` has (`episodeTitle`, `showTitle`, `createdAt`, `timestamp`, `noteText`)

Do not proceed to Phase 2 until you have reported findings.

---

## Phase 2 — Implementation

Proceed only after Phase 1 diagnosis is confirmed.

### Step 1 — Create branch

```bash
git checkout main
git pull origin main
git checkout -b t42-activity-home
```

### Step 2 — Refactor HomeView sections

**File: `EchoNotes/Views/HomeView.swift`**

Replace the current section rendering logic with the following conditional structure. Do not create new files — all changes go in `HomeView.swift` unless a subview already lives in its own file.

#### Data sources to wire up:

```swift
// Playback history — for Continue Listening
@ObservedObject private var historyManager = PlaybackHistoryManager.shared

// Player state — to know if something is actively loaded
@ObservedObject private var player = GlobalPlayerManager.shared

// Recent notes — from Core Data
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
    predicate: NSPredicate(format: "createdAt >= %@", Calendar.current.date(byAdding: .day, value: -7, to: Date())! as NSDate),
    animation: .default
)
private var recentNotes: FetchedResults<NoteEntity>

// Followed podcasts — from Core Data
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
    animation: .default
)
private var followedPodcasts: FetchedResults<PodcastEntity>
```

> **Note:** If `PodcastEntity` does not exist in Core Data and following is stored in UserDefaults instead, read the `followedPodcasts` key from UserDefaults as a `[String]`. Adapt accordingly — do not invent new persistence.

#### Section rendering logic:

```swift
var body: some View {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                
                // MARK: — Continue Listening
                // Show if: PlaybackHistoryManager.shared.recentlyPlayed is not empty
                if !historyManager.recentlyPlayed.isEmpty {
                    continueListeningSection
                        .padding(.bottom, 28)
                }
                
                // MARK: — Recent Notes
                // Show if: recentNotes is not empty
                // Show nudge card if: recentlyPlayed not empty BUT recentNotes IS empty
                if !recentNotes.isEmpty {
                    recentNotesSection
                        .padding(.bottom, 28)
                } else if !historyManager.recentlyPlayed.isEmpty {
                    noteNudgeCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
                
                // MARK: — Your Podcasts
                // Show only if at least 1 podcast is followed
                if !followedPodcasts.isEmpty {
                    yourPodcastsSection
                        .padding(.bottom, 28)
                }
                
                // MARK: — Follow prompt
                // Show if: something is playing AND the current podcast is not followed
                if !historyManager.recentlyPlayed.isEmpty && !followedPodcasts.isEmpty == false {
                    followPromptCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }
                
                // MARK: — Empty state
                // Show only if: no history AND no notes
                if historyManager.recentlyPlayed.isEmpty && recentNotes.isEmpty {
                    emptyStateView
                }
                
            }
            .padding(.top, 8)
        }
        .background(Color.echoBackground)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        // keep existing toolbar items unchanged
    }
}
```

---

#### Continue Listening section

Build the `continueListeningSection` view using `historyManager.recentlyPlayed`. Each item has:
- `episodeTitle: String`
- `podcastTitle: String`
- `currentTime: TimeInterval`
- `duration: TimeInterval`
- `artworkURL: String?` (use AsyncImage, fall back to `rectangle.fill` SF symbol)

Card layout (horizontal scroll, cards ~300pt wide):
- Artwork: 72×72pt, cornerRadius 10pt
- Show name: `.footnote` weight `.semibold`, `Color.mintAccent`, uppercase
- Episode title: `.subheadline` weight `.semibold`, 2-line limit
- Progress bar: 3pt height, `Color.mintAccent` fill, `Color.white.opacity(0.1)` track
- **Note pips**: Yellow dots (`Color(red: 1, green: 0.816, blue: 0.376)`, 6pt diameter) on the progress bar at positions corresponding to notes for this episode. Query `NoteEntity` where `episodeTitle == item.episodeTitle`, convert each note's timestamp string to `TimeInterval`, map to `(timestampSeconds / duration)` for horizontal position.
- Time remaining: `"\(formattedTimeRemaining) left"` — calculate as `duration - currentTime`
- Note count: `"· \(noteCount) note\(noteCount == 1 ? "" : "s")"` — only show if noteCount > 0
- Play button: 32pt mint circle, chevron right or play icon, tapping opens the player for that episode

Tapping the card should call `GlobalPlayerManager.shared` to resume the episode at `currentTime`. Use whatever method currently exists for loading an episode — do not invent new APIs on `GlobalPlayerManager`.

---

#### Recent Notes section

Build `recentNotesSection` using `recentNotes` (last 7 days, max 5 shown with "See all" link).

Card layout (vertical list, full width):
- **Top row**: Timestamp badge (left, mint background, `.caption` bold) + note text (right, `.footnote`, 3-line limit)
- **Divider**: `Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)` — no `Divider()`
- **Bottom row**: 32×32pt artwork thumbnail + episode title (`.caption` medium) + show name (`.caption2` tertiary)

Artwork for note cards: use `AsyncImage` with `note.showTitle` to look up `PodcastEntity.artworkURL` if available. Fall back to `music.note` SF symbol in a `Color.white.opacity(0.08)` rounded rect.

Tapping a note card should open the player for that episode at the note's timestamp, if the episode is in `PlaybackHistoryManager.shared.recentlyPlayed`.

---

#### Note nudge card (State B)

A single card shown instead of the Recent Notes section when there are no notes but listening history exists:

```swift
private var noteNudgeCard: some View {
    HStack(spacing: 12) {
        Image(systemName: "pencil.and.outline")
            .font(.system(size: 22))
            .foregroundColor(Color.mintAccent)
            .frame(width: 36)
        
        VStack(alignment: .leading, spacing: 3) {
            Text("Capture something worth keeping")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            Text("Tap the note button while listening to save a thought at any timestamp.")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(2)
        }
        
        Spacer()
        
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color.mintAccent.opacity(0.6))
    }
    .padding(14)
    .background(Color.mintAccent.opacity(0.07))
    .overlay(
        RoundedRectangle(cornerRadius: 14)
            .stroke(Color.mintAccent.opacity(0.18), lineWidth: 1)
    )
    .cornerRadius(14)
}
```

---

#### Follow prompt card

Show below Recent Notes when `historyManager.recentlyPlayed.first` is not nil and its `podcastTitle` is not in the followed list.

```swift
private var followPromptCard: some View {
    // Only show if current/most recent podcast is not followed
    guard let recent = historyManager.recentlyPlayed.first,
          !followedPodcasts.contains(where: { $0.title == recent.podcastTitle })
    else { return AnyView(EmptyView()) }
    
    return AnyView(
        HStack(spacing: 12) {
            Image(systemName: "bell")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Want new episodes automatically?")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text("Follow \(recent.podcastTitle) to never miss an episode.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button("Follow") {
                // Call existing follow logic — find the method used in PodcastDetailView
                // and replicate here. If following uses UserDefaults, append podcastID.
                // Do not invent new persistence.
            }
            .font(.system(size: 11, weight: .700))
            .foregroundColor(Color.mintAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.mintAccent.opacity(0.12))
            .cornerRadius(16)
        }
        .padding(14)
        .background(Color(red: 0.149, green: 0.149, blue: 0.149))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .cornerRadius(14)
    )
}
```

> If following is stored in UserDefaults (not Core Data), adapt the `followedPodcasts` check to read from UserDefaults instead. Do not change the follow persistence mechanism — just use what already exists.

---

#### Empty state (State A)

Replace the existing empty state with:

```swift
private var emptyStateView: some View {
    VStack(spacing: 0) {
        Spacer(minLength: 60)
        
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 80, height: 80)
                Image(systemName: "mic.fill")
                    .font(.system(size: 34))
                    .foregroundColor(.white.opacity(0.2))
            }
            
            VStack(spacing: 8) {
                Text("Your listening journal")
                    .font(.system(size: 21, weight: .700))
                    .foregroundColor(.white)
                
                Text("Find a podcast, hit play, and take your first note.\nEchoCast builds your home screen from what you\nactually listen to.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            
            Button(action: { /* trigger search — use existing search navigation */ }) {
                Text("Find a podcast")
                    .font(.system(size: 15, weight: .700))
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 13)
                    .background(Color.mintAccent)
                    .cornerRadius(24)
            }
        }
        .padding(.horizontal, 36)
        
        Spacer(minLength: 60)
    }
    .frame(maxWidth: .infinity)
}
```

---

### Step 3 — Constraints

- Do **not** create any new Swift files. All changes in `HomeView.swift` (and its existing subview files if they exist separately).
- Do **not** add new fields to `NoteEntity` or `PodcastEntity` Core Data models.
- Do **not** modify `GlobalPlayerManager`, `PlaybackHistoryManager`, or any player files.
- Do **not** change navigation structure, tab bar, or mini player.
- Preserve all existing `@State` sheet variables and their bindings — do not remove any sheet presentations.
- Use `Color(red: 0.149, green: 0.149, blue: 0.149)` for card backgrounds (not semantic UIColor tokens).

---

### Step 4 — Build and verify

```bash
xcodebuild -project EchoNotes.xcodeproj -scheme EchoNotes build | tail -20
```

Fix any compiler errors. Do not proceed if build fails.

---

### Step 5 — Commit

```bash
git add EchoNotes/Views/HomeView.swift
git commit -m "T42: Activity-driven home screen — conditional sections, note pips, empty state"
```

---

## When complete

Update `docs/echocast_todo.md`:
- Mark T42 as ✅ Complete
- Add commit ID
- Add any discovered issues to the Inbox

---

## What is explicitly out of scope

Do not implement these — log them to Inbox if you think they're needed:

- Playback position persistence to Core Data (separate task)
- Auto-download follow preferences
- Note streak card
- Per-podcast settings sheet
- "Remove download" action
