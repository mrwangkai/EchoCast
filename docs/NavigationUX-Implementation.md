# Browse Navigation Implementation Guide

**Objective:** Convert the podcast Browse/Search flow from nested sheets to a NavigationStack pattern, eliminating 3-layer sheet nesting and providing proper back navigation.

**Pattern:** Option 1 - NavigationStack with back buttons

---

## Current Problem

```
Home Screen
  ↓ (sheet)
Browse View
  ↓ (sheet within sheet)
Podcast Detail View
  ↓ (sheet within sheet within sheet)
Individual Player View ❌ 3 nested sheets!
```

## Target Solution

```
NavigationStack
├── Home Screen (base)
│   ↓ (push navigation)
├── Browse View (with < Back to Home)
│   ↓ (push navigation)
├── Podcast Detail View (with < Back to Browse)
│   ↓ (sheet - only modal)
└── Individual Player View ✅ Only 1 sheet!
```

---

## Implementation Steps

### Step 1: Understand Current Code Structure

**Current implementation uses:**
- `ContentView.swift` - Main tab container
- `HomeView.swift` - Has Browse button that opens sheet
- `PodcastBrowseRealView.swift` - Browse view (currently in sheet)
- `PodcastDetailSheetView.swift` - Podcast detail (currently in nested sheet)
- Individual Player - (currently in triple-nested sheet)

**Current state variables:**
```swift
// In HomeView.swift
@State private var showingPodcastSearch = false

.sheet(isPresented: $showingPodcastSearch) {
    PodcastBrowseRealView()
}
```

### Step 2: Create Navigation Destination Enum

**Create a new file:** `NavigationDestination.swift`

```swift
//
//  NavigationDestination.swift
//  EchoNotes
//
//  Navigation destinations for app-wide navigation
//

import Foundation

enum AppDestination: Hashable {
    case browse
    case podcastDetail(podcast: iTunesPodcast)
    case episodeDetail(episode: RSSEpisode, podcast: iTunesPodcast)
}

// Make iTunesPodcast Hashable for navigation
extension iTunesPodcast: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: iTunesPodcast, rhs: iTunesPodcast) -> Bool {
        lhs.id == rhs.id
    }
}

// Make RSSEpisode Hashable for navigation
extension RSSEpisode: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: RSSEpisode, rhs: RSSEpisode) -> Bool {
        lhs.id == rhs.id
    }
}
```

**Why this is needed:** NavigationStack needs Hashable types to track the navigation path.

---

### Step 3: Update ContentView.swift

**Wrap the TabView in NavigationStack:**

**Find this code** (around line 50-80):
```swift
TabView(selection: $selectedTab) {
    HomeView()
        .tag(0)
    // ... other tabs
}
```

**Replace with:**
```swift
NavigationStack(path: $navigationPath) {
    TabView(selection: $selectedTab) {
        HomeView()
            .tag(0)
        
        LibraryView()
            .tag(1)
        
        Text("Settings")
            .tag(2)
    }
    .navigationDestination(for: AppDestination.self) { destination in
        switch destination {
        case .browse:
            PodcastBrowseNavigationView()
        case .podcastDetail(let podcast):
            PodcastDetailNavigationView(podcast: podcast)
        case .episodeDetail(let episode, let podcast):
            // This might not be needed - episodes usually open player sheet
            EmptyView()
        }
    }
}
.sheet(isPresented: $showFullPlayer) {
    // Player sheet - the ONLY sheet for playback
    if let episode = playerEpisode, let podcast = playerPodcast {
        FullPlayerView(episode: episode, podcast: podcast)
    }
}
```

**Add state variable at top of ContentView:**
```swift
@State private var navigationPath = NavigationPath()
@State private var playerEpisode: RSSEpisode?
@State private var playerPodcast: iTunesPodcast?
@State private var showFullPlayer = false
```

---

### Step 4: Update HomeView.swift

**Remove sheet-based Browse, add navigation:**

**Find this code** (around line 20):
```swift
@State private var showingPodcastSearch = false
```

**Delete it.**

**Find this code** (around line 50-60):
```swift
.sheet(isPresented: $showingPodcastSearch) {
    PodcastBrowseRealView()
}
```

**Delete it.**

**Find the Browse button** (around line 167-178):
```swift
Button(action: {
    showingPodcastSearch = true
}) {
    Text("Find your podcast")
        .font(.system(size: 17, weight: .medium, design: .rounded))
        .foregroundColor(Color(red: 0.647, green: 0.898, blue: 0.847))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(red: 0.102, green: 0.235, blue: 0.204))
        .cornerRadius(8)
}
```

**Replace with:**
```swift
NavigationLink(value: AppDestination.browse) {
    Text("Find your podcast")
        .font(.system(size: 17, weight: .medium, design: .rounded))
        .foregroundColor(Color(red: 0.647, green: 0.898, blue: 0.847))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(red: 0.102, green: 0.235, blue: 0.204))
        .cornerRadius(8)
}
.buttonStyle(.plain)
```

**If there's a settings button that opens a sheet:**
```swift
// Keep this as a sheet - Settings is a modal task
.sheet(isPresented: $showingSettings) {
    SettingsView()
}
```

---

### Step 5: Create PodcastBrowseNavigationView

**Create new file:** `PodcastBrowseNavigationView.swift`

This is a wrapper around the existing `PodcastBrowseRealView` that:
- Removes the Close button (navigation provides back button)
- Removes sheet-specific code
- Uses NavigationLink instead of sheet for podcast details

```swift
//
//  PodcastBrowseNavigationView.swift
//  EchoNotes
//
//  Browse view adapted for NavigationStack (not sheet)
//

import SwiftUI

struct PodcastBrowseNavigationView: View {
    @StateObject private var viewModel = PodcastBrowseViewModel()
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Search bar
                searchField
                
                // Category chips
                categoryChips
                
                // Results
                if let selectedGenre = viewModel.selectedGenre {
                    genreResultsView(genre: selectedGenre)
                } else {
                    allGenresResultsView
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
        .background(Color(red: 0.149, green: 0.149, blue: 0.149))
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Search Field
    
    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search for podcast", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onSubmit {
                    isSearchFocused = false
                    Task {
                        await viewModel.performSearch()
                    }
                }
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                    isSearchFocused = false
                    Task {
                        await viewModel.refresh()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            Button(action: {
                isSearchFocused = false
                Task {
                    await viewModel.performSearch()
                }
            }) {
                Text("Search")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.0, green: 0.784, blue: 0.702))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        .cornerRadius(10)
    }
    
    // MARK: - Category Chips
    
    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                genreChip(nil, name: "All", icon: "square.grid.2x2")
                
                ForEach(PodcastGenre.mainGenres) { genre in
                    genreChip(genre, name: genre.displayName, icon: genre.iconName)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func genreChip(_ genre: PodcastGenre?, name: String, icon: String) -> some View {
        let isSelected = viewModel.selectedGenre == genre
        
        return Button(action: {
            viewModel.selectedGenre = genre
            Task {
                if let genre = genre {
                    await viewModel.loadGenreResults(genre: genre)
                } else {
                    await viewModel.loadAllGenresResults()
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(name)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color(red: 0.0, green: 0.784, blue: 0.702) : Color(red: 0.2, green: 0.2, blue: 0.2))
            .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Genre Results
    
    private var allGenresResultsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(viewModel.genreResults.keys.sorted(by: { $0.displayName < $1.displayName })), id: \.self) { genre in
                if let podcasts = viewModel.genreResults[genre], !podcasts.isEmpty {
                    GenreSection(
                        genre: genre,
                        podcasts: podcasts
                    )
                }
            }
        }
    }
    
    private func genreResultsView(genre: PodcastGenre) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            if let podcasts = viewModel.genreResults[genre], !podcasts.isEmpty {
                GenreSection(
                    genre: genre,
                    podcasts: podcasts
                )
            }
        }
    }
}

// MARK: - Genre Section Component

struct GenreSection: View {
    let genre: PodcastGenre
    let podcasts: [iTunesPodcast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: genre.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(genre.displayName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(podcasts.prefix(10)) { podcast in
                        NavigationLink(value: AppDestination.podcastDetail(podcast: podcast)) {
                            PodcastCard(podcast: podcast)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Podcast Card Component

struct PodcastCard: View {
    let podcast: iTunesPodcast
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: podcast.artworkUrl600 ?? podcast.artworkUrl100 ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty, .failure, @unknown default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "podcast.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
            .frame(width: 140, height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(podcast.collectionName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 140, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        PodcastBrowseNavigationView()
    }
}
```

---

### Step 6: Create PodcastDetailNavigationView

**Create new file:** `PodcastDetailNavigationView.swift`

This replaces `PodcastDetailSheetView` for navigation context:

```swift
//
//  PodcastDetailNavigationView.swift
//  EchoNotes
//
//  Podcast detail view adapted for NavigationStack (not sheet)
//

import SwiftUI

struct PodcastDetailNavigationView: View {
    let podcast: iTunesPodcast
    
    @State private var episodes: [RSSEpisode] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isFollowed = false
    
    // For opening player sheet
    @State private var selectedEpisode: RSSEpisode?
    @State private var showPlayer = false
    
    var body: some View {
        ZStack {
            Color(red: 0.149, green: 0.149, blue: 0.149)
                .ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if episodes.isEmpty {
                emptyView
            } else {
                episodeListView
            }
        }
        .navigationTitle(podcast.collectionName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadFollowState()
        }
        .task {
            await loadEpisodes()
        }
        .sheet(isPresented: $showPlayer) {
            if let episode = selectedEpisode {
                // Open player sheet
                PlayerSheetWrapper(
                    episode: episode,
                    podcast: podcast,
                    dismiss: { showPlayer = false }
                )
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.0, green: 0.784, blue: 0.702)))
                .scaleEffect(1.2)
            
            Text("Loading episodes...")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Unable to load episodes")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "podcast")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No episodes available")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var episodeListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Podcast header
                podcastHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                
                // Episodes list
                VStack(alignment: .leading, spacing: 0) {
                    Text("Episodes")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    
                    ForEach(episodes) { episode in
                        EpisodeRow(
                            episode: episode,
                            onTap: {
                                selectedEpisode = episode
                                showPlayer = true
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }
    
    private var podcastHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Artwork
            AsyncImage(url: URL(string: podcast.artworkUrl600 ?? podcast.artworkUrl100 ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .empty, .failure, @unknown default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "podcast.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Title and artist
            VStack(alignment: .leading, spacing: 4) {
                Text(podcast.collectionName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(podcast.artistName)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Description
            if let description = podcast.longDescription ?? podcast.shortDescription {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .lineSpacing(4)
            }
            
            // Follow button
            Button(action: toggleFollow) {
                HStack {
                    Image(systemName: isFollowed ? "checkmark" : "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text(isFollowed ? "Following" : "Follow")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(isFollowed ? .white : Color(red: 0.0, green: 0.784, blue: 0.702))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isFollowed ? Color(red: 0.0, green: 0.784, blue: 0.702) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(red: 0.0, green: 0.784, blue: 0.702), lineWidth: 2)
                )
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadFollowState() {
        let followedPodcasts = UserDefaults.standard.stringArray(forKey: "followedPodcasts") ?? []
        isFollowed = followedPodcasts.contains(podcast.id)
    }
    
    private func toggleFollow() {
        var followedPodcasts = UserDefaults.standard.stringArray(forKey: "followedPodcasts") ?? []
        
        if isFollowed {
            followedPodcasts.removeAll { $0 == podcast.id }
            isFollowed = false
        } else {
            followedPodcasts.append(podcast.id)
            isFollowed = true
            
            // Save podcast details
            if let data = try? JSONEncoder().encode(podcast) {
                UserDefaults.standard.set(data, forKey: "podcast_\(podcast.id)")
            }
        }
        
        UserDefaults.standard.set(followedPodcasts, forKey: "followedPodcasts")
    }
    
    private func loadEpisodes() async {
        guard let feedUrl = podcast.feedUrl else {
            errorMessage = "No feed URL available"
            isLoading = false
            return
        }
        
        do {
            episodes = try await PodcastRSSService.shared.fetchEpisodes(from: feedUrl)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Episode Row Component

struct EpisodeRow: View {
    let episode: RSSEpisode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Play button
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 0.0, green: 0.784, blue: 0.702))
                
                // Episode info
                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let date = episode.pubDate {
                        Text(formatDate(date))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if let duration = episode.duration {
                        Text(duration)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        PodcastDetailNavigationView(
            podcast: iTunesPodcast(
                id: "1",
                trackId: 1,
                collectionName: "This American Life",
                artistName: "This American Life",
                collectionId: 1,
                artworkUrl600: nil,
                feedUrl: "https://feeds.thisamericanlife.org/talpodcast"
            )
        )
    }
}
```

---

### Step 7: Create PlayerSheetWrapper (if not exists)

**Create new file:** `PlayerSheetWrapper.swift`

This wraps the existing player for sheet presentation:

```swift
//
//  PlayerSheetWrapper.swift
//  EchoNotes
//
//  Wrapper for presenting the full player as a sheet
//

import SwiftUI

struct PlayerSheetWrapper: View {
    let episode: RSSEpisode
    let podcast: iTunesPodcast
    let dismiss: () -> Void
    
    @StateObject private var player = GlobalPlayerManager.shared
    
    var body: some View {
        // Use your existing FullPlayerView or AudioPlayerView
        // This is just a wrapper to pass the episode/podcast data
        
        VStack {
            // Header with minimize button
            HStack {
                Button(action: dismiss) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding()
            
            // Your existing player UI
            // AudioPlayerView(episode: episode, podcast: podcast)
            // Or whatever your current player component is called
            
            Text("Full Player View")
                .foregroundColor(.white)
            
            Spacer()
        }
        .background(Color(red: 0.149, green: 0.149, blue: 0.149))
        .onAppear {
            // Load episode into player
            // player.loadEpisode(episode, podcast: podcast)
        }
    }
}
```

**Note:** Replace the placeholder content with your actual player UI (AudioPlayerView, FullPlayerView, etc.)

---

### Step 8: Update PodcastBrowseViewModel

**In `PodcastBrowseViewModel.swift`:**

**Remove these @Published properties** (no longer needed for sheet management):
```swift
// DELETE THESE:
@Published var selectedPodcast: iTunesPodcast?
@Published var genreForViewAll: PodcastGenre?
```

**Keep these:**
```swift
@Published var searchText: String = ""
@Published var selectedGenre: PodcastGenre?
@Published var genreResults: [PodcastGenre: [iTunesPodcast]] = [:]
@Published var searchResults: [iTunesPodcast] = []
@Published var state: ViewState = .loading
@Published var isLoadingGenre = false
```

The navigation is now handled by NavigationLink, not @Published state.

---

### Step 9: Clean Up Old Sheet Code

**Delete or archive these files** (they're replaced by navigation versions):
- ❌ `PodcastBrowseView.swift` (the mock version with fake data)
- ❌ Any other sheet-specific browse views

**Keep these files:**
- ✅ `PodcastBrowseRealView.swift` (might be useful as reference, but not used anymore)
- ✅ `PodcastDetailSheetView.swift` (might be useful as reference, but not used anymore)

---

### Step 10: Testing Checklist

After implementation, verify these flows:

**Browse Flow:**
- [ ] Tap "Find your podcast" on Home screen
- [ ] Browse view slides in from right (navigation animation)
- [ ] See "< Back" button in top-left (NOT "✕ Close")
- [ ] Tap "< Back" - returns to Home screen
- [ ] Tap podcast card
- [ ] Podcast detail slides in from right
- [ ] See "< Browse" button in top-left
- [ ] Tap "< Browse" - returns to Browse view
- [ ] Tap episode
- [ ] Player sheet pulls up from bottom (modal)
- [ ] Swipe down or tap minimize - player sheet dismisses
- [ ] Still on Podcast Detail screen (NOT Home screen)

**Navigation Stack Depth:**
- [ ] Home → Browse → Podcast Detail = 3 levels ✅
- [ ] Player is always a sheet, not part of navigation stack ✅

**Back Navigation:**
- [ ] From Podcast Detail → "< Browse" works
- [ ] From Browse → "< Back" works (returns to Home)
- [ ] Swipe from left edge works for back navigation

**No Dead Ends:**
- [ ] Never stuck on Browse with no way back
- [ ] Never stuck on Podcast Detail with no way back
- [ ] Player can always be dismissed

**Mini Player:**
- [ ] Mini player appears after playing episode
- [ ] Tapping mini player opens player sheet
- [ ] Mini player persists across Browse/Podcast Detail navigation
- [ ] Mini player stays above tab bar

---

### Step 11: Handle Edge Cases

**What if user is deep in navigation and switches tabs?**

**Add this to ContentView:**
```swift
TabView(selection: $selectedTab) {
    // ...
}
.onChange(of: selectedTab) { oldValue, newValue in
    // Clear navigation stack when switching tabs
    if oldValue != newValue {
        navigationPath = NavigationPath()
    }
}
```

**What if user wants to browse while player is open?**

This works fine - player is a sheet, so:
- Player sheet is open
- User can still navigate underneath (Browse → Podcast Detail)
- When dismissing player, they're back where they were

---

## Success Criteria

✅ **Implementation is successful when:**

1. **No nested sheets** - Only player is a sheet
2. **Back navigation works** - Can always go back from Browse and Podcast Detail
3. **No dead ends** - Never stuck without a way to return to Home
4. **Native feel** - Slides feel like iOS navigation, not jarring
5. **Mini player works** - Persists across all navigation
6. **Tab switching works** - Clears navigation stack appropriately
7. **Player is modal** - Always a sheet, not part of navigation

---

## Common Pitfalls to Avoid

❌ **Don't do this:**
```swift
// DON'T: Navigate to player (it should be a sheet)
NavigationLink(value: AppDestination.player(episode)) {
    Text("Play")
}
```

❌ **Don't do this:**
```swift
// DON'T: Use sheet for Browse (use navigation)
.sheet(isPresented: $showBrowse) {
    PodcastBrowseNavigationView()
}
```

✅ **Do this:**
```swift
// DO: Use NavigationLink for Browse
NavigationLink(value: AppDestination.browse) {
    Text("Find your podcast")
}

// DO: Use sheet for Player
.sheet(isPresented: $showPlayer) {
    PlayerSheetWrapper(episode: episode, podcast: podcast)
}
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────┐
│              NavigationStack                    │
│  ┌──────────────────────────────────────────┐  │
│  │         Home View (base layer)            │  │
│  │                                           │  │
│  │  [Find your podcast] → NavigationLink    │  │
│  └──────────────────────────────────────────┘  │
│                       ↓                         │
│  ┌──────────────────────────────────────────┐  │
│  │    Browse View (pushed)                   │  │
│  │    < Back                                 │  │
│  │                                           │  │
│  │  [Podcast Card] → NavigationLink         │  │
│  └──────────────────────────────────────────┘  │
│                       ↓                         │
│  ┌──────────────────────────────────────────┐  │
│  │   Podcast Detail (pushed)                 │  │
│  │   < Browse                                │  │
│  │                                           │  │
│  │  [Episode Row] → Opens sheet ────┐       │  │
│  └──────────────────────────────────┘│       │  │
└──────────────────────────────────────│───────┘  │
                                       ↓           │
                        ┌──────────────────────────┐
                        │    Player Sheet          │
                        │    (Modal overlay)       │
                        │                          │
                        │    [Minimize] ↓          │
                        └──────────────────────────┘
                                       ↓
                        ┌──────────────────────────┐
                        │    Mini Player           │
                        │    (Above tab bar)       │
                        └──────────────────────────┘
```

---

## Rollback Plan

If something goes wrong, you can quickly rollback:

1. **Restore ContentView.swift** - Remove NavigationStack wrapper
2. **Restore HomeView.swift** - Add back `.sheet(isPresented: $showingPodcastSearch)`
3. **Keep using** - `PodcastBrowseRealView.swift` in sheet

The old code is not deleted, just not used, so rollback is easy.

---

**End of Implementation Guide**
