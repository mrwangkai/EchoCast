# EchoNotes - Xcode Project Prototype

A native iOS app for capturing timestamped notes during podcast playback with voice-first interaction.

## Project Overview

EchoNotes enables podcast listeners to capture insights effortlessly through:
- **Voice-activated note capture** via Siri
- **Quick tap capture** with floating action button
- **Library view** for browsing and searching notes
- **Export functionality** (Markdown, Share Sheet)
- **Podcast discovery** and management

## Project Structure

```
EchoNotes/
├── EchoNotes.xcodeproj/          # Xcode project configuration
│   └── project.pbxproj
├── EchoNotes/                     # Main app source
│   ├── EchoNotesApp.swift        # App entry point
│   ├── ContentView.swift         # Main tab view
│   ├── Info.plist                # App configuration
│   │
│   ├── Views/                     # SwiftUI views
│   │   ├── LibraryView.swift    # Notes library with search/filter
│   │   ├── NoteCaptureView.swift # Note capture with voice recognition
│   │   └── PodcastDiscoveryView.swift # Podcast search and management
│   │
│   ├── Models/                    # Data models
│   │   ├── Note.swift            # Note model
│   │   ├── Podcast.swift         # Podcast model
│   │   └── EchoNotes.xcdatamodeld/ # CoreData schema
│   │
│   ├── ViewModels/               # Business logic
│   │   └── NoteViewModel.swift  # Notes management
│   │
│   ├── Services/                 # Services layer
│   │   ├── PersistenceController.swift # CoreData management
│   │   ├── ExportService.swift  # Markdown export & sharing
│   │   └── SiriShortcutsManager.swift # Siri integration
│   │
│   └── Resources/                # Assets and resources
│       ├── Assets.xcassets/
│       └── Intents.intentdefinition # Siri Shortcuts definition
│
└── README.md                     # This file
```

## Features Implementation

### ✅ Core Features (P0)

1. **Library View** (`LibraryView.swift`)
   - Search and filter notes
   - Group by show and episode
   - Sort by date, show, or timestamp
   - Priority flagging with star icon
   - Swipe actions for quick priority toggle

2. **Quick Note Capture** (`NoteCaptureView.swift`)
   - Floating action button on main screens
   - Voice recording with Speech Recognition
   - Manual text input
   - Auto-timestamp generation
   - Priority toggle
   - Podcast metadata fields

3. **Local Persistence** (`PersistenceController.swift`)
   - CoreData storage for notes and podcasts
   - Full CRUD operations
   - Preview data for SwiftUI previews

### ✅ Secondary Features (P1)

4. **Podcast Discovery** (`PodcastDiscoveryView.swift`)
   - Search interface (ready for API integration)
   - Save podcasts to "My Podcasts"
   - Mock data for testing
   - Easy integration point for Listen Notes API

5. **Export & Share** (`ExportService.swift`)
   - Markdown export with formatting
   - iOS Share Sheet integration
   - Export to Notes, Reminders, Files
   - Formatted quote generation

6. **Siri Shortcuts** (`SiriShortcutsManager.swift`)
   - Custom "Capture Note" intent
   - Voice shortcut support
   - User activity donation
   - Haptic feedback

## Getting Started

### Requirements
- Xcode 15.0+
- iOS 17.0+
- macOS Sonoma or later

### Opening the Project

1. Open `EchoNotes.xcodeproj` in Xcode
2. Select a target device or simulator
3. Press `⌘R` to build and run

### Permissions Required

The app requests the following permissions:
- **Microphone** - For voice note recording
- **Speech Recognition** - For transcribing voice notes
- **Siri & Shortcuts** - For hands-free note capture

These are configured in `Info.plist` with user-friendly descriptions.

## Key Components

### Data Model

**NoteEntity** (CoreData)
- `id`: UUID
- `showTitle`: String
- `episodeTitle`: String
- `timestamp`: String (HH:MM:SS)
- `noteText`: String
- `isPriority`: Bool
- `tags`: String (comma-separated)
- `createdAt`: Date
- `sourceApp`: String

**PodcastEntity** (CoreData)
- `id`: UUID
- `title`: String
- `author`: String
- `podcastDescription`: String
- `artworkURL`: String

### Architecture

The app follows MVVM architecture:
- **Models**: Data structures and CoreData entities
- **Views**: SwiftUI views for UI
- **ViewModels**: Business logic and state management
- **Services**: Shared services (persistence, export, Siri)

### Voice Recording

Uses Apple's Speech Framework:
1. Requests microphone and speech recognition permissions
2. Captures audio via `AVAudioEngine`
3. Transcribes in real-time via `SFSpeechRecognizer`
4. Updates note text as user speaks

## Future Integration Points

### Listen Notes API
In `PodcastDiscoveryView.swift`, replace mock data with API calls:
```swift
private func performSearch() {
    // Call Listen Notes API here
    // Update filteredPodcasts with results
}
```

### Siri Shortcuts
1. Add Intents extension target to project
2. Implement `CaptureNoteIntentHandler`
3. Configure in Shortcuts app

### Cloud Sync
Add CloudKit support to `PersistenceController.swift`:
```swift
container = NSPersistentCloudKitContainer(name: "EchoNotes")
```

## Testing

### Preview Data
Sample data is available in:
- `Note.samples` - Sample notes
- `Podcast.samples` - Sample podcasts
- `PersistenceController.preview` - In-memory CoreData store

### SwiftUI Previews
All views include `#Preview` blocks for live preview in Xcode Canvas.

## Build Configuration

### Debug
- Testability enabled
- Full debug symbols
- Deployment target: iOS 17.0

### Release
- Optimizations enabled
- Symbol stripping
- Code signing required for device installation

## Notes for Implementation

1. **API Integration**: Replace mock podcast data with Listen Notes API calls
2. **Audio Context**: Integrate with `AVAudioSession` to read current podcast playback
3. **Widget Support**: Add Widget extension for recent notes
4. **iCloud Sync**: Enable CloudKit for cross-device sync
5. **Haptic Feedback**: Enhance throughout app for better UX

## Troubleshooting

### Build Errors
- Ensure all files are included in target membership
- Check Swift version is set to 5.0
- Verify deployment target matches device/simulator

### Permissions
- Reset permissions: Settings → General → Reset → Reset Location & Privacy

### CoreData
- Delete app and reinstall to reset data model
- Check entity names match class names

## License

This is a prototype project generated for development purposes.

---

**Generated**: October 29, 2025
**Based on**: PRD_echocast.md v1.1
**Platform**: iOS 17.0+
