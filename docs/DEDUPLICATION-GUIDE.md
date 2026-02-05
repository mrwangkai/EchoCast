# EchoCast Deduplication & Navigation Fix

## Problem Analysis

**Current State (After Phase 1-5):**
- ❌ Duplicate player components exist
- ❌ Duplicate note sheets exist
- ❌ Wrong tab structure (3+ tabs instead of 2)
- ❌ Missing Find + Settings icon buttons

**Target State:**
- ✅ Single unified `EpisodePlayerView.swift`
- ✅ Single note capture component
- ✅ 2 tabs only: Home + Library
- ✅ Top-right icon buttons: Find (browse) + Settings

---

## STEP 1: Identify All Duplicates

Run these commands to find duplicates:

```bash
# Find all player-related files
find EchoNotes -name "*Player*.swift" -type f

# Find all note sheet files
find EchoNotes -name "*Note*.swift" | grep -i sheet

# Check current navigation structure
grep -r "TabView\|.tag(" EchoNotes/ContentView.swift | head -20
```

**Expected duplicates:**
1. `AudioPlayerView.swift` (old) vs. `Player/EpisodePlayerView.swift` (new)
2. `AddNoteSheet.swift` (old) vs. note sheet in EpisodePlayerView (new)
3. Possibly `FullPlayerView` struct inside MiniPlayerView.swift

---

## STEP 2: Consolidate to Single Player

### Task 2A: Verify Which Player is Better

**Check EpisodePlayerView (new):**
```bash
wc -l EchoNotes/Views/Player/EpisodePlayerView.swift
grep -c "Tab\|Listening\|Notes\|Episode Info" EchoNotes/Views/Player/EpisodePlayerView.swift
```

**Check AudioPlayerView (old):**
```bash
wc -l EchoNotes/Views/AudioPlayerView.swift
grep -c "Tab\|Listening\|Notes" EchoNotes/Views/AudioPlayerView.swift
```

**Decision:**
- If `EpisodePlayerView.swift` has 3 tabs (Listening, Notes, Episode Info) → Keep it ✅
- Delete `AudioPlayerView.swift` ❌

### Task 2B: Find All References to Old Player

```bash
# Find where AudioPlayerView is used
grep -r "AudioPlayerView" EchoNotes --include="*.swift"

# Find where FullPlayerView is used
grep -r "FullPlayerView" EchoNotes --include="*.swift"
```

### Task 2C: Replace Old Player References

**For each file that references `AudioPlayerView`:**

1. **In MiniPlayerView.swift:**
   - Find: `.sheet(isPresented: $showFullPlayer) { AudioPlayerView(...) }`
   - Replace with: `.sheet(isPresented: $showFullPlayer) { EpisodePlayerView(...) }`

2. **In ContentView.swift:**
   - Find any `AudioPlayerView` references
   - Replace with `EpisodePlayerView`

3. **In HomeView.swift:**
   - Find any player sheet presentations
   - Replace with `EpisodePlayerView`

### Task 2D: Delete Old Player File

```bash
# After confirming all references updated:
rm EchoNotes/Views/AudioPlayerView.swift

# If FullPlayerView struct exists in MiniPlayerView:
# Open MiniPlayerView.swift and delete the entire FullPlayerView struct
```

---

## STEP 3: Consolidate Note Capture

### Task 3A: Check for Duplicate Note Sheets

```bash
# Find all note sheet files
find EchoNotes/Views -name "*Note*.swift" | grep -i "sheet\|capture"
```

**Likely duplicates:**
- `AddNoteSheet.swift` (old, iTunes models)
- Note capture in `EpisodePlayerView.swift` (new, RSS models)
- `NoteCaptureView.swift` (if exists)

### Task 3B: Decide Which to Keep

**Check if AddNoteSheet uses iTunes or RSS models:**
```bash
grep "iTunesPodcast\|RSSEpisode\|PodcastEntity" EchoNotes/Views/AddNoteSheet.swift
```

**Decision:**
- If `AddNoteSheet.swift` uses iTunes models (iTunesPodcast) → Delete ❌
- If `EpisodePlayerView` has note capture with RSS models → Keep ✅

### Task 3C: Remove Old Note Sheet

If AddNoteSheet is old/unused:
```bash
rm EchoNotes/Views/AddNoteSheet.swift
```

---

## STEP 4: Fix Navigation Structure

### Current Wrong Structure
```swift
TabView(selection: $selectedTab) {
    HomeView().tag(0)
    LibraryView().tag(1)
    SomeOtherView().tag(2)  // ❌ Extra tab
    SettingsView().tag(3)   // ❌ Extra tab
}
```

### Target Correct Structure
```swift
TabView(selection: $selectedTab) {
    HomeView().tag(0)      // ✅ Home tab
    LibraryView().tag(1)   // ✅ Library tab
}
// No other tabs!
```

### Task 4A: Update ContentView Tab Structure

**In `ContentView.swift`, find the TabView section and modify:**

```swift
var body: some View {
    ZStack(alignment: .bottom) {
        // Main content with navigation
        NavigationStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "book.fill")
                    }
                    .tag(1)
            }
            .tint(.mintAccent)  // Use design token
        }
        
        // Mini player above tab bar
        if player.currentEpisode != nil {
            MiniPlayerView()
                .transition(.move(edge: .bottom))
        }
    }
    .sheet(isPresented: $showingPlayerSheet) {
        if let episode = player.currentEpisode, 
           let podcast = player.currentPodcast {
            EpisodePlayerView(episode: episode, podcast: podcast)
        }
    }
}
```

---

## STEP 5: Add Find + Settings Icon Buttons

### Task 5A: Add to HomeView Header

**In `HomeView.swift`, update the header section:**

```swift
var body: some View {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Content sections...
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
        }
        .background(Color.echoBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("EchoCast")
                    .font(.largeTitleEcho())
                    .foregroundColor(.echoTextPrimary)
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Find button (Browse)
                Button(action: {
                    showingBrowse = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.mintAccent)
                }
                .buttonStyle(.glass)  // iOS 26 liquid glass style
                
                // Settings button
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.mintAccent)
                }
                .buttonStyle(.glass)  // iOS 26 liquid glass style
            }
        }
    }
    .sheet(isPresented: $showingBrowse) {
        // Browse/Search flow
        PodcastBrowseNavigationView()
    }
    .sheet(isPresented: $showingSettings) {
        // Settings view
        SettingsPlaceholderView()
    }
}
```

**Add state variables at top of HomeView:**
```swift
@State private var showingBrowse = false
@State private var showingSettings = false
```

### Task 5B: Create Settings Placeholder

**Create: `EchoNotes/Views/SettingsView.swift`**

```swift
//
//  SettingsView.swift
//  EchoNotes
//
//  App settings and preferences
//

import SwiftUI

struct SettingsPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.echoTextSecondary)
                    }
                }
                
                Section("Playback") {
                    Toggle("Auto-play next episode", isOn: .constant(false))
                    Toggle("Background downloads", isOn: .constant(true))
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text("Dark")
                            .foregroundColor(.echoTextSecondary)
                    }
                }
            }
            .navigationTitle("Settings")
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
```

---

## STEP 6: Update Library Tab Header

**In `LibraryView.swift`, add similar icon buttons:**

```swift
.toolbar {
    ToolbarItem(placement: .principal) {
        Text("Library")
            .font(.largeTitleEcho())
            .foregroundColor(.echoTextPrimary)
    }
    
    ToolbarItemGroup(placement: .navigationBarTrailing) {
        // Find button
        Button(action: {
            showingBrowse = true
        }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(.mintAccent)
        }
        .buttonStyle(.glass)
        
        // Settings button
        Button(action: {
            showingSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.mintAccent)
        }
        .buttonStyle(.glass)
    }
}
```

---

## STEP 7: Verification

### Build & Test

```bash
# Clean build
xcodebuild -project EchoNotes.xcodeproj -scheme EchoNotes clean build
```

### Test Checklist

**Navigation:**
- [ ] App shows only 2 tabs: Home + Library
- [ ] No extra tabs visible
- [ ] Tab icons are correct

**Icon Buttons:**
- [ ] Home screen has Find + Settings buttons (top-right)
- [ ] Library screen has Find + Settings buttons (top-right)
- [ ] Buttons use iOS 26 glass style
- [ ] Buttons are mint color (#00c8b3)

**Player:**
- [ ] Tapping episode opens `EpisodePlayerView` (not AudioPlayerView)
- [ ] Player has 3 tabs (Listening, Notes, Episode Info)
- [ ] No duplicate player views exist

**Notes:**
- [ ] "Add note" button works in player
- [ ] Only one note capture interface exists
- [ ] No duplicate note sheets

**Browse:**
- [ ] Tapping Find button opens browse/search
- [ ] Browse view slides in as sheet
- [ ] Can search and find podcasts
- [ ] Tapping podcast shows detail

**Settings:**
- [ ] Tapping Settings button opens settings
- [ ] Settings view slides in as sheet
- [ ] Can dismiss settings

---

## STEP 8: Git Commit

After successful deduplication:

```bash
git add .
git commit -m "Fix: Remove duplicate components, restore 2-tab navigation with icon buttons

- Deleted AudioPlayerView.swift (duplicate)
- Unified on EpisodePlayerView.swift
- Removed duplicate note sheets
- Fixed navigation: 2 tabs (Home + Library)
- Added Find + Settings icon buttons to headers
- Applied iOS 26 glass button style"

git push origin after-laptop-crash-recovery
```

---

## Summary of Changes

### Files Deleted ❌
- `AudioPlayerView.swift` (replaced by EpisodePlayerView)
- `AddNoteSheet.swift` (if using iTunes models, replaced by RSS version)
- Any extra tab views

### Files Modified ✅
- `ContentView.swift` - 2-tab structure, removed extra tabs
- `HomeView.swift` - Added Find + Settings icon buttons
- `LibraryView.swift` - Added Find + Settings icon buttons
- `MiniPlayerView.swift` - References EpisodePlayerView instead of AudioPlayerView

### Files Created ✅
- `SettingsView.swift` - Settings placeholder

### Result
- ✅ Single unified player (EpisodePlayerView)
- ✅ Single note capture system
- ✅ 2 tabs: Home + Library
- ✅ Icon buttons: Find + Settings (iOS 26 glass style)
- ✅ No duplicates
- ✅ Clean architecture

---

**END OF DEDUPLICATION GUIDE**
