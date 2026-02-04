# EchoCast Development Guide

This document captures the consistent patterns used throughout the EchoCast codebase. Follow these patterns when adding new features or modifying existing code.

---

## Table of Contents

1. [Design Tokens](#design-tokens)
2. [Button Styling Patterns](#button-styling-patterns)
3. [Spacing & Padding](#spacing--padding)
4. [Navigation Patterns](#navigation-patterns)
5. [State Management](#state-management)
6. [Color Usage](#color-usage)
7. [Typography](#typography)
8. [File Naming Conventions](#file-naming-conventions)
9. [MARK: Comment Structure](#mark-comment-structure)
10. [View Organization](#view-organization)

---

## Design Tokens

EchoCast uses a centralized design token system in `EchoCastDesignTokens.swift`. Always reference these tokens instead of hardcoding values.

### What We Do

```swift
// Use design token constants
.padding(.horizontal, EchoSpacing.screenPadding)
.font(.largeTitleEcho())
.background(Color.echoBackground)
```

### What We Don't Do

```swift
// Don't hardcode values
.padding(.horizontal, 24)  // Use EchoSpacing.screenPadding instead
.font(.system(size: 34, weight: .bold))  // Use .largeTitleEcho() instead
.background(Color(red: 0.149, green: 0.149, blue: 0.149))  // Use .echoBackground instead
```

### Where to Find Examples

- `/Views/EchoCastDesignTokens.swift` - Complete design token definitions
- `/Views/LibraryView.swift:70-71` - Title with design token
- `/Views/AddNoteSheet.swift:45-56` - Typography tokens

---

## Button Styling Patterns

### Primary Buttons (Mint/Green Theme)

```swift
Button(action: {
    showingPodcastSearch = true
}) {
    Text("Find your podcast")
        .font(.system(size: 17, weight: .medium, design: .rounded))
        .foregroundColor(Color(red: 0.102, green: 0.235, blue: 0.204)) // mintButtonText
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(red: 0.647, green: 0.898, blue: 0.847)) // mintButtonBackground
        .cornerRadius(8)
}
```

### Dark Action Buttons

```swift
Button {
    saveNote()
} label: {
    Text("Save note")
        .font(.system(size: 17, weight: .semibold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color(hex: "1a3c34")) // darkGreenButton
        .cornerRadius(12)
}
.disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
.opacity(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
```

### Icon-Only Buttons (Circular)

```swift
Button(action: {
    showingSettings = true
}) {
    ZStack {
        Circle()
            .fill(Color(red: 0.071, green: 0.071, blue: 0.071)) // menuIndicatorBackground
            .frame(width: 36, height: 36)

        Image(systemName: "gearshape.fill")
            .font(.system(size: 20, weight: .regular))
            .foregroundColor(.white)
    }
}
.buttonStyle(.plain)
```

### iOS 26 Liquid Glass Buttons

```swift
Button("Play") {
    // Action
}
.buttonStyle(.glass)  // Native iOS 26 glass style
```

### What We Don't Do

```swift
// Don't use system button styles without customization
.buttonStyle(.borderedProminent)

// Don't skip disabled state styling
Button("Save") { save() }
// Missing: .disabled(), .opacity()

// Don't use plain buttons for primary actions
Button("Submit") { submit() }
// Should have background color and styling
```

### Where to Find Examples

- `/Views/LibraryView.swift:167-178` - Mint primary button
- `/Views/AddNoteSheet.swift:106-120` - Dark action button with disabled state
- `/Views/LibraryView.swift:77-89` - Circular icon button
- `/Views/LiquidGlassComponents.swift:96-131` - iOS 26 glass buttons

---

## Spacing & Padding

EchoCast defines spacing constants in `EchoSpacing` struct. Use these consistently.

### Standard Spacing Values

| Context | Value | Constant |
|---------|-------|----------|
| Screen horizontal padding | 24pt | `EchoSpacing.screenPadding` |
| Note card padding | 16pt | `EchoSpacing.noteCardPadding` |
| Button height | 54pt | `EchoSpacing.buttonHeight` |
| Search bar height | 40pt | `EchoSpacing.searchBarHeight` |
| Tab bar height | 95pt | `EchoSpacing.tabBarHeight` |
| Vertical spacing between cards | 16pt | `EchoSpacing.noteCardSpacing` |

### What We Do

```swift
// Screen-level padding
VStack {
    // content
}
.padding(.horizontal, EchoSpacing.screenPadding)

// Card padding
.padding(EchoSpacing.noteCardPadding)  // 16pt

// Consistent vertical spacing
VStack(spacing: EchoSpacing.noteCardSpacing) {
    // cards
}

// Button padding
.padding(.vertical, 16)  // For primary buttons
.padding(.horizontal, 24)

// Top padding accounting for status bar
.padding(.top, EchoSpacing.headerTopPadding)  // 80pt
```

### What We Don't Do

```swift
// Don't use magic numbers for standard spacing
.padding(16)  // Use EchoSpacing.noteCardPadding
.padding(.all, 12)  // Define a constant for new patterns

// Don't use inconsistent spacing
.padding(.horizontal, 20)  // One view
.padding(.horizontal, 24)  // Another view
// Be consistent: use EchoSpacing.screenPadding (24pt)
```

### Where to Find Examples

- `/Views/EchoCastDesignTokens.swift:156-200` - All spacing constants
- `/Views/LibraryView.swift:287-291` - Card padding usage
- `/Views/AddNoteSheet.swift:44-103` - Consistent section spacing

---

## Navigation Patterns

### Sheet Presentation (Modal)

```swift
@State private var showingPodcastSearch = false

// In body
.sheet(isPresented: $showingPodcastSearch) {
    Text("Podcast Search")
        .font(.title)
}

// Trigger
Button("Open") {
    showingPodcastSearch = true
}
```

### Sheet with Data Passing

```swift
@State private var selectedEpisode: RSSEpisode?
@State private var showPlayerSheet = false

Button(action: {
    selectedEpisode = episode
    showPlayerSheet = true
}) {
    // Button content
}
.sheet(isPresented: $showPlayerSheet) {
    if let episode = selectedEpisode {
        PlayerSheetWrapper(
            episode: episode,
            podcast: podcast,
            dismiss: { showPlayerSheet = false }
        )
    }
}
```

### NavigationLink (Push Navigation)

```swift
NavigationLink(value: episode) {
    EpisodeRowView(episode: episode)
}
.navigationDestination(for: RSSEpisode.self) { episode in
    EpisodeDetailView(episode: episode, podcast: podcast)
}
```

### Programmatic Dismissal

```swift
@Environment(\.dismiss) private var dismiss

// In action
Button("Close") {
    dismiss()
}
```

### What We Don't Do

```swift
// Don't use fullScreenCover for standard navigation
.fullScreenCover(isPresented: $showingDetail) {
    // Should use .sheet or NavigationLink
}

// Don't use toggle for sheet state with data
.sheet(isPresented: $showingSheet) {
    // What if selectedEpisode is nil?
}
```

### Where to Find Examples

- `/Views/LibraryView.swift:54-60` - Sheet presentation
- `/Views/PodcastDetailView.swift:47-57, 105-136` - Sheet with data passing
- `/Views/EpisodeDetailView.swift:146-156` - NavigationLink pattern
- `/Views/AddNoteSheet.swift:31` - Environment dismiss

---

## State Management

### @StateObject (View-Owned Observable Object)

```swift
struct LibraryView: View {
    @StateObject private var viewModel = NoteViewModel()
}
```

Use `@StateObject` when:
- The view creates and owns the observable object
- The object should persist across view redraws

### @ObservedObject (Shared Observable Object)

```swift
@ObservedObject private var downloadManager = EpisodeDownloadManager.shared
```

Use `@ObservedObject` when:
- The object is a shared singleton
- The object is owned elsewhere but this view needs to observe it

### @State (Local View State)

```swift
@State private var showingSortOptions = false
@State private var selectedEpisode: DownloadedEpisode?
@State private var isExpanded = false
```

Use `@State` for:
- Boolean toggles (showing sheets, alerts)
- Optional selections
- Simple local state

### @Bindable (iOS 17+ Observation)

```swift
@Bindable var playerState: PlayerState
```

Use `@Bindable` for:
- Observable objects that need two-way binding
- Pass-through to child views

### @FetchRequest (Core Data)

```swift
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
    animation: .default
)
private var notes: FetchedResults<NoteEntity>
```

### @Environment (System Values)

```swift
@Environment(\.managedObjectContext) private var viewContext
@Environment(\.dismiss) private var dismiss
```

### What We Don't Do

```swift
// Don't use @StateObject for singletons
@StateObject private var downloadManager = EpisodeDownloadManager.shared
// Should be @ObservedObject

// Don't use @ObservedObject for view-owned objects
@ObservedObject private var viewModel = NoteViewModel()
// Should be @StateObject

// Don't forget @State for simple values
var isExpanded = false  // Won't update UI
// Should be @State
```

### Where to Find Examples

- `/Views/LibraryView.swift:15` - @StateObject for ViewModel
- `/Views/PodcastDetailView.swift:20, 263` - @ObservedObject for singleton
- `/Views/LibraryView.swift:16-18` - @State for local state
- `/Views/AddNoteSheet.swift:30` - @Bindable for Observable object
- `/Views/HomeView.swift:15-18` - @FetchRequest for Core Data
- `/Views/PodcastDetailView.swift:19` - Environment values

---

## Color Usage

### Semantic Colors (Preferred)

```swift
// Text
.foregroundColor(.echoTextPrimary)    // White
.foregroundColor(.echoTextSecondary)  // 85% white
.foregroundColor(.echoTextTertiary)   // 65% white

// Backgrounds
.background(Color.echoBackground)
.background(Color.noteCardBackground)
.background(Color.searchFieldBackground)

// Accents
.background(Color.mintAccent)
.foregroundColor(Color.mintButtonText)
```

### Opacity Patterns

```swift
// White with opacity
.foregroundColor(.white.opacity(0.85))
.foregroundColor(.white.opacity(0.65))
.foregroundColor(.white.opacity(0.7))

// System semantic
.foregroundColor(.primary)
.foregroundColor(.secondary)
```

### Light/Dark Mode Handling

```swift
// Currently: Dark mode only (per Figma)
// All colors are explicit for dark mode
Color(red: 0.149, green: 0.149, blue: 0.149) // #262626
```

### What We Don't Do

```swift
// Don't use hardcoded RGB for semantic colors
.foregroundColor(Color(red: 1, green: 1, blue: 1))  // Use .white or .echoTextPrimary

// Don't mix semantic and literal colors inconsistently
.background(Color.gray.opacity(0.2))  // Use a design token

// Don't assume light mode support (app is dark-mode only)
// All colors should be dark mode appropriate
```

### Where to Find Examples

- `/Views/EchoCastDesignTokens.swift:62-152` - All color definitions
- `/Views/LibraryView.swift:71, 99-100, 224, 231` - Text color usage
- `/Views/LibraryView.swift:82, 107-108` - Background color usage
- `/Views/LibraryView.swift:241, 267` - Opacity patterns

---

## Typography

### Font Extension Methods (Preferred)

```swift
.font(.largeTitleEcho())       // 34pt Bold
.font(.title2Echo())           // 22pt Bold
.font(.bodyEcho())             // 17pt Regular
.font(.bodyRoundedMedium())    // 17pt Rounded Medium
.font(.subheadlineRounded())   // 15pt Rounded Medium
.font(.captionRounded())       // 13pt Regular
.font(.caption2Medium())       // 12pt Medium
.font(.tabLabel())             // 10pt Semibold
.font(.tabLabelMedium())       // 10pt Medium
```

### Direct System Font (When Custom Needed)

```swift
.font(.system(size: 20, weight: .regular))
.font(.system(size: 34, weight: .bold))
```

### Font Patterns by Context

| Context | Font |
|---------|------|
| Screen title | `largeTitleEcho()` |
| Section header | `title2Echo()` |
| Body text | `bodyEcho()` or `bodyRoundedMedium()` |
| Subheading | `subheadlineRounded()` |
| Caption/label | `captionRounded()` or `caption2Medium()` |
| Tab label | `tabLabel()` |
| Timestamp | `caption2Medium()` |

### What We Don't Do

```swift
// Don't hardcode values when design token exists
.font(.system(size: 34, weight: .bold))  // Use .largeTitleEcho()
.font(.system(size: 17, weight: .medium, design: .rounded))  // Use .bodyRoundedMedium()

// Don't use inconsistent sizes for same context
.font(.system(size: 16))  // In one place
.font(.system(size: 17))  // In another place for same purpose
```

### Where to Find Examples

- `/Views/EchoCastDesignTokens.swift:11-58` - Font extensions
- `/Views/LibraryView.swift:70` - Title font
- `/Views/LibraryView.swift:223-224` - Episode title font
- `/Views/AddNoteSheet.swift:47-51` - Hierarchy of fonts

---

## File Naming Conventions

### Views

```
[FeatureName]View.swift       // Main feature view
[FeatureName][Type]View.swift  // Specific sub-view
```

Examples:
- `LibraryView.swift`
- `PodcastDetailView.swift`
- `EpisodeDetailView.swift`
- `AddNoteSheet.swift` (Sheet suffix)
- `NoteCaptureView.swift` (no View suffix needed for clarity)

### ViewModels

```
[FeatureName]ViewModel.swift
```

Examples:
- `NoteViewModel.swift`
- `PodcastBrowseViewModel.swift`

### Components

```
[ComponentName]View.swift
[ComponentName].swift
```

Examples:
- `BannerView.swift`
- `FlowLayout.swift`

### What We Don't Do

```swift
// Don't use unclear abbreviations
LibVw.swift

// Don't mix naming conventions
noteView.swift
Note_view.swift

// Don't put multiple top-level types in one file (unless related)
// Good: PodcastDetailView.swift contains PodcastDetailView + PodcastHeaderView + EpisodeRowView
// Bad: HomeView.swift contains HomeView + SettingsView + ProfileView
```

### Where to Find Examples

- `/Views/` directory - All view naming patterns
- `/ViewModels/` directory - ViewModel naming
- `/Components/` directory - Component naming

---

## MARK: Comment Structure

EchoCast uses `// MARK:` comments to organize code into logical sections.

### Standard MARK Sections

```swift
// MARK: - Main [View Name] View

struct LibraryView: View {
    // ...
}

// MARK: - Header View

private var headerView: some View {
    // ...
}

// MARK: - Empty State View

private var emptyStateView: some View {
    // ...
}

// MARK: - Notes List View

private var notesListView: some View {
    // ...
}

// MARK: - Library Note Card View

struct LibraryNoteCardView: View {
    // ...
}

// MARK: - Preview

#Preview("Empty State") {
    LibraryView()
}
```

### Extension MARKs

```swift
// MARK: - Font Extensions

extension Font {
    // ...
}

// MARK: - Color Extensions

extension Color {
    // ...
}

// MARK: - Spacing Constants

struct EchoSpacing {
    // ...
}

// MARK: - TimeInterval Formatting Extension

extension TimeInterval {
    func formattedTimestamp() -> String {
        // ...
    }
}
```

### What We Don't Do

```swift
// Don't use inconsistent comment styles
/* Header View */

// MARK: Header View  // Missing hyphen

// MARK: - Random Section
// Keep sections logical and consistent

// Don't skip MARK comments for logical sections
// Always add a MARK when starting a new sub-view or extension
```

### Where to Find Examples

- `/Views/LibraryView.swift:12, 63, 135, 186, 199, 295` - MARK usage
- `/Views/EchoCastDesignTokens.swift:11, 60, 154, 202` - MARK in design tokens
- `/Views/AddNoteSheet.swift:10, 27` - Extension and view MARKs

---

## View Organization

### Standard View Structure

```swift
//
//  FileName.swift
//  EchoNotes
//
//  Brief description of what this view does
//

import SwiftUI
// Other imports

// MARK: - Extension (if any)

extension SomeType {
    // extension content
}

// MARK: - Main View

struct MainView: View {
    // Properties (@State, @Environment, etc.)

    var body: some View {
        // View hierarchy
    }

    // MARK: - Computed Properties (private vars)

    private var subView1: some View {
        // ...
    }

    private var subView2: some View {
        // ...
    }

    // MARK: - Methods

    private func someMethod() {
        // ...
    }
}

// MARK: - Supporting Views (if in same file)

struct SupportingView: View {
    // ...
}

// MARK: - Preview

#Preview("Preview Name") {
    MainView()
}
```

### Computed Property Pattern

Extract sub-views into computed properties:

```swift
struct LibraryView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerView
                notesContentView
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 24) {
            // ...
        }
    }

    private var notesContentView: some View {
        // ...
    }
}
```

### Child View as Separate Type

```swift
// MARK: - Library Note Card View

struct LibraryNoteCardView: View {
    let note: NoteEntity
    @State private var isExpanded = false

    var body: some View {
        // ...
    }
}
```

### What We Don't Do

```swift
// Don't put everything in body
var body: some View {
    VStack {
        // 100 lines of nested view code
    }
}

// Don't mix @State in child views unnecessarily
struct ChildView: View {
    @State private var parentState = false  // Should be passed down
}

// Don't skip file headers
// Always include the comment header with filename and description
```

### Where to Find Examples

- `/Views/LibraryView.swift:1-296` - Well-organized main view
- `/Views/LibraryView.swift:199-293` - Child view pattern
- `/Views/AddNoteSheet.swift:1-192` - File header and structure
- `/Views/PodcastDetailView.swift:187-254, 256-392` - Multiple supporting views

---

## Additional Patterns

### Empty State Handling

```swift
if viewModel.notes.isEmpty {
    emptyStateView
} else {
    notesListView
}
```

### Loading State

```swift
if isLoadingEpisodes {
    ProgressView("Loading episodes...")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}
```

### Card Pattern

```swift
VStack(alignment: .leading, spacing: 16) {
    // Content
}
.padding(16)
.background(Color(red: 0.2, green: 0.2, blue: 0.2))
.cornerRadius(8)
.shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
.shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
```

### Search Pattern

```swift
HStack(spacing: 8) {
    Image(systemName: "magnifyingglass")
        .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))

    TextField("Search notes in library", text: $viewModel.searchText)
        .textFieldStyle(.plain)
        .font(.system(size: 17))
        .foregroundColor(.white)
}
.padding(10)
.background(Color(red: 0.463, green: 0.463, blue: 0.502, opacity: 0.24))
.cornerRadius(8)
```

---

## Quick Reference

### Common Imports

```swift
import SwiftUI
import CoreData
import Combine
import AVFoundation
```

### Standard File Header

```swift
//
//  FileName.swift
//  EchoNotes
//
//  Brief description
//
```

### State Property Declaration Order

1. `@Environment` values
2. `@FetchRequest` properties
3. `@StateObject` properties
4. `@ObservedObject` properties
5. `@Bindable` properties
6. `@State` properties
7. Regular properties (`let`, `var`)

---

## Summary Table

| Pattern | Do | Don't |
|---------|-----|-------|
| Design Tokens | Use `EchoSpacing.*`, `.largeTitleEcho()`, `.echoBackground` | Hardcode values |
| Buttons | Consistent styling, disabled states, mint theme | Mixed styles, no disabled state |
| Spacing | Use constants (24, 16, 8, 4) | Magic numbers, inconsistent values |
| Navigation | `.sheet()` for modals, `NavigationLink` for push | `.fullScreenCover` for standard flows |
| State | `@StateObject` for owned, `@ObservedObject` for shared | `@ObservedObject` for view-owned objects |
| Colors | Semantic colors (`.echoTextPrimary`) | Hardcoded RGB, assuming light mode |
| Typography | Font extensions (`.largeTitleEcho()`) | Hardcoded sizes when token exists |
| Naming | `LibraryView.swift`, `NoteViewModel.swift` | Abbreviations, inconsistent case |
| Comments | `// MARK: - Section Name` | Missing hyphens, inconsistent style |
| Organization | Computed properties, separate types | Everything in body |
