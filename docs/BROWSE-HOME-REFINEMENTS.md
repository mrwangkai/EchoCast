# Browse & Home Screen Refinements - Figma Accurate

## Overview

This guide addresses:
1. Remove "My Podcasts" section from browse
2. Redesign browse to show podcasts by category (horizontal carousels)
3. Fix Continue Listening card to match Figma
4. Fix Following section to match Figma
5. Fix Note card layout to match Figma
6. Ensure player actually plays with time updates
7. Add comprehensive debug logging

---

## PART 1: Redesign Browse Experience

### Reference Figma
https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1416-7312

### Current Issues
- ❌ "My Podcasts" section takes up space
- ❌ Podcast cards show titles (should be artwork only)
- ❌ No "View all" link per category
- ❌ Not 10 podcasts per row
- ❌ Missing corner radius on sections

### Target Design

**Structure:**
```
Browse View
├── Search bar
├── Genre chips (horizontal scroll)
├── Comedy section
│   ├── Header: "Comedy" + "View all" →
│   └── Horizontal carousel (10 podcasts, artwork only, no corner radius)
├── News section
│   ├── Header: "News" + "View all" →
│   └── Horizontal carousel (10 podcasts)
└── ... (repeat for each genre)
```

### Implementation

**File: `PodcastDiscoveryView.swift`**

```swift
//
//  PodcastDiscoveryView.swift
//  EchoNotes
//
//  Browse podcasts by genre with horizontal carousels
//

import SwiftUI

struct PodcastDiscoveryView: View {
    @StateObject private var viewModel = PodcastBrowseViewModel()
    @State private var selectedGenre: PodcastGenre?
    @State private var showingViewAll = false
    @State private var viewAllGenre: PodcastGenre?
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, EchoSpacing.screenPadding)
                        .padding(.vertical, 12)
                    
                    // Genre chips carousel
                    genreChipsScrollView
                    
                    // Podcasts by category
                    if searchText.isEmpty {
                        categoryCarouselsView
                    } else {
                        searchResultsView
                    }
                }
            }
            .background(Color.echoBackground)
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await viewModel.loadAllGenres()
        }
        .sheet(isPresented: $showingViewAll) {
            if let genre = viewAllGenre {
                GenreViewAllView(genre: genre, podcasts: viewModel.genreResults[genre] ?? [])
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.echoTextTertiary)
                .font(.system(size: 17))
            
            TextField("Search podcasts", text: $searchText)
                .textFieldStyle(.plain)
                .font(.bodyEcho())
                .foregroundColor(.echoTextPrimary)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.echoTextTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.searchFieldBackground)
        .cornerRadius(8)
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
                            print("🎯 Genre tapped: \(genre.displayName)")
                            selectedGenre = genre
                            // Scroll to that section
                        }
                    )
                }
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
            .padding(.vertical, 12)
        }
        .background(Color.echoBackground)
    }
    
    // MARK: - Category Carousels View
    
    private var categoryCarouselsView: some View {
        VStack(spacing: 24) {
            ForEach(PodcastGenre.mainGenres.filter { $0 != .all }) { genre in
                CategoryCarouselSection(
                    genre: genre,
                    podcasts: Array((viewModel.genreResults[genre] ?? []).prefix(10)),
                    onViewAll: {
                        print("🔍 View all tapped for: \(genre.displayName)")
                        viewAllGenre = genre
                        showingViewAll = true
                    },
                    onPodcastTap: { podcast in
                        print("🎧 Podcast tapped: \(podcast.collectionName)")
                        // Open podcast detail
                    }
                )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Search Results View
    
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Results")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
                .padding(.horizontal, EchoSpacing.screenPadding)
            
            // Grid of search results
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Search results
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
        }
    }
}

// MARK: - Category Carousel Section

struct CategoryCarouselSection: View {
    let genre: PodcastGenre
    let podcasts: [iTunesPodcast]
    let onViewAll: () -> Void
    let onPodcastTap: (iTunesPodcast) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(genre.displayName)
                    .font(.title2Echo())
                    .foregroundColor(.echoTextPrimary)
                
                Spacer()
                
                Button(action: onViewAll) {
                    Text("View all")
                        .font(.bodyRoundedMedium())
                        .foregroundColor(.mintAccent)
                }
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
            
            // Horizontal carousel (10 podcasts, artwork only)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(podcasts) { podcast in
                        PodcastArtworkCard(podcast: podcast)
                            .onTapGesture {
                                onPodcastTap(podcast)
                            }
                    }
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.noteCardBackground.opacity(0.3))
            )
            .padding(.bottom, 16)  // 16-24px bottom spacing
        }
    }
}

// MARK: - Podcast Artwork Card (No Corner Radius)

struct PodcastArtworkCard: View {
    let podcast: iTunesPodcast
    
    var body: some View {
        AsyncImage(url: URL(string: podcast.artworkUrl600 ?? "")) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.noteCardBackground)
                    .frame(width: 120, height: 120)
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
            case .failure:
                Rectangle()
                    .fill(Color.noteCardBackground)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundColor(.echoTextTertiary)
                    }
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 120, height: 120)
        // NO corner radius as per requirements
    }
}

// MARK: - Genre View All

struct GenreViewAllView: View {
    let genre: PodcastGenre
    let podcasts: [iTunesPodcast]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(podcasts) { podcast in
                        VStack(spacing: 8) {
                            PodcastArtworkCard(podcast: podcast)
                            
                            Text(podcast.collectionName)
                                .font(.captionRounded())
                                .foregroundColor(.echoTextPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 120)
                        }
                        .onTapGesture {
                            print("🎧 Podcast tapped in view all: \(podcast.collectionName)")
                            // Open podcast detail
                        }
                    }
                }
                .padding(EchoSpacing.screenPadding)
            }
            .background(Color.echoBackground)
            .navigationTitle(genre.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.mintAccent)
                }
            }
        }
    }
}

// MARK: - ViewModel Extension

extension PodcastBrowseViewModel {
    func loadAllGenres() async {
        print("📡 Loading all genres...")
        for genre in PodcastGenre.mainGenres where genre != .all {
            do {
                print("📡 Fetching \(genre.displayName)...")
                let podcasts = try await PodcastAPIService.shared.getTopPodcasts(genreId: genre.rawValue, limit: 10)
                await MainActor.run {
                    genreResults[genre] = podcasts
                    print("✅ Loaded \(podcasts.count) podcasts for \(genre.displayName)")
                }
            } catch {
                print("❌ Failed to load \(genre.displayName): \(error)")
            }
        }
    }
}
```

---

## PART 2: Fix Continue Listening Card

### Reference Figma
https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-4000

### Extract Figma Specs

Use Figma MCP or manual inspection:
```
- Card dimensions: ??? x ??? pt
- Album artwork: ??? x ??? pt, ??? corner radius
- Episode title: Font, size, weight, lines
- Podcast name: Font, size, weight
- Progress bar: Height, thumb size, colors
- Time remaining: Position, styling
- Play button overlay: Size, position
- Card background: Color, corner radius, shadow
```

### Implementation

**File: `ContinueListeningCard.swift`**

```swift
//
//  ContinueListeningCard.swift
//  EchoNotes
//
//  Figma-accurate continue listening card
//

import SwiftUI

struct ContinueListeningCard: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    let progress: Double  // 0.0 to 1.0
    let currentTime: TimeInterval
    let duration: TimeInterval
    let onTap: () -> Void
    
    var timeRemaining: String {
        let remaining = duration - currentTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "-%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Album artwork with play button overlay
                ZStack(alignment: .center) {
                    AsyncImage(url: URL(string: episode.imageURL ?? podcast.artworkURL ?? "")) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.noteCardBackground)
                                .frame(width: 88, height: 88)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 88, height: 88)
                                .clipped()
                        case .failure:
                            Rectangle()
                                .fill(Color.noteCardBackground)
                                .frame(width: 88, height: 88)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 88, height: 88)
                    .cornerRadius(8)  // Verify from Figma
                    
                    // Play button overlay
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                }
                
                // Episode metadata
                VStack(alignment: .leading, spacing: 6) {
                    Text(episode.title)
                        .font(.bodyRoundedMedium())
                        .foregroundColor(.echoTextPrimary)
                        .lineLimit(2)
                    
                    Text(podcast.title ?? "Unknown Podcast")
                        .font(.captionRounded())
                        .foregroundColor(.echoTextSecondary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                
                Spacer()
            }
            
            // Progress bar with time
            VStack(spacing: 4) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        Rectangle()
                            .fill(Color.echoTextTertiary.opacity(0.2))
                            .frame(height: 4)
                        
                        // Progress
                        Rectangle()
                            .fill(Color.mintAccent)
                            .frame(width: geometry.size.width * progress, height: 4)
                        
                        // Note markers (if any)
                        // TODO: Add note markers as 8pt circles
                    }
                }
                .frame(height: 4)
                .cornerRadius(2)
                
                // Time remaining
                HStack {
                    Spacer()
                    Text(timeRemaining)
                        .font(.caption2Medium())
                        .foregroundColor(.echoTextTertiary)
                }
            }
        }
        .padding(16)
        .background(Color.noteCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
        .onTapGesture {
            print("🎧 Continue listening card tapped: \(episode.title)")
            onTap()
        }
    }
}
```

---

## PART 3: Fix Note Card Layout

### Reference Figma
https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-4052

### Target Structure

```
┌─────────────────────────────────────────────┐
│ [Note text]                                 │
│ Multiple lines...                           │
│                                             │
│ [🕐 12:45]          [tag1] [tag2] [+2] ←225px│
├─────────────────────────────────────────────┤
│ [🎧 88x88]  Episode Name (Caption 1)        │
│   8px gap   Podcast Name (Caption 2)        │
└─────────────────────────────────────────────┘
```

### Implementation

**File: `NoteCardView.swift`**

```swift
//
//  NoteCardView.swift
//  EchoNotes
//
//  Figma-accurate note card layout
//

import SwiftUI

struct NoteCardView: View {
    let note: NoteEntity
    let onTap: () -> Void
    
    private var visibleTags: [String] {
        let tags = note.tagsArray
        return Array(tags.prefix(3))  // Show max 3 tags
    }
    
    private var additionalTagsCount: Int {
        max(0, note.tagsArray.count - 3)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // TOP: Note content + metadata
            VStack(alignment: .leading, spacing: 12) {
                // Note text
                Text(note.noteText ?? "")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(4)
                
                // Timestamp (left) + Tags (right, max 225px)
                HStack(alignment: .top) {
                    // Timestamp badge (fixed left)
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(note.timestamp ?? "")
                            .font(.caption2Medium())
                    }
                    .foregroundColor(.mintAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.mintAccent.opacity(0.15))
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    // Tags (fixed right, max 225px)
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
                    .frame(maxWidth: 225)  // Max width constraint
                }
            }
            .padding(16)
            
            // SEPARATOR
            Divider()
                .background(Color.echoTextTertiary.opacity(0.2))
            
            // BOTTOM: Podcast metadata
            HStack(spacing: 8) {
                // Mini album art (88x88)
                AsyncImage(url: URL(string: note.podcastArtworkURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.noteCardBackground)
                            .frame(width: 88, height: 88)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 88, height: 88)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.noteCardBackground)
                            .frame(width: 88, height: 88)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 88, height: 88)
                .cornerRadius(8)
                
                // Episode information
                VStack(alignment: .leading, spacing: 4) {
                    // Episode name (Caption 1 Regular)
                    Text(note.episodeTitle ?? "Unknown Episode")
                        .font(.system(size: 12, weight: .regular))  // Caption 1
                        .foregroundColor(.echoTextPrimary)
                        .lineLimit(2)
                    
                    // Series name (Caption 2 Regular)
                    Text(note.showTitle ?? "Unknown Podcast")
                        .font(.system(size: 11, weight: .regular))  // Caption 2
                        .foregroundColor(.echoTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(16)
        }
        .background(Color.noteCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
        .onTapGesture {
            print("📝 Note card tapped: \(note.id?.uuidString ?? "unknown")")
            onTap()
        }
    }
}

// MARK: - NoteEntity Extension

extension NoteEntity {
    var podcastArtworkURL: String? {
        // Try to get artwork URL from associated data
        // This might need to be stored in Core Data
        return nil  // TODO: Add artwork URL to NoteEntity
    }
}
```

---

## PART 4: Fix Player Time Updates

### Issue
Player doesn't show elapsed/remaining time or progress doesn't update

### Root Cause
Likely missing `TimeObserver` on AVPlayer

### Implementation

**File: `GlobalPlayerManager.swift`**

```swift
class GlobalPlayerManager: ObservableObject {
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isPlaying = false
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    func setupPlayer(with url: URL) {
        print("🎵 Setting up player with URL: \(url)")
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Setup time observer (CRITICAL)
        setupTimeObserver()
        
        // Setup duration observer
        setupDurationObserver(for: playerItem)
        
        print("✅ Player setup complete")
    }
    
    private func setupTimeObserver() {
        print("⏱️ Setting up time observer")
        
        // Remove old observer if exists
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        
        // Add periodic time observer (updates every 0.5 seconds)
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            let currentSeconds = CMTimeGetSeconds(time)
            
            // Only update if changed significantly (avoid excessive updates)
            if abs(self.currentTime - currentSeconds) > 0.1 {
                self.currentTime = currentSeconds
                print("⏱️ Current time: \(Int(currentSeconds))s / \(Int(self.duration))s")
            }
        }
    }
    
    private func setupDurationObserver(for item: AVPlayerItem) {
        print("⏱️ Setting up duration observer")
        
        // Observe status changes
        item.publisher(for: \.status)
            .sink { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case .readyToPlay:
                    let durationSeconds = CMTimeGetSeconds(item.duration)
                    if durationSeconds.isFinite && durationSeconds > 0 {
                        self.duration = durationSeconds
                        print("✅ Duration set: \(Int(durationSeconds))s (\(self.formatTime(durationSeconds)))")
                    } else {
                        print("⚠️ Duration not available yet")
                    }
                case .failed:
                    print("❌ Player item failed: \(item.error?.localizedDescription ?? "unknown")")
                case .unknown:
                    print("⏳ Player status unknown")
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func play() {
        print("▶️ Play called")
        player?.play()
        isPlaying = true
        print("✅ Player is playing: \(isPlaying)")
    }
    
    func pause() {
        print("⏸️ Pause called")
        player?.pause()
        isPlaying = false
        print("✅ Player is paused")
    }
    
    func seek(to time: TimeInterval) {
        print("⏩ Seeking to: \(formatTime(time))")
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime) { [weak self] completed in
            if completed {
                print("✅ Seek completed")
            } else {
                print("⚠️ Seek interrupted")
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    deinit {
        // Remove time observer on cleanup
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        print("🗑️ GlobalPlayerManager deallocated")
    }
}
```

---

## PART 5: Add Comprehensive Debug Logging

### Add to Key Files

**PodcastDetailView.swift:**
```swift
.task {
    print("📡 [PodcastDetail] Loading episodes for: \(podcast.collectionName)")
    print("📡 [PodcastDetail] Feed URL: \(podcast.feedUrl ?? "nil")")
    await loadEpisodes()
}

private func loadEpisodes() async {
    print("📡 [PodcastDetail] loadEpisodes() called")
    
    guard let feedURL = podcast.feedUrl else {
        print("❌ [PodcastDetail] No feed URL available")
        errorMessage = "No feed URL available"
        return
    }
    
    isLoadingEpisodes = true
    print("⏳ [PodcastDetail] Fetching from: \(feedURL)")
    
    do {
        let rssService = PodcastRSSService()
        episodes = try await rssService.fetchEpisodes(from: feedURL)
        print("✅ [PodcastDetail] Loaded \(episodes.count) episodes")
    } catch {
        print("❌ [PodcastDetail] Failed to load episodes: \(error)")
        errorMessage = "Failed to load episodes: \(error.localizedDescription)"
    }
    
    isLoadingEpisodes = false
}
```

**HomeView.swift:**
```swift
var body: some View {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Log section visibility
                if player.currentEpisode != nil {
                    print("🏠 [HomeView] Showing Continue Listening section")
                    continueListeningSection
                }
                
                if !followedPodcasts.isEmpty {
                    print("🏠 [HomeView] Showing Following section (\(followedPodcasts.count) podcasts)")
                    followingSection
                }
                
                if !recentNotes.isEmpty {
                    print("🏠 [HomeView] Showing Recent Notes section (\(recentNotes.count) notes)")
                    recentNotesSection
                } else if followedPodcasts.isEmpty && player.currentEpisode == nil {
                    print("🏠 [HomeView] Showing empty state")
                    emptyStateView
                }
            }
        }
    }
}
```

**PodcastDiscoveryView.swift:**
```swift
.task {
    print("📡 [Browse] Loading all genres...")
    await viewModel.loadAllGenres()
    print("✅ [Browse] All genres loaded")
}
```

---

## PART 6: Fix IOSurfaceClientSetSurfaceNotify Error

### About This Error
This is a common macOS/iOS error related to image rendering. It's usually harmless but indicates:
- AsyncImage having issues
- Image caching problems
- Metal/GPU rendering issues

### Fix 1: Ensure Proper AsyncImage Usage
Already covered in sections above.

### Fix 2: Clear Derived Data
```bash
# In Terminal
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Fix 3: Add to Build Settings
In Xcode project settings:
```
Build Settings → Other Linker Flags
Add: -Wl,-weak_reference_mismatches,weak
```

This error is usually non-blocking and can be ignored if app works correctly.

---

## CLAUDE CODE PROMPT

```
TASK: Implement Browse & Home Screen Refinements

Read and implement: BROWSE-HOME-REFINEMENTS.md

Execute all parts:

PART 1: Redesign Browse Experience
- Remove "My Podcasts" section
- Implement category carousels (10 podcasts each, artwork only)
- Add "View all" links per category
- Section background with 8pt corner radius
- Bottom padding 16-24px between sections
- Reference Figma: node-id=1416-7312

PART 2: Fix Continue Listening Card
- Match Figma design exactly: node-id=1878-4000
- Extract specs with Figma MCP
- 88x88 artwork, progress bar, time remaining
- Play button overlay

PART 3: Fix Note Card Layout
- Match Figma design exactly: node-id=1878-4052
- Top: Note text + timestamp (left) + tags max 225px (right)
- Separator
- Bottom: 88x88 artwork + episode info (8px gap)
- Caption 1 Regular for episode, Caption 2 Regular for series

PART 4: Fix Player Time Updates
- Add TimeObserver to GlobalPlayerManager
- Update currentTime every 0.5 seconds
- Display elapsed/remaining time
- Update progress bar

PART 5: Add Debug Logging
- Add comprehensive logs to all key files
- Log section visibility, API calls, errors
- Use prefixes: 🏠 [HomeView], 📡 [Browse], ❌ [Error]

Test after each part. Commit when working.
Document in docs/refinements-progress.md

Figma file: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects
```

---

**END OF REFINEMENTS GUIDE**
