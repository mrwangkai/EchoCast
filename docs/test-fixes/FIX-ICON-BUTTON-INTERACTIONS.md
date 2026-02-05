# Fix: Icon Buttons Not Opening Sheets

## Issue
Find and Settings icon buttons in HomeView and LibraryView show pressed state but don't open sheets.

## Root Cause
Missing `@State` variables and `.sheet()` modifiers to present the browse/settings views.

---

## Fix for HomeView.swift

### Step 1: Add State Variables

At the top of `HomeView` struct, add:

```swift
struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    // Add these state variables:
    @State private var showingBrowse = false
    @State private var showingSettings = false
    
    // ... rest of existing properties
```

### Step 2: Add Sheet Modifiers

At the end of the `body` variable (after all other modifiers), add:

```swift
var body: some View {
    NavigationStack {
        ScrollView {
            // ... existing content
        }
        .toolbar {
            // ... existing toolbar with buttons
        }
    }
    // Add these sheet modifiers:
    .sheet(isPresented: $showingBrowse) {
        PodcastBrowseView()
    }
    .sheet(isPresented: $showingSettings) {
        SettingsView()
    }
}
```

### Step 3: Verify Button Actions

The toolbar buttons should already have the correct actions, but verify:

```swift
.toolbar {
    ToolbarItem(placement: .principal) {
        Text("EchoCast")
            .font(.largeTitleEcho())
            .foregroundColor(.echoTextPrimary)
    }
    
    ToolbarItemGroup(placement: .navigationBarTrailing) {
        // Find button
        Button(action: {
            showingBrowse = true  // ← Should trigger sheet
        }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20))
                .foregroundColor(.mintAccent)
        }
        
        // Settings button
        Button(action: {
            showingSettings = true  // ← Should trigger sheet
        }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.mintAccent)
        }
    }
}
```

---

## Fix for LibraryView.swift

Apply the exact same fixes to `LibraryView.swift`:

### Step 1: Add State Variables

```swift
struct LibraryView: View {
    @StateObject private var viewModel = NoteViewModel()
    
    // Add these:
    @State private var showingBrowse = false
    @State private var showingSettings = false
    
    // ... rest of existing properties
```

### Step 2: Add Sheet Modifiers

```swift
var body: some View {
    NavigationStack {
        ScrollView {
            // ... existing content
        }
        .toolbar {
            // ... existing toolbar
        }
    }
    // Add these:
    .sheet(isPresented: $showingBrowse) {
        PodcastBrowseView()
    }
    .sheet(isPresented: $showingSettings) {
        SettingsView()
    }
}
```

---

## Create SettingsView.swift (If Missing)

If `SettingsView.swift` doesn't exist, create it:

**File: `EchoNotes/Views/SettingsView.swift`**

```swift
//
//  SettingsView.swift
//  EchoNotes
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
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
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2026.02.05")
                            .foregroundColor(.echoTextSecondary)
                    }
                }
                
                Section("Playback") {
                    Toggle("Auto-play next episode", isOn: .constant(false))
                    Toggle("Background downloads", isOn: .constant(true))
                    
                    HStack {
                        Text("Skip forward")
                        Spacer()
                        Text("30 seconds")
                            .foregroundColor(.echoTextSecondary)
                    }
                    
                    HStack {
                        Text("Skip backward")
                        Spacer()
                        Text("15 seconds")
                            .foregroundColor(.echoTextSecondary)
                    }
                }
                
                Section("Appearance") {
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text("Dark")
                            .foregroundColor(.echoTextSecondary)
                    }
                }
                
                Section("Storage") {
                    HStack {
                        Text("Downloaded episodes")
                        Spacer()
                        Text("0")
                            .foregroundColor(.echoTextSecondary)
                    }
                    
                    Button("Clear cache") {
                        // TODO: Implement cache clearing
                    }
                    .foregroundColor(.red)
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

#Preview {
    SettingsView()
}
```

---

## Verify PodcastBrowseView Exists

Check that you have one of these browse views:
- `PodcastBrowseView.swift`
- `PodcastBrowseRealView.swift`
- `PodcastBrowseNavigationView.swift`

If the name doesn't match what's in `.sheet(isPresented: $showingBrowse)`, update the reference.

Example: If you have `PodcastBrowseRealView.swift`, use:
```swift
.sheet(isPresented: $showingBrowse) {
    PodcastBrowseRealView()
}
```

---

## Testing Checklist After Fix

### HomeView:
- [ ] Tap Find button → Browse sheet opens
- [ ] Browse sheet has search and podcast list
- [ ] Can dismiss browse sheet
- [ ] Tap Settings button → Settings sheet opens
- [ ] Settings sheet has options
- [ ] Can dismiss settings sheet with "Done"

### LibraryView:
- [ ] Tap Find button → Same browse sheet opens
- [ ] Tap Settings button → Same settings sheet opens
- [ ] Both work identically to HomeView

---

## Git Commit After Fix

```bash
git add .
git commit -m "Fix: Wire up Find and Settings icon button interactions

- Added @State variables for sheet presentation
- Added .sheet() modifiers for Browse and Settings
- Created SettingsView.swift placeholder
- Icon buttons now open sheets when tapped
- Applied to both HomeView and LibraryView"

git push origin after-laptop-crash-recovery
```

---

## Common Issues & Solutions

### Issue: "Cannot find PodcastBrowseView"
**Solution:** Check which browse view file exists and use that name

### Issue: Settings view is too basic
**Solution:** This is a placeholder - can enhance later with real settings

### Issue: Browse sheet doesn't show podcasts
**Solution:** Verify PodcastBrowseView has search functionality and API integration

### Issue: Sheets don't dismiss
**Solution:** Ensure browse/settings views have dismiss buttons or swipe-down enabled

---

## Expected Behavior After Fix

**Tap Find button:**
1. Browse sheet slides up from bottom
2. Shows search bar and podcast discovery
3. Can search for podcasts
4. Can tap podcast to see details
5. Swipe down or tap back to dismiss

**Tap Settings button:**
1. Settings sheet slides up from bottom
2. Shows app settings in a list
3. Has "Done" button in top-right
4. Tap "Done" to dismiss

---

**END OF FIX GUIDE**
