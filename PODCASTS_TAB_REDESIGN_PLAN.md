# Podcasts Tab Redesign Plan

## Overview
Merge Home tab functionality into Podcasts tab, then hide Home tab. This creates a unified podcast-centric experience.

## Current State

### Home Tab (HomeView)
- Recently Played section (3 episodes)
- My Podcasts section (3 podcasts with "view all")
- Episodes carousel
- Search bar

### Podcasts Tab (PodcastsListView)
- Simple list of subscribed podcasts
- Episodes section showing downloaded episodes
- "My Podcasts" header with count

## Target State for Podcasts Tab

### 1. Header
- **Title**: "CastNotes" (instead of "Home" or "Podcasts")
- **Subtitle**: "X notes saved across Y podcasts"
  - Count total notes from Core Data
  - Count total podcasts from Core Data

### 2. Continue Listening Section
- **Change from**: "Recently Played"
- **Change to**: "Continue Listening"
- Show 3 most recent episodes with playback progress
- Horizontal scroll
- Display: Episode thumbnail (circular), title, podcast name, progress indicator

### 3. My Podcasts Section
- **Header**: "My Podcasts" with "View all" link
- **View all link**: Opens sheet with full podcast list
- **Search bar**: "Search for podcasts" placeholder
  - Same functionality as current Home search
  - Opens PodcastSearchView sheet
- **Podcast list**: Show 3-5 podcasts below search bar
  - Rectangle thumbnails
  - Podcast title
  - Episode count or last updated info

### 4. Recent Notes Section (NEW)
- **Header**: "Recent Notes" with "View all" link on right
- **Layout**: Horizontal carousel (ScrollView)
- **Card dimensions**: 3/4 of screen width (excluding padding)
- **Show**: Up to 5 most recent notes
- **Card content**:
  - Note text (h4 or h5 font size, ~3-4 lines)
  - Episode name below note
  - Hide series name for now
  - Timestamp/date in corner
- **Last card**: "View all notes" button card
  - Takes user to Notes tab
- **View all link**: Takes to Notes tab (tag 2)

### 5. Hide Home Tab
- Remove HomeView from TabView
- Adjust tab tags (Podcasts=0, Notes=1, Settings=2)
- Update any selectedTab references

## Implementation Steps

### Phase 1: Update PodcastsListView (file: ContentView.swift, line ~907)

1. **Add data fetching**:
   ```swift
   @FetchRequest(
       sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
       animation: .default
   ) private var allNotes: FetchedResults<NoteEntity>

   @ObservedObject var historyManager = PlaybackHistoryManager.shared
   @ObservedObject var downloadManager = EpisodeDownloadManager.shared
   ```

2. **Add computed properties**:
   ```swift
   private var totalNotes: Int {
       allNotes.count
   }

   private var totalPodcasts: Int {
       podcasts.count
   }

   private var recentNotes: [NoteEntity] {
       Array(allNotes.prefix(5))
   }
   ```

3. **Replace body with ScrollView containing**:
   - Header with subtitle
   - Continue Listening section (copy from HomeView's Recently Played)
   - My Podcasts section with search + list
   - Recent Notes carousel (new component)

### Phase 2: Create RecentNotesCarousel Component

```swift
struct RecentNotesCarousel: View {
    let notes: [NoteEntity]
    let onViewAll: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(notes) { note in
                    RecentNoteCard(note: note)
                        .frame(width: UIScreen.main.bounds.width * 0.75)
                }

                // View all card
                ViewAllNotesCard(onTap: onViewAll)
                    .frame(width: UIScreen.main.bounds.width * 0.75)
            }
            .padding(.horizontal)
        }
    }
}

struct RecentNoteCard: View {
    let note: NoteEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Note text (3-4 lines)
            Text(note.noteText ?? "")
                .font(.title3) // or .title2 for h4
                .lineLimit(4)

            Spacer()

            // Episode name
            Text(note.episodeTitle ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Timestamp
            if let date = note.createdAt {
                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

### Phase 3: Hide Home Tab (file: ContentView.swift, line ~108)

1. **Comment out or remove HomeView**:
   ```swift
   TabView(selection: $selectedTab) {
       // HomeView(selectedTab: $selectedTab)
       //     .tabItem {
       //         Label("Home", systemImage: "house.fill")
       //     }
       //     .tag(0)

       PodcastsListView()
           .tabItem {
               Label("Podcasts", systemImage: "mic.fill")
           }
           .tag(0)  // Changed from 1 to 0

       NotesListView(selectedTab: $selectedTab)
           .tabItem {
               Label("Notes", systemImage: "note.text")
           }
           .tag(1)  // Changed from 2 to 1

       SettingsView()
           .tabItem {
               Label("Settings", systemImage: "gearshape.fill")
           }
           .tag(2)  // Changed from 3 to 2
   }
   ```

2. **Update default selectedTab**:
   ```swift
   @State private var selectedTab = 0  // Now opens Podcasts by default
   ```

3. **Search for selectedTab references and update**:
   - Notes tab now = 1 (was 2)
   - Settings tab now = 2 (was 3)

## Files to Modify

1. **ContentView.swift**:
   - Line ~907: PodcastsListView struct (major rewrite)
   - Line ~108: TabView structure (remove Home, adjust tags)
   - Line ~80: selectedTab default value

2. **Consider creating new file**: `RecentNotesCarousel.swift`
   - Or add components to ContentView.swift

## Testing Checklist

- [ ] Podcasts tab shows "CastNotes" title
- [ ] Subtitle shows correct note/podcast counts
- [ ] Continue Listening shows 3 recent episodes
- [ ] My Podcasts section has View All link
- [ ] Search bar opens search sheet
- [ ] Recent Notes carousel scrolls horizontally
- [ ] Note cards show at 3/4 width
- [ ] "View all notes" card navigates to Notes tab
- [ ] View All link navigates to Notes tab
- [ ] Home tab is hidden
- [ ] Tab indices work correctly (Podcasts=0, Notes=1, Settings=2)
- [ ] MiniPlayer still works on all tabs

## Estimated Context Usage

- Reading current PodcastsListView: ~500 tokens
- Reading HomeView sections to copy: ~1500 tokens
- Writing new PodcastsListView: ~2000 tokens
- Creating RecentNotesCarousel: ~1000 tokens
- Updating TabView structure: ~500 tokens
- Testing/fixes: ~1000 tokens

**Total: ~6500 tokens** (reasonable for one session)

## Alternative Approach (If Context Limited)

1. **Step 1**: Just add header + subtitle to PodcastsListView (commit)
2. **Step 2**: Add Continue Listening section (commit)
3. **Step 3**: Add My Podcasts with search (commit)
4. **Step 4**: Add Recent Notes carousel (commit)
5. **Step 5**: Hide Home tab (commit)

Each step is a small, testable change.

## Notes

- Keep HomeView code intact initially in case we need to reference it
- Can delete HomeView struct after successful migration
- Consider renaming PodcastsListView to something like MainView or CastNotesView for clarity
