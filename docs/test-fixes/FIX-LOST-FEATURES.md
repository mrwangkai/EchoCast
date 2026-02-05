# Recovering Lost Features - Post-Deduplication

## Issues Identified

### 1. Browse Experience Regression
**Lost:** Horizontal carousel with genre chips (Comedy, News, True Crime, etc.)
**Current:** Basic search only
**Evidence:** Development Status Report mentions `PodcastBrowseViewModel` with genre filtering

### 2. RSS vs iTunes Data Loading Issues
**Problem:** Album artwork not loading, episodes showing "No episodes found"
**Cause:** Likely switched from working RSS implementation to iTunes-only
**Evidence:** App has both `PodcastRSSService` and `PodcastAPIService`

### 3. Missing "Following" Section on Home
**Lost:** 3-section home screen (Continue Listening, Following, Recent Notes)
**Current:** Only Continue Listening + Recent Notes
**Evidence:** User confirms this existed in lost version

### 4. Note Detail/Edit Sheet Missing
**Lost:** Tap note → Opens detail sheet with edit option
**Current:** Unknown behavior when tapping note
**Expected:** Reuse AddNoteSheet for editing

---

## RECOVERY PLAN

### Phase A: Fix Browse Experience (1-2 hours)
Restore genre-based carousel browsing

### Phase B: Fix RSS Episode Loading (30 min - 1 hour)
Ensure episodes load with artwork

### Phase C: Add Following Section to Home (1 hour)
Implement podcast following feature

### Phase D: Wire Up Note Detail/Edit (30 min)
Reuse AddNoteSheet for editing notes

---

## PHASE A: Restore Browse Genre Carousel

### Goal
Restore horizontal scrolling genre chips at top of browse view with podcasts by genre below.

### Files to Check/Update
- `PodcastDiscoveryView.swift` (current browse view)
- `PodcastBrowseRealView.swift` (old browse view - might have carousel)
- `PodcastBrowseViewModel.swift` (has genre logic)
- `PodcastGenre.swift` (genre definitions)

### Implementation

#### Step 1: Check if PodcastBrowseRealView Has Carousel

```bash
# Check if old browse view still exists with carousel
grep -n "ScrollView.*horizontal\|genre.*chip\|category" EchoNotes/Views/PodcastBrowseRealView.swift

# Check what PodcastDiscoveryView currently has
grep -n "struct PodcastDiscoveryView" EchoNotes/Views/PodcastDiscoveryView.swift
```

#### Step 2: Restore Genre Carousel to Browse View

The browse view should have:

1. **Search bar** at top
2. **Horizontal genre chips** (scrollable carousel)
3. **Podcasts by genre** below (vertical scroll)

**Target structure:**
```swift
struct PodcastDiscoveryView: View {
    @StateObject private var viewModel = PodcastBrowseViewModel()
    @State private var selectedGenre: PodcastGenre?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Horizontal genre chips
                genreChipsScrollView
                
                // Podcasts list (changes based on selected genre)
                podcastsList
            }
            .navigationTitle("Browse")
        }
        .task {
            await viewModel.loadGenres()
        }
    }
    
    // MARK: - Genre Chips Carousel
    
    private var genreChipsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PodcastGenre.mainGenres) { genre in
                    GenreChip(
                        genre: genre,
                        isSelected: selectedGenre == genre,
                        action: {
                            selectedGenre = genre
                            Task {
                                await viewModel.loadPodcasts(for: genre)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
            .padding(.vertical, 12)
        }
        .background(Color.echoBackground)
    }
}

// MARK: - Genre Chip Component

struct GenreChip: View {
    let genre: PodcastGenre
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: genre.iconName)
                    .font(.system(size: 14))
                
                Text(genre.displayName)
                    .font(.subheadlineRounded())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.mintAccent : Color.noteCardBackground)
            .foregroundColor(isSelected ? Color.mintButtonText : Color.echoTextPrimary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
```

#### Step 3: Verify PodcastGenre.swift Exists

Check if genre definitions exist:
```bash
cat EchoNotes/Models/PodcastGenre.swift
```

If missing, create it:
```swift
//
//  PodcastGenre.swift
//  EchoNotes
//

import Foundation

enum PodcastGenre: String, Identifiable, CaseIterable {
    case all = "0"
    case comedy = "1303"
    case news = "1489"
    case trueCrime = "1488"
    case sports = "1545"
    case business = "1321"
    case education = "1304"
    case arts = "1301"
    case health = "1512"
    case tvFilm = "1309"
    case music = "1310"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .comedy: return "Comedy"
        case .news: return "News"
        case .trueCrime: return "True Crime"
        case .sports: return "Sports"
        case .business: return "Business"
        case .education: return "Education"
        case .arts: return "Arts"
        case .health: return "Health & Fitness"
        case .tvFilm: return "TV & Film"
        case .music: return "Music"
        }
    }
    
    var iconName: String {
        switch self {
        case .all: return "star.fill"
        case .comedy: return "face.smiling"
        case .news: return "newspaper.fill"
        case .trueCrime: return "magnifyingglass"
        case .sports: return "sportscourt.fill"
        case .business: return "briefcase.fill"
        case .education: return "graduationcap.fill"
        case .arts: return "paintpalette.fill"
        case .health: return "heart.fill"
        case .tvFilm: return "tv.fill"
        case .music: return "music.note"
        }
    }
    
    static var mainGenres: [PodcastGenre] {
        [.all, .comedy, .news, .trueCrime, .sports, .business, .education]
    }
}
```

---

## PHASE B: Fix RSS Episode Loading

### Problem
Episodes not loading when tapping podcast, showing "No episodes found"
Album artwork not displaying

### Root Cause Analysis

The app has TWO podcast systems:
1. **iTunes Search** - For discovery (works)
2. **RSS Parsing** - For episode details (broken?)

When you tap a podcast from search:
1. iTunes gives you podcast metadata + feed URL
2. App should fetch RSS feed to get episodes
3. Parse episodes from RSS

**Likely issue:** RSS fetching broken or not being called

### Files to Check
- `PodcastDetailView.swift` or similar (podcast detail sheet)
- `PodcastRSSService.swift` (RSS parsing)
- How podcast detail view loads episodes

### Step 1: Find Podcast Detail View

```bash
# Find where podcast detail is shown
find EchoNotes/Views -name "*Podcast*Detail*.swift"

# Check what happens when tapping podcast
grep -rn "iTunesPodcast.*sheet\|iTunesPodcast.*NavigationLink" EchoNotes/Views
```

### Step 2: Verify RSS Service Works

```bash
# Check if RSS service exists
cat EchoNotes/Services/PodcastRSSService.swift | head -50

# Check if it's being called
grep -rn "PodcastRSSService\|fetchEpisodes\|parseFeed" EchoNotes/Views
```

### Step 3: Fix Episode Loading

**In PodcastDetailView (or equivalent):**

```swift
struct PodcastDetailView: View {
    let podcast: iTunesPodcast  // From search
    
    @State private var episodes: [RSSEpisode] = []
    @State private var isLoadingEpisodes = false
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Podcast header with artwork
                podcastHeader
                
                // Episodes list
                if isLoadingEpisodes {
                    ProgressView("Loading episodes...")
                } else if episodes.isEmpty {
                    Text("No episodes found")
                        .foregroundColor(.echoTextSecondary)
                } else {
                    episodesList
                }
            }
        }
        .task {
            await loadEpisodes()
        }
    }
    
    private func loadEpisodes() async {
        guard let feedURL = podcast.feedUrl else {
            errorMessage = "No feed URL available"
            return
        }
        
        isLoadingEpisodes = true
        
        do {
            let rssService = PodcastRSSService()
            episodes = try await rssService.fetchEpisodes(from: feedURL)
        } catch {
            errorMessage = "Failed to load episodes: \(error.localizedDescription)"
            print("❌ RSS Error: \(error)")
        }
        
        isLoadingEpisodes = false
    }
}
```

### Step 4: Fix Album Artwork Loading

**Artwork loading issues usually caused by:**
1. URL is nil or invalid
2. Image not being cached
3. AsyncImage not configured correctly

**Fix:**
```swift
// In podcast row or card
AsyncImage(url: URL(string: podcast.artworkUrl600 ?? "")) { phase in
    switch phase {
    case .empty:
        ProgressView()
            .frame(width: 88, height: 88)
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    case .failure:
        Image(systemName: "music.note")
            .font(.system(size: 32))
            .foregroundColor(.echoTextTertiary)
            .frame(width: 88, height: 88)
            .background(Color.noteCardBackground)
    @unknown default:
        EmptyView()
    }
}
.frame(width: 88, height: 88)
.cornerRadius(12)
```

---

## PHASE C: Add Following Section to Home

### Goal
3-section home screen:
1. Continue Listening
2. Following (podcasts user has followed)
3. Recent Notes

### Implementation

#### Step 1: Add Follow/Unfollow Functionality

**Create or update PodcastEntity in Core Data to track followed podcasts**

Check if following is already tracked:
```bash
grep -rn "isFollowing\|followed\|subscribe" EchoNotes/Models
```

#### Step 2: Update HomeView with Following Section

```swift
struct HomeView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        predicate: NSPredicate(format: "isFollowing == true"),
        animation: .default
    )
    private var followedPodcasts: FetchedResults<PodcastEntity>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // 1. Continue Listening
                    if player.currentEpisode != nil {
                        continueListeningSection
                    }
                    
                    // 2. Following (NEW)
                    if !followedPodcasts.isEmpty {
                        followingSection
                    }
                    
                    // 3. Recent Notes
                    if !recentNotes.isEmpty {
                        recentNotesSection
                    } else if followedPodcasts.isEmpty && player.currentEpisode == nil {
                        emptyStateView
                    }
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
            }
        }
    }
    
    // MARK: - Following Section
    
    private var followingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Following")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(followedPodcasts) { podcast in
                        PodcastFollowingCard(podcast: podcast)
                    }
                }
            }
        }
    }
}

// MARK: - Following Card Component

struct PodcastFollowingCard: View {
    let podcast: PodcastEntity
    
    var body: some View {
        VStack(spacing: 8) {
            // Album artwork
            AsyncImage(url: URL(string: podcast.artworkURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.noteCardBackground
            }
            .frame(width: 120, height: 120)
            .cornerRadius(12)
            
            // Podcast title
            Text(podcast.title ?? "Unknown")
                .font(.captionRounded())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120)
        }
        .onTapGesture {
            // Open podcast detail
        }
    }
}
```

#### Step 3: Add Follow Button to Podcast Detail

```swift
// In PodcastDetailView
Button(action: {
    toggleFollow()
}) {
    HStack {
        Image(systemName: isFollowing ? "checkmark" : "plus")
        Text(isFollowing ? "Following" : "Follow")
    }
    .font(.bodyRoundedMedium())
    .foregroundColor(isFollowing ? Color.echoTextPrimary : Color.mintButtonText)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(isFollowing ? Color.noteCardBackground : Color.mintAccent)
    .cornerRadius(8)
}
```

---

## PHASE D: Wire Up Note Detail/Edit

### Goal
Tap note → Opens sheet with note details + edit button → Reuses AddNoteSheet

### Implementation

#### Step 1: Make AddNoteSheet Support Editing

```swift
struct AddNoteSheet: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    let existingNote: NoteEntity?  // NEW: nil for new note, populated for editing
    let dismiss: () -> Void
    
    @State private var noteContent: String = ""
    @State private var isPriority: Bool = false
    @State private var tags: [String] = []
    
    init(episode: RSSEpisode, podcast: PodcastEntity, existingNote: NoteEntity? = nil, dismiss: @escaping () -> Void) {
        self.episode = episode
        self.podcast = podcast
        self.existingNote = existingNote
        self.dismiss = dismiss
        
        // Pre-populate if editing
        if let note = existingNote {
            _noteContent = State(initialValue: note.noteText ?? "")
            _isPriority = State(initialValue: note.isPriority)
            _tags = State(initialValue: note.tagsArray)
        }
    }
    
    var body: some View {
        // ... existing UI
        
        // Save button title changes
        Button {
            saveNote()
        } label: {
            Text(existingNote == nil ? "Save note" : "Update note")
                .font(.bodyRoundedMedium())
        }
    }
    
    private func saveNote() {
        if let existing = existingNote {
            // Update existing note
            existing.noteText = noteContent
            existing.isPriority = isPriority
            existing.tags = tags.joined(separator: ",")
            PersistenceController.shared.saveContext()
        } else {
            // Create new note
            PersistenceController.shared.createNote(
                // ... existing creation logic
            )
        }
        dismiss()
    }
}
```

#### Step 2: Add Note Detail Sheet

```swift
struct NoteDetailSheet: View {
    let note: NoteEntity
    @State private var showingEditSheet = false
    let dismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Episode context
                    VStack(alignment: .leading, spacing: 8) {
                        if let showTitle = note.showTitle {
                            Text(showTitle)
                                .font(.captionRounded())
                                .foregroundColor(.echoTextSecondary)
                        }
                        
                        if let episodeTitle = note.episodeTitle {
                            Text(episodeTitle)
                                .font(.bodyRoundedMedium())
                                .foregroundColor(.echoTextPrimary)
                        }
                    }
                    
                    Divider()
                    
                    // Note content
                    Text(note.noteText ?? "")
                        .font(.bodyEcho())
                        .foregroundColor(.echoTextPrimary)
                    
                    // Timestamp
                    if let timestamp = note.timestamp {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text(timestamp)
                        }
                        .font(.caption2Medium())
                        .foregroundColor(.mintAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.mintAccent.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    // Tags
                    if !note.tagsArray.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(note.tagsArray, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2Medium())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.noteCardBackground)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(EchoSpacing.screenPadding)
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.mintAccent)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .foregroundColor(.mintAccent)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            // Reuse AddNoteSheet for editing
            if let episode = getRSSEpisodeForNote(note),
               let podcast = getPodcastForNote(note) {
                AddNoteSheet(
                    episode: episode,
                    podcast: podcast,
                    existingNote: note,  // Pass existing note
                    dismiss: {
                        showingEditSheet = false
                        dismiss()  // Close detail sheet too
                    }
                )
            }
        }
    }
}
```

#### Step 3: Wire Up Note Card Tap

```swift
// In HomeView or LibraryView where notes are displayed
NoteCardView(note: note)
    .onTapGesture {
        selectedNote = note
        showingNoteDetail = true
    }

// Add state and sheet
@State private var selectedNote: NoteEntity?
@State private var showingNoteDetail = false

.sheet(isPresented: $showingNoteDetail) {
    if let note = selectedNote {
        NoteDetailSheet(note: note, dismiss: {
            showingNoteDetail = false
        })
    }
}
```

---

## CLAUDE CODE PROMPT - RECOVER ALL FEATURES

```
TASK: Recover 4 Lost Features

Read and implement: FIX-LOST-FEATURES.md

Execute all 4 phases:

PHASE A: Restore Browse Genre Carousel
- Check if PodcastBrowseRealView has carousel code
- Add horizontal scrolling genre chips to PodcastDiscoveryView
- Create GenreChip component
- Verify PodcastGenre.swift exists with icons
- Wire up genre selection to filter podcasts
- Test: Genre chips scroll horizontally, tap chip filters podcasts

PHASE B: Fix RSS Episode Loading
- Find PodcastDetailView or equivalent
- Verify RSS service is being called when tapping podcast
- Fix episode loading to use PodcastRSSService
- Fix album artwork loading with proper AsyncImage
- Add loading states and error handling
- Test: Episodes load, artwork displays, no "No episodes found"

PHASE C: Add Following Section to Home
- Add Following section between Continue Listening and Recent Notes
- Create horizontal scrolling podcast cards
- Add Follow/Unfollow button to podcast detail
- Store following state in PodcastEntity
- Test: Can follow podcasts, they appear on home

PHASE D: Wire Up Note Detail/Edit
- Update AddNoteSheet to support editing mode
- Create NoteDetailSheet component
- Wire up note card tap to open detail
- Test: Tap note → detail sheet → Edit button → reuses AddNoteSheet

COMMIT after each phase.
Document progress in docs/feature-recovery-progress.md
```

---

**END OF RECOVERY GUIDE**
