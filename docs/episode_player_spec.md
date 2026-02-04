# EchoCast Episode Player - Implementation Specification

## Overview
Implement a full-screen sheet-based episode player that displays when a user taps on any episode (downloaded or not). The player includes audio controls, note-taking functionality, and episode information across three tabs.

## Technical Architecture

### Data Models Required

#### Episode Note Model
```swift
@Model
class EpisodeNote {
    var id: UUID
    var episodeId: String  // Links to podcast episode
    var timestamp: TimeInterval  // Current playback position when note was created
    var content: String
    var tags: [String]
    var createdAt: Date
    
    init(episodeId: String, timestamp: TimeInterval, content: String, tags: [String] = []) {
        self.id = UUID()
        self.episodeId = episodeId
        self.timestamp = timestamp
        self.content = content
        self.tags = tags
        self.createdAt = Date()
    }
}
```

#### Player State (Observable)
```swift
@Observable
class PlayerState {
    var currentEpisode: Episode?
    var isPlaying: Bool = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var isDownloaded: Bool = false
    var downloadProgress: Double = 0
    var isDownloading: Bool = false
}
```

## UI Structure

### 1. Main Player Sheet (PlayerView.swift)

**Presentation**: Full-screen sheet presented when user taps an episode

**Layout Hierarchy**:
- Background: System background color
- Top: Close button (top-right, 44x44pt tap target)
- Segmented Control (3 segments, below close button)
- Tab content area (changes based on selected segment)

**Segmented Control**:
- Style: Standard iOS segmented control
- Segments: "Listening", "Notes", "Episode info"
- Default selection: "Listening"

### 2. Listening Tab (ListeningView.swift)

**Visual Hierarchy** (top to bottom):

1. **Episode Artwork**
   - Size: 335x335pt (centered horizontally)
   - Corner radius: 8pt
   - Margin top: 32pt from segmented control
   - Shadow: Subtle drop shadow (opacity 0.1, radius 8, y offset 4)

2. **Episode Title Section**
   - Margin top: 32pt from artwork
   - Podcast name (gray color #6B7280):
     - Font: SF Pro Text, Footnote (13pt), Regular
   - Episode name:
     - Font: SF Pro Display, Headline (17pt), Regular
     - Color: Primary text
     - Margin top: 4pt from podcast name
     - Max lines: 2 with truncation

3. **Progress Slider**
   - Margin top: 48pt from episode name
   - Height: 4pt track
   - Thumb: 20x20pt
   - Min track tint: Mint color (#00c8b3)
   - Max track tint: Light gray (#E5E7EB)
   - Horizontal padding: 44pt each side

4. **Time Labels**
   - Margin top: 8pt from slider
   - Layout: HStack with Spacer between
   - Current time (left): Format as "MM:SS" (e.g., "19:34")
   - Remaining time (right): Format as "-MM:SS" (e.g., "-24:58")
   - Font: SF Pro Text, Caption 1 (12pt), Regular
   - Color: Secondary text (#6B7280)

5. **Playback Controls**
   - Margin top: 32pt from time labels
   - Layout: HStack with equal spacing
   - Horizontal padding: 44pt each side
   
   **Rewind 15s Button**:
   - Icon: Circular arrow with "15" text
   - Size: 60x60pt
   - Color: Primary text
   - Action: Seek backward 15 seconds
   
   **Play/Pause Button**:
   - Icon: Circle.fill with play.fill or pause.fill overlay
   - Size: 88x88pt (larger center button)
   - Color: Primary text
   - Toggle between play and pause states
   
   **Forward 30s Button**:
   - Icon: Circular arrow with "30" text
   - Size: 60x60pt
   - Color: Primary text
   - Action: Seek forward 30 seconds

6. **Add Note Button**
   - Position: Bottom of screen with safe area padding (16pt)
   - Full width with 16pt horizontal padding
   - Height: 56pt
   - Background: Dark green gradient (#1a3c34)
   - Corner radius: 12pt
   - Icon: Plus circle (leading)
   - Text: "Add note at current time"
   - Font: SF Pro Text, Body (17pt), Semibold
   - Color: White
   - Action: Present AddNoteSheet

### 3. Add Note Sheet (AddNoteSheet.swift)

**Presentation**: Modal sheet (not full screen, medium detent)

**Layout**:

1. **Header Section**
   - Margin top: 24pt
   - Horizontal padding: 16pt
   
   **Podcast Title**:
   - Text: Podcast name
   - Font: SF Pro Text, Footnote (13pt), Regular
   - Color: Secondary text (#6B7280)
   
   **Episode Title**:
   - Text: Episode name
   - Font: SF Pro Display, Title 3 (20pt), Regular
   - Color: Primary text
   - Margin top: 4pt
   
   **Timestamp**:
   - Text: Current playback time (e.g., "19:34")
   - Font: SF Pro Text, Subheadline (15pt), Regular
   - Color: Secondary text (#6B7280)
   - Margin top: 8pt

2. **Divider**
   - Margin top: 16pt
   - Color: Separator color

3. **Note Section Header**
   - Margin top: 24pt
   - Horizontal padding: 16pt
   - Text: "Note added at [timestamp]"
   - Font: SF Pro Text, Body (17pt), Semibold
   - Color: Primary text

4. **Note Input Field**
   - Margin top: 12pt
   - Horizontal padding: 16pt
   - Background: Light gray (#F3F4F6)
   - Corner radius: 8pt
   - Min height: 200pt
   - Placeholder: "Add note"
   - Font: SF Pro Text, Body (17pt), Regular
   - Color: Primary text
   - Vertical padding: 12pt
   - Horizontal padding: 12pt

5. **Tags Section**
   - Margin top: 24pt
   - Horizontal padding: 16pt
   
   **Label**:
   - Text: "Tags (optional)"
   - Font: SF Pro Text, Body (17pt), Semibold
   - Color: Primary text
   
   **Tag Input Field**:
   - Margin top: 12pt
   - Background: Light gray (#F3F4F6)
   - Corner radius: 8pt
   - Height: 48pt
   - Placeholder: "Add tag(s)"
   - Font: SF Pro Text, Body (17pt), Regular
   - Horizontal padding: 12pt

6. **Save Button**
   - Position: Bottom with safe area padding (16pt)
   - Full width with 16pt horizontal padding
   - Height: 56pt
   - Background: Dark green (#1a3c34)
   - Corner radius: 12pt
   - Text: "Save note"
   - Font: SF Pro Text, Body (17pt), Semibold
   - Color: White
   - Action: Save note and dismiss sheet

### 4. Notes Tab (NotesView.swift)

**Empty State**:
- Text: "No notes yet"
- Font: SF Pro Text, Body (17pt), Regular
- Color: Secondary text (#6B7280)
- Center aligned

**Notes List**:
- Layout: List with default styling
- Each note row displays:
  - Timestamp badge (pill shape, mint background, white text)
  - Note content preview (2 lines max)
  - Tags (if any) in smaller gray text
  - Tap to expand/edit

### 5. Episode Info Tab (EpisodeInfoView.swift)

**Content**:
- Vertical scroll view
- Horizontal padding: 16pt

**Sections**:

1. **Episode Details**:
   - Duration
   - Release date
   - File size (if downloaded)

2. **Description**:
   - Full episode description
   - Font: SF Pro Text, Body (17pt), Regular
   - Line spacing: 1.4
   - Color: Primary text

3. **Download Section** (if not downloaded):
   - Download button
   - Shows download progress when downloading
   - Disabled during download

## State Management

### PlayerState Properties
```swift
- currentEpisode: Episode? - Currently playing episode
- isPlaying: Bool - Playback state
- currentTime: TimeInterval - Current playback position
- duration: TimeInterval - Total episode duration
- isDownloaded: Bool - Download status
- downloadProgress: Double - Download progress (0.0 to 1.0)
- isDownloading: Bool - Download in progress
- selectedTab: Int - Currently selected tab (0: Listening, 1: Notes, 2: Info)
```

### PlayerState Methods
```swift
- func play() - Start playback
- func pause() - Pause playback
- func seek(to time: TimeInterval) - Seek to specific time
- func skipForward(seconds: Double) - Skip forward by seconds
- func skipBackward(seconds: Double) - Skip backward by seconds
- func togglePlayPause() - Toggle play/pause
- func downloadEpisode() - Initiate download
- func formatTime(_ time: TimeInterval) -> String - Format time as MM:SS
```

## Color Palette

```swift
// Brand Colors
let mintColor = Color(hex: "00c8b3")
let darkGreen = Color(hex: "1a3c34")

// UI Colors
let lightGray = Color(hex: "F3F4F6")
let mediumGray = Color(hex: "E5E7EB")
let textGray = Color(hex: "6B7280")
```

## Typography

```swift
// Episode artwork section
.font(.system(.footnote)) // Podcast name (13pt)
.font(.system(.headline)) // Episode name (17pt)

// Time labels
.font(.system(.caption)) // Time display (12pt)

// Buttons
.font(.system(.body, design: .default, weight: .semibold)) // Button text (17pt)

// Notes
.font(.system(.body)) // Note content (17pt)
```

## Interaction Flows

### Flow 1: Opening Player
1. User taps episode from any screen (Home, Search, Podcast Detail)
2. PlayerView presents as full-screen sheet
3. Default tab is "Listening"
4. If episode is downloaded, load from local storage
5. If not downloaded, show download option in Episode Info tab

### Flow 2: Adding a Note
1. User taps "Add note at current time" button
2. AddNoteSheet presents as modal (medium detent)
3. Sheet pre-fills with current timestamp
4. User types note content
5. User optionally adds tags (comma-separated)
6. User taps "Save note"
7. Note saves to SwiftData with episodeId, timestamp, content, tags
8. Sheet dismisses
9. User switches to "Notes" tab to see saved note

### Flow 3: Playback Control
1. User taps play/pause button → toggles playback state
2. User drags slider → seeks to new position, updates currentTime
3. User taps rewind button → seeks backward 15 seconds
4. User taps forward button → seeks forward 30 seconds
5. Time labels update in real-time during playback

### Flow 4: Downloading Episode
1. User switches to "Episode Info" tab
2. If not downloaded, sees "Download" button
3. User taps download button
4. Button shows progress indicator and percentage
5. When complete, button becomes "Downloaded" (disabled state)
6. Episode now available for offline playback

## Implementation Notes

### Audio Playback
- Use AVPlayer for audio playback
- Implement observer for currentTime updates
- Handle background playback
- Implement remote control events (lock screen controls)

### Download Management
- Use URLSession background download
- Store files in Documents directory
- Track download progress with URLSessionDownloadDelegate
- Update isDownloaded status in Episode model

### SwiftData Integration
- Query notes filtered by episodeId
- Sort notes by timestamp (oldest first)
- Support deletion of notes

### Accessibility
- All buttons have minimum 44x44pt tap targets
- Provide VoiceOver labels for all controls
- Support Dynamic Type
- Ensure sufficient color contrast

## File Structure

```
EchoCast/
├── Views/
│   ├── Player/
│   │   ├── PlayerView.swift (Main container)
│   │   ├── ListeningView.swift (Listening tab)
│   │   ├── NotesView.swift (Notes tab)
│   │   ├── EpisodeInfoView.swift (Episode info tab)
│   │   └── AddNoteSheet.swift (Note creation modal)
├── Models/
│   ├── EpisodeNote.swift
│   └── PlayerState.swift
└── Extensions/
    └── TimeInterval+Formatting.swift
```

## Testing Checklist

- [ ] Player opens when tapping episode from home screen
- [ ] Player opens when tapping episode from search results
- [ ] Player opens when tapping episode from podcast detail
- [ ] Play/pause button toggles correctly
- [ ] Rewind 15s button seeks backward
- [ ] Forward 30s button seeks forward
- [ ] Slider updates during playback
- [ ] Dragging slider seeks correctly
- [ ] Time labels update in real-time
- [ ] Add note button opens AddNoteSheet
- [ ] AddNoteSheet captures current timestamp
- [ ] Saving note adds to SwiftData
- [ ] Notes tab displays saved notes
- [ ] Download button initiates download
- [ ] Download progress updates correctly
- [ ] Downloaded episodes play offline
- [ ] Close button dismisses player
- [ ] Tab switching works smoothly
- [ ] VoiceOver announces all elements correctly
- [ ] Dynamic Type scales text appropriately

## Brand Consistency

All UI elements must use:
- Mint accent color (#00c8b3) for primary actions and progress indicators
- Dark green (#1a3c34) for CTA buttons
- SF Pro font family throughout
- Consistent 16pt horizontal padding
- Consistent 12pt corner radius for cards/buttons (8pt for artwork)
- System gray colors for secondary text and backgrounds
