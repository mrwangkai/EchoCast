# EchoCast Rebuild Implementation Plan
**For Claude Code Execution**

## Current State
- ✅ 23 Swift files building successfully
- ✅ iTunes search working in ContentView
- ✅ RSS parsing service exists (PodcastRSSService.swift)
- ✅ Basic audio playback (AudioPlayerView.swift exists)
- ✅ Design tokens ready to add
- ❌ Missing: HomeView, unified player, home screen components

## Implementation Priorities
1. Add design tokens for visual consistency
2. Create HomeView with empty state
3. Create ContinueListeningCard component  
4. Create unified EpisodePlayerView
5. Polish mini player behavior

---

# PHASE 1: Add Design Tokens (5 minutes)

## Task
Add `EchoCastDesignTokens.swift` to enable consistent styling.

## Steps

1. **File already exists at:** `/mnt/user-data/outputs/EchoCastDesignTokens.swift`

2. **Add to Xcode:**
   - Copy file to `EchoNotes/Views/EchoCastDesignTokens.swift`
   - In Xcode: Right-click `/Views/` → "Add Files to EchoNotes..."
   - Select `EchoCastDesignTokens.swift`
   - Settings:
     - ☑️ Copy items if needed - CHECK
     - ☑️ Add to targets: EchoNotes - CHECK
   - Click "Add"

3. **Verify:**
   ```bash
   # Build should succeed
   xcodebuild -project EchoNotes.xcodeproj -scheme EchoNotes clean build
   ```

## Success Criteria
- ✅ File appears in Xcode under `/Views/`
- ✅ Project builds with no errors
- ✅ Can reference `Color.mintAccent`, `EchoSpacing.screenPadding`, `.largeTitleEcho()` in code

---

# PHASE 2: Create HomeView (30 minutes)

## Reference Documents
- `empty_and_onboarding.md` - Empty state design
- `EchoCast-Development-Guide.md` - Design patterns

## Task
Create main home screen with empty state and continue listening section.

## Implementation

### File: `EchoNotes/Views/HomeView.swift`

```swift
//
//  HomeView.swift
//  EchoNotes
//
//  Main home screen showing continue listening and recent notes
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Fetch recent notes
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
        animation: .default
    )
    private var recentNotes: FetchedResults<NoteEntity>
    
    // Player state
    @ObservedObject private var player = GlobalPlayerManager.shared
    
    @State private var showingPlayerSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    headerSection
                    
                    // Continue Listening Section
                    if player.currentEpisode != nil || !recentNotes.isEmpty {
                        continueListeningSection
                    }
                    
                    // Recent Notes Section
                    if !recentNotes.isEmpty {
                        recentNotesSection
                    } else {
                        emptyStateView
                    }
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
                .padding(.top, EchoSpacing.headerTopPadding)
            }
            .background(Color.echoBackground)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EchoCast")
                .font(.largeTitleEcho())
                .foregroundColor(.echoTextPrimary)
            
            Text(greetingText)
                .font(.bodyEcho())
                .foregroundColor(.echoTextSecondary)
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
    
    // MARK: - Continue Listening Section
    
    private var continueListeningSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Continue Listening")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
            
            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                ContinueListeningPlaceholder(
                    episodeTitle: episode.title,
                    podcastTitle: podcast.title ?? "Unknown Podcast",
                    progress: player.currentTime / player.duration
                )
                .onTapGesture {
                    showingPlayerSheet = true
                }
            } else {
                Text("No episodes playing")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextTertiary)
            }
        }
        .sheet(isPresented: $showingPlayerSheet) {
            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                // TODO: Replace with EpisodePlayerView when created
                Text("Player for: \(episode.title)")
            }
        }
    }
    
    // MARK: - Recent Notes Section
    
    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Notes")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
            
            ForEach(recentNotes.prefix(5)) { note in
                NoteCardPlaceholder(note: note)
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 100)
            
            Image(systemName: "waveform")
                .font(.system(size: 72))
                .foregroundColor(.mintAccent)
            
            VStack(spacing: 8) {
                Text("No notes yet")
                    .font(.title2Echo())
                    .foregroundColor(.echoTextPrimary)
                
                Text("Start listening to a podcast and add notes as you go")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Placeholder Components (Temporary)

struct ContinueListeningPlaceholder: View {
    let episodeTitle: String
    let podcastTitle: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(episodeTitle)
                .font(.bodyRoundedMedium())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(2)
            
            Text(podcastTitle)
                .font(.captionRounded())
                .foregroundColor(.echoTextSecondary)
            
            ProgressView(value: progress)
                .tint(.mintAccent)
        }
        .padding(EchoSpacing.noteCardPadding)
        .background(Color.noteCardBackground)
        .cornerRadius(EchoSpacing.noteCardCornerRadius)
    }
}

struct NoteCardPlaceholder: View {
    let note: NoteEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let showTitle = note.showTitle {
                Text(showTitle)
                    .font(.captionRounded())
                    .foregroundColor(.echoTextSecondary)
            }
            
            if let noteText = note.noteText {
                Text(noteText)
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(3)
            }
            
            if let timestamp = note.timestamp {
                Text(timestamp)
                    .font(.caption2Medium())
                    .foregroundColor(.mintAccent)
            }
        }
        .padding(EchoSpacing.noteCardPadding)
        .background(Color.noteCardBackground)
        .cornerRadius(EchoSpacing.noteCardCornerRadius)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
```

### Add to Xcode
1. Create file: `EchoNotes/Views/HomeView.swift`
2. Add to project with target "EchoNotes"
3. Build and verify

### Update ContentView Navigation
In `ContentView.swift`, find the tab view and ensure Home tab shows `HomeView()`.

## Success Criteria
- ✅ HomeView.swift compiles
- ✅ Empty state displays when no notes exist
- ✅ Continue listening section shows current episode
- ✅ Recent notes list displays when notes exist
- ✅ App builds successfully

---

# PHASE 3: Create ContinueListeningCard (45 minutes)

## Reference Documents
- `FigmaContinueListeningCard-Specification.md` - Complete Figma spec

## Task
Create pixel-perfect continue listening card matching Figma design.

## Implementation

Read the complete specification from `FigmaContinueListeningCard-Specification.md` and implement:

### File: `EchoNotes/Views/ContinueListeningCard.swift`

**Key Requirements from Figma:**
- Dimensions: 327x156pt
- Album artwork: 108x108pt, 12pt corner radius
- Episode title: SF Pro Rounded Medium 17pt, 2 lines max
- Podcast name: SF Pro Regular 15pt, secondary color
- Progress bar with note markers (8pt circles)
- Time remaining label
- Play button overlay on artwork

**Use design tokens:**
- `EchoSpacing.screenPadding`
- `Color.mintAccent`
- `Color.noteCardBackground`
- Font extensions from design tokens

### Update HomeView
Replace `ContinueListeningPlaceholder` with actual `ContinueListeningCard` component.

## Success Criteria
- ✅ Card matches Figma design exactly
- ✅ Displays episode artwork, title, podcast name
- ✅ Shows progress bar with time remaining
- ✅ Play button overlay works
- ✅ Tap card opens player
- ✅ Note markers appear at correct positions

---

# PHASE 4: Create Unified EpisodePlayerView (2 hours)

## Reference Documents
- `EpisodePlayerView-Specification.md` - 900-line complete spec with Figma designs
- `miniPlayerBehavior.md` - Mini player integration

## Task
Create single reusable episode player with 3 tabs matching Figma designs.

## Key Requirements

### Three-Tab Layout
1. **Listening Tab** - Artwork, controls, "Add note" button
2. **Notes Tab** - List of notes with timeline
3. **Episode Info Tab** - Description, metadata

### Critical Features
- ✅ Player controls STICKY at bottom across all tabs
- ✅ Segmented control for tab switching
- ✅ TabView for swipe-to-switch
- ✅ Note timeline markers on progress bar
- ✅ "Add note at current time" button
- ✅ HTML stripping for episode descriptions
- ✅ Uses GlobalPlayerManager.shared for state

### Data Models
- Works with RSSEpisode + PodcastEntity (RSS/Core Data)
- No model conversion needed (simpler than 5-phase approach)

## Implementation Steps

1. **Read complete spec:**
   ```bash
   cat EpisodePlayerView-Specification.md
   ```

2. **Create file:** `EchoNotes/Views/Player/EpisodePlayerView.swift`
   - Implement all 3 tabs
   - Add sticky player controls
   - Implement note capture integration
   - Add HTML stripping for descriptions

3. **Update integration points:**
   - MiniPlayerView: Replace sheet with EpisodePlayerView
   - HomeView: Update continue listening tap action
   - ContentView: Update episode taps (if any)

4. **Create AddNoteSheet for RSS models** (if needed)
   - Or adapt existing AddNoteSheet to work with RSSEpisode

## Success Criteria
- ✅ All 3 tabs display correctly
- ✅ Player controls remain sticky
- ✅ Can switch tabs via segmented control AND swipe
- ✅ "Add note" button opens note sheet
- ✅ Notes display in Notes tab
- ✅ Tapping note seeks to timestamp
- ✅ Episode info shows without HTML tags
- ✅ Design matches Figma exactly

---

# PHASE 5: Polish Mini Player (30 minutes)

## Reference Documents
- `miniPlayerBehavior.md` - Figma-accurate mini player spec

## Task
Update MiniPlayerView to match Figma design exactly.

## Key Updates
- Album artwork (48x48pt, 8pt corner radius)
- Episode metadata (title + podcast name)
- Add note button + Play/Pause button
- Show/hide logic when episode playing
- Tap to open full player

## Implementation
Follow specifications in `miniPlayerBehavior.md` exactly.

## Success Criteria
- ✅ Mini player hidden when no episode
- ✅ Shows when episode playing
- ✅ Album artwork displays correctly
- ✅ Add note button works
- ✅ Play/Pause toggles correctly
- ✅ Tapping opens full player
- ✅ Matches Figma design

---

# GIT COMMIT STRATEGY

**After EACH phase:**
```bash
git add .
git commit -m "Phase X: [Description]"
git push origin after-laptop-crash-recovery
```

**Never work >30 minutes without committing!**

---

# TESTING CHECKLIST

After all phases complete:

## HomeView
- [ ] Empty state displays correctly
- [ ] Continue listening section shows current episode
- [ ] Recent notes list displays
- [ ] Greetings change based on time of day

## ContinueListeningCard  
- [ ] Matches Figma design exactly
- [ ] Progress bar accurate
- [ ] Note markers appear
- [ ] Play button overlay works
- [ ] Tap opens player

## EpisodePlayerView
- [ ] All 3 tabs accessible
- [ ] Player controls sticky
- [ ] Tab switching works (tap + swipe)
- [ ] Add note button works
- [ ] Notes save and display
- [ ] Tapping note seeks correctly
- [ ] Episode info displays without HTML

## Mini Player
- [ ] Hidden when no episode
- [ ] Shows when playing
- [ ] Add note button works
- [ ] Play/Pause toggles
- [ ] Opens full player on tap
- [ ] Matches Figma design

---

# TROUBLESHOOTING

## Build Errors
```bash
# Clean build
xcodebuild -project EchoNotes.xcodeproj -scheme EchoNotes clean

# Check for missing imports
grep -r "import" EchoNotes/Views/HomeView.swift
```

## Design Token Not Found
- Verify EchoCastDesignTokens.swift in Xcode project
- Check Target Membership is "EchoNotes"
- Clean and rebuild

## Player State Issues
- GlobalPlayerManager.shared should be singleton
- Check @ObservedObject vs @StateObject usage
- Verify player.currentEpisode is being set

---

# COMPLETION

When all phases done and tests pass:

```bash
git add .
git commit -m "Complete: HomeView + Player consolidation + Mini player polish"
git push origin after-laptop-crash-recovery
```

**Then test the full flow:**
1. Open app → See HomeView
2. Browse/search podcast
3. Tap episode → Player opens with 3 tabs
4. Add note → Saves successfully
5. Close player → Mini player appears
6. Return home → Continue listening shows episode

**SUCCESS!** 🎉
