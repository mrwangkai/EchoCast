# EpisodePlayerView Consolidation Specification

**Document Version:** 1.0  
**Date:** February 3, 2026  
**Purpose:** Consolidate PlayerView (Type 1) and FullPlayerView (Type 2) into a single, reusable EpisodePlayerView component that matches Figma designs precisely.

---

## 1. Overview

### Objective
Create a unified `EpisodePlayerView.swift` that serves as the single source of truth for individual episode playback across the entire app. This component must be reusable from multiple entry points and maintain consistent behavior and appearance.

### Design Source
- **Figma File:** ✨ Kai's Projects
- **Listening Tab:** [Node 1321-4397](https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1321-4397&t=0S5nKaWUWbL48hc5-4)
- **Notes Tab:** [Node 1321-4521](https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1321-4521&t=0S5nKaWUWbL48hc5-4)
- **Episode Info Tab:** [Node 1321-4647](https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1321-4647&t=0S5nKaWUWbL48hc5-4)
- **Player Controls:** [Node 1321-4615](https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1321-4615&t=0S5nKaWUWbL48hc5-4)

### Entry Points (Must Support All)
1. Mini player tap → Full player sheet
2. Home screen "Continue listening" card tap
3. Episode tap in podcast detail/series page
4. Episode tap in search results
5. Deep link (future implementation)

---





### File Structure
```
/Views/Player/EpisodePlayerView.swift (NEW - CREATE THIS)
├─ Main View: EpisodePlayerView
├─ Three-Zone Layout:
│  ├─ Zone 1: Segmented Control (fixed at top)
│  ├─ Zone 2: Content Container (scrollable, changes by tab)
│  └─ Zone 3: Player Controls (sticky at bottom)
└─ Supporting Views (in same file)
```

### Data Flow
```
Entry Point (any)
    ↓
EpisodePlayerView(episode: RSSEpisode, podcast: PodcastEntity)
    ↓
GlobalPlayerManager.shared (single source of truth)
    ↓
Audio playback + State updates
```

---

## 4. Component Interface

### Required Initializer
```swift
struct EpisodePlayerView: View {
    // MARK: - Properties
    
    /// The episode to play (RSS model from feed parsing)
    let episode: RSSEpisode
    
    /// The podcast this episode belongs to (Core Data)
    let podcast: PodcastEntity
    
    /// Shared player manager - single source of truth for playback state
    @ObservedObject private var player = GlobalPlayerManager.shared
    
    /// Currently selected tab/segment (0 = Listening, 1 = Notes, 2 = Episode Info)
    @State private var selectedSegment = 0
    
    /// Controls note capture sheet presentation
    @State private var showingNoteCaptureSheet = false
    
    /// Environment dismiss for closing the sheet
    @Environment(\.dismiss) private var dismiss
    
    /// Core Data context for fetching notes
    @Environment(\.managedObjectContext) private var viewContext
    
    /// Fetch notes for current episode
    @FetchRequest private var notes: FetchedResults<NoteEntity>
    
    // MARK: - Initialization
    
    init(episode: RSSEpisode, podcast: PodcastEntity) {
        self.episode = episode
        self.podcast = podcast
        
        // Setup FetchRequest to get notes for this specific episode
        let episodeTitle = episode.title
        let podcastTitle = podcast.title ?? ""
        
        _notes = FetchRequest<NoteEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
            predicate: NSPredicate(
                format: "episodeTitle == %@ AND showTitle == %@",
                episodeTitle, podcastTitle
            ),
            animation: .default
        )
    }
}
```

### Usage Examples
```swift
// From MiniPlayerView
.sheet(isPresented: $showingFullPlayer) {
    if let episode = player.currentEpisode,
       let podcast = player.currentPodcast {
        EpisodePlayerView(episode: episode, podcast: podcast)
    }
}

// From Home View "Continue listening" card
Button {
    selectedEpisode = episode
    showPlayerSheet = true
} label: {
    ContinueListeningCard(episode: episode)
}
.sheet(isPresented: $showPlayerSheet) {
    if let episode = selectedEpisode {
        EpisodePlayerView(episode: episode, podcast: podcast)
    }
}

// From Podcast Detail episode row
Button {
    player.loadEpisode(episode, podcast: podcast)
    showPlayerSheet = true
} label: {
    EpisodeRowView(episode: episode)
}
.sheet(isPresented: $showPlayerSheet) {
    EpisodePlayerView(episode: episode, podcast: podcast)
}
```

---

## 5. Three-Zone Layout Structure

### Critical Layout Requirements

**The view MUST be divided into exactly 3 zones:**

1. **Zone 1: Segmented Control** (Fixed at top, always visible)
2. **Zone 2: Content Container** (Scrollable, content changes by tab)
3. **Zone 3: Player Controls** (Sticky at bottom, always visible)

**Zone 3 (Player Controls) must remain visible and in the same position across ALL three tabs.** Users should never lose access to playback controls when switching tabs or scrolling content.

### Implementation Pattern

```swift
var body: some View {
    VStack(spacing: 0) {
        // ZONE 1: SEGMENTED CONTROL (Fixed)
        segmentedControlSection
            .background(Color.echoBackground)
        
        // ZONE 2: CONTENT CONTAINER (Scrollable, changes by tab)
        contentContainerSection
        
        // ZONE 3: PLAYER CONTROLS (Sticky at bottom)
        playerControlsSection
            .background(Color.echoBackground)
    }
    .background(Color.echoBackground)
    .ignoresSafeArea(edges: .bottom) // Allow player controls to extend to bottom
}
```

### Zone 1: Segmented Control Section

```swift
// MARK: - Zone 1: Segmented Control

private var segmentedControlSection: some View {
    VStack(spacing: 0) {
        // Dismiss handle (optional drag indicator)
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color.white.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 16)
        
        // Segmented control
        Picker("", selection: $selectedSegment) {
            Text("Listening").tag(0)
            Text("Notes").tag(1)
            Text("Episode Info").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, EchoSpacing.screenPadding)
        .padding(.bottom, 16)
    }
}
```

**Design Token Reference:**
- Horizontal padding: `EchoSpacing.screenPadding` (24pt)
- Handle color: `Color.white.opacity(0.3)`
- Font: System default for segmented control

### Zone 2: Content Container Section

```swift
// MARK: - Zone 2: Content Container

private var contentContainerSection: some View {
    // Use TabView synchronized with segmented control
    TabView(selection: $selectedSegment) {
        listeningTabContent
            .tag(0)
        
        notesTabContent
            .tag(1)
        
        episodeInfoTabContent
            .tag(2)
    }
    .tabViewStyle(.page(indexDisplayMode: .never)) // Hide page dots (using segmented control instead)
}
```

**Important:** 
- TabView allows BOTH tap-to-switch (via segmented control) AND swipe-to-switch
- `.page(indexDisplayMode: .never)` hides the page indicator dots since we're using segmented control
- Content inside each tab should be wrapped in ScrollView for vertical scrolling

### Zone 3: Player Controls Section

```swift
// MARK: - Zone 3: Player Controls (Sticky)

private var playerControlsSection: some View {
    VStack(spacing: 16) {
        Divider()
            .background(Color.white.opacity(0.1))
        
        VStack(spacing: 20) {
            // Time scrubber with note markers
            timeProgressWithMarkers
            
            // Playback control buttons
            playbackControlButtons
            
            // Secondary actions row
            secondaryActionsRow
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
        .padding(.bottom, 24) // Extra padding for home indicator
    }
    .background(Color.echoBackground)
}
```

**Critical Requirements:**
- This section must be OUTSIDE any ScrollView
- It should NOT scroll with content
- It must remain visible when switching tabs
- It should have consistent spacing and appearance across all tabs

---

## 6. Tab 1: Listening (Figma Node 1321-4397)

### Layout Structure

```swift
// MARK: - Listening Tab Content

private var listeningTabContent: some View {
    ScrollView {
        VStack(spacing: 24) {
            // Album artwork
            albumArtworkView
                .padding(.top, 24)
            
            // Episode metadata (title, podcast name)
            episodeMetadataView
            
            // "Add note at current time" button
            addNoteButton
            
            Spacer(minLength: 100) // Space for player controls
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
    }
}
```

### Album Artwork

**Design Specs from Figma:**
- Size: Square, width determined by screen width minus padding
- Corner radius: 12pt
- Shadow: Multiple layers for depth
- Aspect ratio: 1:1

```swift
// MARK: - Album Artwork View

private var albumArtworkView: some View {
    GeometryReader { geometry in
        AsyncImage(url: URL(string: podcast.artworkURL ?? episode.imageURL ?? "")) { phase in
            switch phase {
            case .empty:
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    ProgressView()
                        .tint(.white)
                }
                
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
            case .failure:
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                }
                
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.width)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    .aspectRatio(1, contentMode: .fit)
}
```

### Episode Metadata

**Design Specs:**
- Episode title: `title2Echo()` (22pt Bold)
- Podcast name: `bodyEcho()` with 70% opacity
- Alignment: Center
- Spacing: 8pt between elements

```swift
// MARK: - Episode Metadata View

private var episodeMetadataView: some View {
    VStack(spacing: 8) {
        Text(episode.title)
            .font(.title2Echo())
            .foregroundColor(.echoTextPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
        
        Text(podcast.title ?? "Unknown Podcast")
            .font(.bodyEcho())
            .foregroundColor(.white.opacity(0.7))
            .multilineTextAlignment(.center)
    }
}
```

### "Add Note at Current Time" Button

**Design Specs from Figma:**
- Background: `mintButtonBackground` (#a5e5d8)
- Text color: `mintButtonText` (#1a3c34)
- Font: SF Pro Rounded Medium, 17pt
- Height: 56pt
- Corner radius: 12pt
- Icon: `note.text.badge.plus`

```swift
// MARK: - Add Note Button

private var addNoteButton: some View {
    Button {
        showingNoteCaptureSheet = true
    } label: {
        HStack(spacing: 8) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 17, weight: .medium))
            
            Text("Add note at current time")
                .font(.bodyRoundedMedium())
        }
        .foregroundColor(.mintButtonText)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color.mintButtonBackground)
        .cornerRadius(12)
    }
    .sheet(isPresented: $showingNoteCaptureSheet) {
        AddNoteSheet(
            episode: episode,
            podcast: podcast,
            timestamp: player.currentTime
        )
    }
}
```

---

## 7. Tab 2: Notes (Figma Node 1321-4521)

### Layout Structure

```swift
// MARK: - Notes Tab Content

private var notesTabContent: some View {
    ScrollView {
        VStack(spacing: 16) {
            if notes.isEmpty {
                emptyNotesState
            } else {
                notesListView
            }
            
            Spacer(minLength: 100) // Space for player controls
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
        .padding(.top, 24)
    }
}
```

### Empty State

**Design Specs:**
- Icon: `note.text` system symbol, 48pt
- Icon color: White 30% opacity
- Title: "No notes yet"
- Message: "Tap 'Add note at current time' while listening to capture your thoughts"
- Center aligned vertically and horizontally

```swift
// MARK: - Empty Notes State

private var emptyNotesState: some View {
    VStack(spacing: 16) {
        Spacer()
        
        Image(systemName: "note.text")
            .font(.system(size: 48))
            .foregroundColor(.white.opacity(0.3))
        
        Text("No notes yet")
            .font(.title2Echo())
            .foregroundColor(.echoTextPrimary)
        
        Text("Tap 'Add note at current time' while listening to capture your thoughts")
            .font(.bodyEcho())
            .foregroundColor(.echoTextSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

### Notes List

**Design Specs per Note Card:**
- Background: `noteCardBackground` (#333333)
- Corner radius: 8pt
- Padding: 16pt
- Shadow: Two-layer shadow for depth
- Spacing between cards: 16pt

```swift
// MARK: - Notes List View

private var notesListView: some View {
    ForEach(notes) { note in
        NoteCardView(note: note) {
            // Tap to seek to timestamp and switch to Listening tab
            if let timestamp = note.timestamp,
               let timeInSeconds = parseTimestamp(timestamp) {
                player.seek(to: timeInSeconds)
                withAnimation {
                    selectedSegment = 0 // Switch to Listening tab
                }
            }
        }
    }
}
```

### Note Card Component

```swift
// MARK: - Note Card View

struct NoteCardView: View {
    let note: NoteEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Timestamp + Priority flag
                HStack {
                    if let timestamp = note.timestamp {
                        Text(timestamp)
                            .font(.caption2Medium())
                            .foregroundColor(.mintAccent)
                    }
                    
                    Spacer()
                    
                    if note.isPriority {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.mintAccent)
                    }
                }
                
                // Note text
                if let noteText = note.noteText, !noteText.isEmpty {
                    Text(noteText)
                        .font(.bodyEcho())
                        .foregroundColor(.echoTextPrimary)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Tags
                if !note.tagsArray.isEmpty {
                    FlowLayout(spacing: 4) {
                        ForEach(note.tagsArray, id: \.self) { tag in
                            TagView(tag: tag)
                        }
                    }
                }
            }
            .padding(EchoSpacing.noteCardPadding)
            .background(Color.noteCardBackground)
            .cornerRadius(EchoSpacing.noteCardCornerRadius)
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag View

struct TagView: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.captionRounded())
            .foregroundColor(.echoTextPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(EchoSpacing.tagCornerRadius)
    }
}
```

---

## 8. Tab 3: Episode Info (Figma Node 1321-4647)

### Layout Structure

```swift
// MARK: - Episode Info Tab Content

private var episodeInfoTabContent: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 32) {
            // Episode description (from RSS feed)
            if let description = episode.description, !description.isEmpty {
                episodeDescriptionSection(description)
            }
            
            // Podcast description
            if let podcastDesc = podcast.podcastDescription, !podcastDesc.isEmpty {
                podcastDescriptionSection(podcastDesc)
            }
            
            // Episode metadata
            episodeMetadataSection
            
            Spacer(minLength: 100) // Space for player controls
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
        .padding(.top, 24)
    }
}
```

### Episode Description Section

**Design Specs:**
- Section title: "Episode Description" - `title2Echo()` (22pt Bold)
- Body text: `bodyEcho()` (17pt Regular)
- Text color: `echoTextSecondary` (85% white)
- Line spacing: 6pt
- **Critical:** Strip ALL HTML tags from description

```swift
// MARK: - Episode Description Section

private func episodeDescriptionSection(_ description: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Episode Description")
            .font(.title2Echo())
            .foregroundColor(.echoTextPrimary)
        
        Text(description.htmlStripped)
            .font(.bodyEcho())
            .foregroundColor(.echoTextSecondary)
            .lineSpacing(6)
    }
}
```

### Podcast Description Section

```swift
// MARK: - Podcast Description Section

private func podcastDescriptionSection(_ description: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("About the Podcast")
            .font(.title2Echo())
            .foregroundColor(.echoTextPrimary)
        
        Text(description.htmlStripped)
            .font(.bodyEcho())
            .foregroundColor(.echoTextSecondary)
            .lineSpacing(6)
    }
}
```

### Episode Metadata Section

**Design Specs:**
- Section title: "Details"
- Each row: Label (tertiary color) + Value (primary color)
- Font: `bodyEcho()` (17pt Regular)

```swift
// MARK: - Episode Metadata Section

private var episodeMetadataSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Details")
            .font(.title2Echo())
            .foregroundColor(.echoTextPrimary)
        
        VStack(alignment: .leading, spacing: 12) {
            if let pubDate = episode.pubDate {
                MetadataRow(label: "Published", value: formatPublishDate(pubDate))
            }
            
            if let duration = episode.duration {
                MetadataRow(label: "Duration", value: duration)
            }
            
            // Add more metadata as available from RSS feed
        }
    }
}

// MARK: - Metadata Row

struct MetadataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.bodyEcho())
                .foregroundColor(.echoTextTertiary)
            
            Spacer()
            
            Text(value)
                .font(.bodyEcho())
                .foregroundColor(.echoTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
```

### HTML Stripping Extension

**Critical:** RSS feed descriptions often contain HTML tags for formatting. These MUST be stripped before display.

```swift
// MARK: - String Extension for HTML Stripping

extension String {
    var htmlStripped: String {
        // Remove HTML tags
        var result = self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Decode HTML entities
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")
        
        // Trim whitespace
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

---

## 9. Zone 3: Player Controls (Figma Node 1321-4615)

### Layout Structure

**This section is CRITICAL and must be implemented exactly as specified to remain sticky across all tabs.**

```swift
// MARK: - Zone 3: Player Controls (Sticky Bottom Section)

private var playerControlsSection: some View {
    VStack(spacing: 16) {
        // Top divider
        Divider()
            .background(Color.white.opacity(0.1))
        
        VStack(spacing: 20) {
            // Time progress bar with note markers
            timeProgressWithMarkers
            
            // Main playback control buttons
            playbackControlButtons
            
            // Secondary actions row (download, speed, sleep timer, etc.)
            secondaryActionsRow
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
        .padding(.bottom, 24)
    }
    .background(Color.echoBackground)
}
```

### Time Progress Bar with Note Markers

**Design Specs:**
- Track height: 4pt
- Track color: White 20% opacity
- Progress color: `mintAccent` (#00c8b3)
- Note markers: Small circles (8pt diameter) on track
- Time labels: `caption2Medium()` (12pt Medium)
- Draggable for seeking

```swift
// MARK: - Time Progress with Note Markers

private var timeProgressWithMarkers: some View {
    VStack(spacing: 8) {
        // Progress bar with markers
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 4)
                
                // Progress fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.mintAccent)
                    .frame(width: progressWidth(geometry.size.width), height: 4)
                
                // Note markers overlay
                ForEach(notes.filter { $0.timestamp != nil }) { note in
                    if let timestamp = note.timestamp,
                       let timeInSeconds = parseTimestamp(timestamp),
                       player.duration > 0 {
                        Circle()
                            .fill(Color.mintAccent)
                            .frame(width: 8, height: 8)
                            .offset(x: markerPosition(timeInSeconds, width: geometry.size.width))
                            .offset(y: -2) // Center on track
                    }
                }
            }
            .frame(height: 20) // Give space for markers
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newTime = (value.location.x / geometry.size.width) * player.duration
                        player.seek(to: max(0, min(newTime, player.duration)))
                    }
            )
        }
        .frame(height: 20)
        
        // Time labels
        HStack {
            Text(formatTime(player.currentTime))
                .font(.caption2Medium())
                .foregroundColor(.echoTextTertiary)
            
            Spacer()
            
            Text("-\(formatTime(player.duration - player.currentTime))")
                .font(.caption2Medium())
                .foregroundColor(.echoTextTertiary)
        }
    }
}

// Helper: Calculate progress width
private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
    guard player.duration > 0 else { return 0 }
    return (player.currentTime / player.duration) * totalWidth
}

// Helper: Calculate marker position
private func markerPosition(_ timestamp: TimeInterval, width: CGFloat) -> CGFloat {
    guard player.duration > 0 else { return 0 }
    return (timestamp / player.duration) * width - 4 // -4 to center the 8pt circle
}
```

### Main Playback Control Buttons

**Design Specs from Figma:**
- Layout: 5 buttons in a row with equal spacing
- Button order: Skip back 30s | Skip back 15s | Play/Pause | Skip forward 15s | Skip forward 30s
- Play/Pause button: Larger (64pt circle)
- Skip buttons: Medium size (48pt circle)
- Background: Semi-transparent circles
- Icons: SF Symbols

```swift
// MARK: - Playback Control Buttons

private var playbackControlButtons: some View {
    HStack(spacing: 24) {
        // Skip backward 30 seconds
        skipButton(systemName: "gobackward.30", action: { player.skipBackward(30) })
        
        // Skip backward 15 seconds
        skipButton(systemName: "gobackward.15", action: { player.skipBackward(15) })
        
        // Play/Pause (larger, center button)
        Button {
            if player.isPlaying {
                player.pause()
            } else {
                player.play()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 64, height: 64)
                
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        
        // Skip forward 15 seconds
        skipButton(systemName: "goforward.15", action: { player.skipForward(15) })
        
        // Skip forward 30 seconds
        skipButton(systemName: "goforward.30", action: { player.skipForward(30) })
    }
    .frame(maxWidth: .infinity)
}

// Helper: Skip button component
private func skipButton(systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 48, height: 48)
            
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
    }
    .buttonStyle(.plain)
}
```

### Secondary Actions Row

**Design Specs:**
- 4 actions: Download | Playback Speed | Share | More Options
- Icon size: 20pt
- Icon color: White 85% opacity
- Spacing: Equal distribution across width

```swift
// MARK: - Secondary Actions Row

private var secondaryActionsRow: some View {
    HStack {
        // Download button
        downloadButton
        
        Spacer()
        
        // Playback speed
        playbackSpeedButton
        
        Spacer()
        
        // Share button
        shareButton
        
        Spacer()
        
        // More options
        moreOptionsButton
    }
}

private var downloadButton: some View {
    Button {
        let downloadManager = EpisodeDownloadManager.shared
        if downloadManager.isDownloaded(episode.id) {
            // Already downloaded - could show options to delete
            print("Episode already downloaded")
        } else {
            // Start download
            downloadManager.downloadEpisode(
                episode,
                podcastTitle: podcast.title ?? "",
                podcastFeedURL: podcast.feedURL
            )
        }
    } label: {
        let downloadManager = EpisodeDownloadManager.shared
        let isDownloaded = downloadManager.isDownloaded(episode.id)
        let isDownloading = downloadManager.downloadProgress[episode.id] != nil
        
        if isDownloading {
            ProgressView()
                .tint(.white)
        } else {
            Image(systemName: isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.echoTextSecondary)
        }
    }
    .buttonStyle(.plain)
}

private var playbackSpeedButton: some View {
    Button {
        // Cycle through speeds: 1.0x → 1.25x → 1.5x → 1.75x → 2.0x → 1.0x
        let speeds: [Float] = [1.0, 1.25, 1.5, 1.75, 2.0]
        if let currentIndex = speeds.firstIndex(of: player.playbackRate) {
            let nextIndex = (currentIndex + 1) % speeds.count
            player.setPlaybackRate(speeds[nextIndex])
        } else {
            player.setPlaybackRate(1.0)
        }
    } label: {
        Text("\(player.playbackRate, specifier: "%.2g")×")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.echoTextSecondary)
    }
    .buttonStyle(.plain)
}

private var shareButton: some View {
    Button {
        // Share episode (implement share sheet)
        print("Share episode")
    } label: {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.echoTextSecondary)
    }
    .buttonStyle(.plain)
}

private var moreOptionsButton: some View {
    Button {
        // Show more options menu
        print("More options")
    } label: {
        Image(systemName: "ellipsis")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(.echoTextSecondary)
    }
    .buttonStyle(.plain)
}
```

---

## 10. Helper Functions & Utilities

### Time Formatting

```swift
// MARK: - Time Formatting Helpers

private func formatTime(_ time: TimeInterval) -> String {
    guard !time.isNaN && !time.isInfinite else { return "0:00" }
    
    let hours = Int(time) / 3600
    let minutes = (Int(time) % 3600) / 60
    let seconds = Int(time) % 60
    
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private func formatPublishDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: date)
}
```

### Timestamp Parsing

```swift
// MARK: - Timestamp Parsing

private func parseTimestamp(_ timestamp: String) -> TimeInterval? {
    // Expected format: "HH:MM:SS" or "MM:SS"
    let components = timestamp.split(separator: ":")
    
    guard components.count >= 2 else { return nil }
    
    if components.count == 2 {
        // MM:SS format
        guard let minutes = Int(components[0]),
              let seconds = Int(components[1]) else { return nil }
        return TimeInterval(minutes * 60 + seconds)
        
    } else if components.count == 3 {
        // HH:MM:SS format
        guard let hours = Int(components[0]),
              let minutes = Int(components[1]),
              let seconds = Int(components[2]) else { return nil }
        return TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
    
    return nil
}
```

---

## 11. Integration Instructions

### Step 1: Create New File

```bash
# Create the new player view file
touch /path/to/EchoNotes/Views/Player/EpisodePlayerView.swift
```

Add to Xcode project:
1. Right-click on `/Views/Player/` folder
2. Select "Add Files to EchoNotes..."
3. Select `EpisodePlayerView.swift`
4. Ensure "Copy items if needed" is unchecked (file already in correct location)
5. Ensure target "EchoNotes" is checked

### Step 2: Update MiniPlayerView Integration

**File:** `/Views/MiniPlayerView.swift`

**Find:** The sheet presentation for FullPlayerView (around line 100-120)

**Replace:**
```swift
// OLD CODE (DELETE):
.sheet(isPresented: $showingFullPlayer) {
    FullPlayerView(episode: episode, podcast: podcast)
}

// NEW CODE:
.sheet(isPresented: $showingFullPlayer) {
    if let episode = player.currentEpisode,
       let podcast = player.currentPodcast {
        EpisodePlayerView(episode: episode, podcast: podcast)
    }
}
```

### Step 3: Update HomeView Integration

**File:** `/Views/HomeView.swift`

**Find:** "Continue listening" card tap handling

**Replace:**
```swift
// Find the button that opens player from "Continue listening" card
Button {
    // Load episode in player
    player.loadEpisode(episode, podcast: podcast)
    showPlayerSheet = true
} label: {
    ContinueListeningCard(...)
}
.sheet(isPresented: $showPlayerSheet) {
    if let episode = player.currentEpisode,
       let podcast = player.currentPodcast {
        EpisodePlayerView(episode: episode, podcast: podcast)
    }
}
```

### Step 4: Update PodcastDetailView Integration

**File:** `/Views/PodcastDetailView.swift`

**Find:** Episode row tap handling (around line 105-136)

**Replace:**
```swift
// OLD CODE (DELETE):
.sheet(isPresented: $showPlayerSheet) {
    if let selectedEpisode = selectedEpisode {
        PlayerSheetWrapper(episode: selectedEpisode, podcast: podcast)
    }
}

// NEW CODE:
.sheet(isPresented: $showPlayerSheet) {
    if let episode = selectedEpisode {
        EpisodePlayerView(episode: episode, podcast: podcast)
    }
}
```



---



### Functional Testing

- [ ] **Mini Player Entry Point**
  - [ ] Tap mini player → Full player sheet opens
  - [ ] Segmented control shows "Listening" selected
  - [ ] Album artwork displays correctly
  - [ ] Player controls are functional
  
- [ ] **Home Screen Entry Point**
  - [ ] Tap "Continue listening" card → Player opens with correct episode
  - [ ] Resume position matches last listened position
  
- [ ] **Podcast Detail Entry Point**
  - [ ] Tap episode in series list → Player opens
  - [ ] Episode loads and starts playing
  
- [ ] **Tab Navigation**
  - [ ] Tap segmented control → Content changes
  - [ ] Swipe between tabs → Segmented control updates
  - [ ] Player controls remain visible when switching tabs
  - [ ] Player controls remain visible when scrolling content
  
- [ ] **Listening Tab**
  - [ ] Album artwork loads and displays
  - [ ] Episode metadata displays correctly
  - [ ] "Add note at current time" button is visible and functional
  - [ ] Tapping button opens AddNoteSheet with correct timestamp
  
- [ ] **Notes Tab**
  - [ ] Empty state displays when no notes
  - [ ] Notes list populates correctly
  - [ ] Note cards display timestamp, text, tags, priority flag
  - [ ] Tapping note seeks to timestamp and switches to Listening tab
  
- [ ] **Episode Info Tab**
  - [ ] Episode description displays without HTML tags
  - [ ] Podcast description displays correctly
  - [ ] Metadata (publish date, duration) displays
  
- [ ] **Player Controls**
  - [ ] Play/Pause toggles correctly
  - [ ] Skip forward/backward (15s, 30s) works
  - [ ] Progress bar updates in real-time
  - [ ] Dragging progress bar seeks correctly
  - [ ] Note markers appear on progress bar
  - [ ] Playback speed cycles through speeds
  - [ ] Download button shows correct state
  
- [ ] **Note Timeline Markers**
  - [ ] Markers appear at correct positions
  - [ ] Markers scale with progress bar width
  - [ ] Multiple notes show multiple markers

### Visual Testing

- [ ] **Design Token Compliance**
  - [ ] All colors use EchoCast design tokens
  - [ ] All spacing uses EchoSpacing constants
  - [ ] All typography uses font extensions
  
- [ ] **Layout**
  - [ ] Segmented control remains at top (doesn't scroll)
  - [ ] Player controls remain at bottom (doesn't scroll)
  - [ ] Content area scrolls independently
  - [ ] No content hidden behind player controls
  - [ ] Safe area insets respected
  
- [ ] **Figma Accuracy**
  - [ ] Listening tab matches Figma node 1321-4397
  - [ ] Notes tab matches Figma node 1321-4521
  - [ ] Episode Info tab matches Figma node 1321-4647
  - [ ] Player controls match Figma node 1321-4615
  
- [ ] **Dark Mode**
  - [ ] All elements visible in dark mode
  - [ ] Contrast ratios meet accessibility standards

### Edge Cases

- [ ] **Missing Data**
  - [ ] Episode with no artwork → Shows placeholder
  - [ ] Episode with no description → Section hidden
  - [ ] Podcast with no description → Section hidden
  - [ ] Episode with no duration → Metadata row hidden
  
- [ ] **HTML Content**
  - [ ] RSS description with HTML tags → Tags stripped correctly
  - [ ] HTML entities decoded (e.g., &amp; → &)
  
- [ ] **Long Content**
  - [ ] Very long episode title → Truncates with ellipsis
  - [ ] Very long note text → Wraps correctly
  - [ ] Many notes → ScrollView performs smoothly
  
- [ ] **Playback States**
  - [ ] Loading state → Shows appropriate UI
  - [ ] Error state → Handles gracefully
  - [ ] Completed episode → Shows replay or next episode

### Performance Testing

- [ ] **Smooth Animations**
  - [ ] Tab switching is smooth (no lag)
  - [ ] Progress bar updates smoothly
  - [ ] Scrolling is smooth in all tabs
  
- [ ] **Memory Management**
  - [ ] No memory leaks when opening/closing player
  - [ ] Album artwork cached properly
  - [ ] Old player state released when dismissed

---

## 13. Design Token Reference

### Colors

```swift
// Backgrounds
Color.echoBackground               // #262626 - Main background
Color.noteCardBackground           // #333333 - Card background
Color.searchFieldBackground        // rgba(118, 118, 128, 0.24) - Search fields

// Text
Color.echoTextPrimary              // White 100%
Color.echoTextSecondary            // White 85%
Color.echoTextTertiary             // White 65%
Color.echoTextQuaternary           // White 70%

// Accents
Color.mintAccent                   // #00c8b3 - Primary accent
Color.mintButtonBackground         // #a5e5d8 - Button background
Color.mintButtonText               // #1a3c34 - Button text
Color.darkGreenButton              // #1a3c34 - Dark buttons
```

### Typography

```swift
.font(.largeTitleEcho())           // 34pt Bold
.font(.title2Echo())               // 22pt Bold
.font(.bodyEcho())                 // 17pt Regular
.font(.bodyRoundedMedium())        // 17pt Rounded Medium
.font(.subheadlineRounded())       // 15pt Rounded Medium
.font(.captionRounded())           // 13pt Regular
.font(.caption2Medium())           // 12pt Medium
```

### Spacing

```swift
EchoSpacing.screenPadding          // 24pt - Screen horizontal padding
EchoSpacing.noteCardPadding        // 16pt - Card internal padding
EchoSpacing.noteCardSpacing        // 16pt - Spacing between cards
EchoSpacing.buttonHeight           // 54pt - Standard button height
EchoSpacing.buttonCornerRadius     // 8pt - Standard button corners
EchoSpacing.noteCardCornerRadius   // 8pt - Card corners
EchoSpacing.tagCornerRadius        // 8pt - Tag corners
```

---

## 14. Implementation Priority

### Phase 1: Core Structure (HIGHEST PRIORITY)
1. Create `EpisodePlayerView.swift` file
2. Implement three-zone layout (segmented control, content, controls)
3. Implement basic tab switching
4. Verify player controls remain sticky

### Phase 2: Listening Tab
1. Add album artwork display
2. Add episode metadata
3. Add "Add note at current time" button
4. Integrate with AddNoteSheet

### Phase 3: Player Controls
1. Implement time progress bar
2. Add note markers to progress bar
3. Add playback control buttons
4. Add secondary actions row

### Phase 4: Notes Tab
1. Implement empty state
2. Implement notes list
3. Add note card component
4. Add tap-to-seek functionality

### Phase 5: Episode Info Tab
1. Add episode description with HTML stripping
2. Add podcast description
3. Add metadata section

### Phase 6: Integration
1. Update MiniPlayerView
2. Update HomeView
3. Update PodcastDetailView
4. Test all entry points



---

## 15. Common Pitfalls to Avoid

### ❌ DON'T: Put Player Controls Inside ScrollView

```swift
// WRONG - Player controls will scroll away
ScrollView {
    VStack {
        // Content
        
        // Player controls here ❌
        playbackControlButtons
    }
}
```

### ✅ DO: Keep Player Controls Outside ScrollView

```swift
// CORRECT - Player controls stay sticky
VStack {
    segmentedControl
    
    ScrollView {
        // Content only
    }
    
    // Player controls here ✅
    playbackControlButtons
}
```

### ❌ DON'T: Use Different Models for Same View

```swift
// WRONG - Inconsistent data models
struct EpisodePlayerView: View {
    let episode: PodcastEpisode?     // iTunes model
    let rssEpisode: RSSEpisode?      // RSS model
}
```

### ✅ DO: Use Consistent Models

```swift
// CORRECT - Single data model type
struct EpisodePlayerView: View {
    let episode: RSSEpisode          // RSS model only
    let podcast: PodcastEntity       // Core Data model
}
```

### ❌ DON'T: Create Local Player State

```swift
// WRONG - Local state doesn't sync
@State private var playerState = PlayerState()
```

### ✅ DO: Use Shared GlobalPlayerManager

```swift
// CORRECT - Shared singleton
@ObservedObject private var player = GlobalPlayerManager.shared
```

### ❌ DON'T: Forget to Strip HTML Tags

```swift
// WRONG - Displays raw HTML
Text(episode.description)
```

### ✅ DO: Strip HTML Before Display

```swift
// CORRECT - Clean text only
Text(episode.description.htmlStripped)
```

---

## 16. Success Criteria

The implementation is complete when:

1. ✅ Single `EpisodePlayerView.swift` file exists and compiles
2. ✅ All three tabs (Listening, Notes, Episode Info) display correctly
3. ✅ Player controls remain sticky across all tabs
4. ✅ All entry points (mini player, home, podcast detail) open the same view
5. ✅ Visual appearance matches Figma designs exactly
6. ✅ All design tokens are used (no hardcoded values)
7. ✅ Note markers appear on progress bar
8. ✅ "Add note at current time" button works
9. ✅ Tapping notes seeks to timestamp
10. ✅ HTML tags stripped from descriptions

12. ✅ All integration points updated
13. ✅ All tests in checklist pass

---

## 17. File Template Structure

```swift
//
//  EpisodePlayerView.swift
//  EchoNotes
//
//  Unified episode player view with three tabs: Listening, Notes, Episode Info.
//  This component is reusable across all app entry points (mini player, home, podcast detail).
//

import SwiftUI
import CoreData
import AVFoundation

// MARK: - Episode Player View

struct EpisodePlayerView: View {
    // MARK: - Properties
    
    let episode: RSSEpisode
    let podcast: PodcastEntity
    
    @ObservedObject private var player = GlobalPlayerManager.shared
    @State private var selectedSegment = 0
    @State private var showingNoteCaptureSheet = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var notes: FetchedResults<NoteEntity>
    
    // MARK: - Initialization
    
    init(episode: RSSEpisode, podcast: PodcastEntity) {
        // Implementation here
    }
    
    // MARK: - Body
    
    var body: some View {
        // Three-zone layout implementation
    }
}

// MARK: - Zone 1: Segmented Control

private extension EpisodePlayerView {
    var segmentedControlSection: some View {
        // Implementation
    }
}

// MARK: - Zone 2: Content Container

private extension EpisodePlayerView {
    var contentContainerSection: some View {
        // Implementation
    }
}

// MARK: - Listening Tab Content

private extension EpisodePlayerView {
    var listeningTabContent: some View {
        // Implementation
    }
    
    var albumArtworkView: some View {
        // Implementation
    }
    
    var episodeMetadataView: some View {
        // Implementation
    }
    
    var addNoteButton: some View {
        // Implementation
    }
}

// MARK: - Notes Tab Content

private extension EpisodePlayerView {
    var notesTabContent: some View {
        // Implementation
    }
    
    var emptyNotesState: some View {
        // Implementation
    }
    
    var notesListView: some View {
        // Implementation
    }
}

// MARK: - Episode Info Tab Content

private extension EpisodePlayerView {
    var episodeInfoTabContent: some View {
        // Implementation
    }
    
    func episodeDescriptionSection(_ description: String) -> some View {
        // Implementation
    }
    
    func podcastDescriptionSection(_ description: String) -> some View {
        // Implementation
    }
    
    var episodeMetadataSection: some View {
        // Implementation
    }
}

// MARK: - Zone 3: Player Controls

private extension EpisodePlayerView {
    var playerControlsSection: some View {
        // Implementation
    }
    
    var timeProgressWithMarkers: some View {
        // Implementation
    }
    
    var playbackControlButtons: some View {
        // Implementation
    }
    
    func skipButton(systemName: String, action: @escaping () -> Void) -> some View {
        // Implementation
    }
    
    var secondaryActionsRow: some View {
        // Implementation
    }
    
    var downloadButton: some View {
        // Implementation
    }
    
    var playbackSpeedButton: some View {
        // Implementation
    }
    
    var shareButton: some View {
        // Implementation
    }
    
    var moreOptionsButton: some View {
        // Implementation
    }
}

// MARK: - Helper Functions

private extension EpisodePlayerView {
    func formatTime(_ time: TimeInterval) -> String {
        // Implementation
    }
    
    func formatPublishDate(_ date: Date) -> String {
        // Implementation
    }
    
    func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        // Implementation
    }
    
    func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        // Implementation
    }
    
    func markerPosition(_ timestamp: TimeInterval, width: CGFloat) -> CGFloat {
        // Implementation
    }
}

// MARK: - Supporting Views

struct NoteCardView: View {
    // Implementation
}

struct TagView: View {
    // Implementation
}

struct MetadataRow: View {
    // Implementation
}

// MARK: - String Extension for HTML Stripping

extension String {
    var htmlStripped: String {
        // Implementation
    }
}

// MARK: - Preview

#Preview("With Notes") {
    EpisodePlayerView(
        episode: RSSEpisode(
            title: "Sample Episode",
            description: "Sample description",
            pubDate: Date(),
            duration: "45:30",
            audioURL: "https://example.com/audio.mp3",
            imageURL: nil
        ),
        podcast: PodcastEntity() // Preview mock
    )
}

#Preview("Empty Notes") {
    // Preview implementation
}
```

---

**END OF SPECIFICATION**

This document provides complete, precise instructions for implementing the consolidated EpisodePlayerView. Follow this specification exactly to ensure consistency with the Figma designs and EchoCast design system.
