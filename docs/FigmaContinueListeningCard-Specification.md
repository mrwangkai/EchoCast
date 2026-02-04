# Continue Listening Card Component Specification

**Figma Reference:** https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1696-3836&t=0S5nKaWUWbL48hc5-4

**Component Purpose:** Display a podcast episode with playback progress in a horizontal card format for the "Continue listening" section on the Home screen.

---

## Visual Reference

The card displays:
- Left: Square podcast artwork
- Center: Episode title, podcast name, progress bar, metadata (notes count, time remaining)
- Right: Circular play button

---

## Component Structure

```
ContinueListeningCard (VStack)
├── Artwork + Content (HStack)
│   ├── Podcast Artwork (AsyncImage)
│   ├── Episode Info (VStack)
│   │   ├── Episode Title (Text)
│   │   ├── Podcast Name (Text)
│   │   ├── Progress Bar (ProgressView)
│   │   └── Metadata Row (HStack)
│   │       ├── Notes Indicator (HStack)
│   │       │   ├── Icon (Image)
│   │       │   └── Count (Text)
│   │       └── Time Remaining (Text)
│   └── Play Button (Button with Circle + Icon)
```

---

## Measurements & Layout

### Card Container
- **Background Color:** `#333333` (rgb 51, 51, 51) → `Color(red: 0.2, green: 0.2, blue: 0.2)`
- **Corner Radius:** 12pt
- **Padding (internal):** 16pt all sides
- **Shadow:** 
  - Primary: `Color.black.opacity(0.3)`, radius: 3, x: 0, y: 1
  - Secondary: `Color.black.opacity(0.15)`, radius: 2, x: 0, y: 1
- **Card Width:** Dynamic (fills horizontal scroll space, typically ~320-360pt)
- **Card Height:** Auto-sized by content (approximately 140pt)

### Podcast Artwork
- **Size:** 88x88pt (square)
- **Corner Radius:** 8pt
- **Position:** Leading edge, vertically centered
- **Trailing Spacing:** 12pt to episode info

### Episode Info Section (VStack)
- **Alignment:** `.leading`
- **Spacing:** 8pt between elements
- **Max Width:** Flexible (fills space between artwork and play button)

#### Episode Title (Text)
- **Font:** SF Pro Rounded Medium, 17pt → `.system(size: 17, weight: .medium, design: .rounded)`
- **Color:** White 100% → `Color.white`
- **Line Limit:** 2 lines
- **Line Height:** Default (approximately 22pt)

#### Podcast Name (Text)
- **Font:** SF Pro Regular, 15pt → `.system(size: 15, weight: .regular)`
- **Color:** White 85% → `Color.white.opacity(0.85)`
- **Line Limit:** 1 line

#### Progress Bar (ProgressView)
- **Height:** 4pt
- **Tint Color:** Mint accent `#00c8b3` → `Color(red: 0.0, green: 0.784, blue: 0.702)`
- **Track Color:** System default (dark gray)
- **Corner Radius:** 2pt (system default)
- **Top Margin:** 4pt
- **Bottom Margin:** 6pt

#### Metadata Row (HStack)
- **Alignment:** `.center`
- **Spacing:** 8pt between notes indicator and time remaining

##### Notes Indicator (HStack)
- **Spacing:** 4pt between icon and count
- **Icon:**
  - SF Symbol: `doc.text` or `note.text`
  - Size: 12pt → `.system(size: 12)`
  - Color: White 70% → `Color.white.opacity(0.7)`
- **Count Text:**
  - Font: SF Pro Medium, 12pt → `.system(size: 12, weight: .medium)`
  - Color: White 70% → `Color.white.opacity(0.7)`
  - Format: "{count} notes" (e.g., "9 notes")

##### Time Remaining (Text)
- **Font:** SF Pro Regular, 12pt → `.system(size: 12, weight: .regular)`
- **Color:** White 70% → `Color.white.opacity(0.7)`
- **Format:** "{time} left" (e.g., "0:48 left")
- **Position:** Trailing edge of metadata row

### Play Button
- **Container:** Circle
  - Size: 48x48pt
  - Color: Mint accent `#00c8b3` → `Color(red: 0.0, green: 0.784, blue: 0.702)`
- **Icon:** 
  - SF Symbol: `play.fill`
  - Size: 20pt → `.system(size: 20, weight: .regular)`
  - Color: Dark green `#1a3c34` → `Color(red: 0.102, green: 0.235, blue: 0.204)`
- **Position:** Trailing edge, vertically centered
- **Leading Spacing:** 12pt from episode info

---

## SwiftUI Implementation Structure

```swift
struct ContinueListeningCard: View {
    // MARK: - Properties
    let episode: ContinueListeningEpisode
    let onTap: () -> Void
    let onPlayTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Artwork
                artworkView
                
                // Episode Info
                episodeInfoView
                
                // Play Button
                playButton
            }
            .padding(16)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Subviews
    
    private var artworkView: some View {
        AsyncImage(url: URL(string: episode.artworkURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .empty, .failure, @unknown default:
                placeholderArtwork
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "podcast.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.5))
            )
    }
    
    private var episodeInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Episode Title
            Text(episode.title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(2)
            
            // Podcast Name
            Text(episode.podcastName)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
            
            // Progress Bar
            ProgressView(value: episode.progress)
                .tint(Color(red: 0.0, green: 0.784, blue: 0.702))
                .frame(height: 4)
                .padding(.top, 4)
                .padding(.bottom, 6)
            
            // Metadata Row
            HStack(spacing: 8) {
                // Notes Indicator
                if episode.notesCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(episode.notesCount) notes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Time Remaining
                Text("\(episode.timeRemaining) left")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var playButton: some View {
        Button(action: onPlayTap) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.784, blue: 0.702))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(Color(red: 0.102, green: 0.235, blue: 0.204))
            }
        }
        .buttonStyle(.plain)
    }
}
```

---

## Data Model

```swift
struct ContinueListeningEpisode: Identifiable {
    let id: String
    let title: String
    let podcastName: String
    let artworkURL: String?
    let progress: Double         // 0.0 to 1.0 (e.g., 0.45 for 45%)
    let notesCount: Int         // Number of notes taken
    let timeRemaining: String   // Formatted string (e.g., "0:48", "1:23:45")
    let audioURL: String?
    
    // Optional: Additional metadata
    let duration: TimeInterval?
    let currentTime: TimeInterval?
}
```

---

## Usage Example

```swift
// In HomeView or parent view
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 12) {
        ForEach(continueListeningEpisodes) { episode in
            ContinueListeningCard(
                episode: episode,
                onTap: {
                    // Navigate to full player
                    selectedEpisode = episode
                    showPlayer = true
                },
                onPlayTap: {
                    // Start/resume playback
                    GlobalPlayerManager.shared.loadEpisode(episode)
                    GlobalPlayerManager.shared.play()
                }
            )
            .frame(width: 327) // Fixed width for horizontal scroll
        }
    }
    .padding(.horizontal, 24)
}
```

---

## Integration with Existing Code

### Replace Existing Implementation
**File:** `HomeView.swift`
**Section:** "Continue Playing Section" (lines 228-242)

Replace the current `ContinuePlayingCard` with this new implementation.

### Conversion from Existing Data
The existing `DownloadedEpisode` model needs mapping to `ContinueListeningEpisode`:

```swift
extension DownloadedEpisode {
    func toContinueListeningEpisode(notesCount: Int = 0) -> ContinueListeningEpisode {
        // Calculate time remaining
        let remaining = (duration?.toTimeInterval() ?? 0) * (1.0 - progress)
        let timeRemainingString = TimeInterval(remaining).formattedTimestamp()
        
        return ContinueListeningEpisode(
            id: id,
            title: title,
            podcastName: podcastName,
            artworkURL: artworkUrl,
            progress: progress,
            notesCount: notesCount,
            timeRemaining: timeRemainingString,
            audioURL: audioUrl,
            duration: duration?.toTimeInterval(),
            currentTime: nil
        )
    }
}
```

---

## Design Tokens to Use

Reference `EchoCastDesignTokens.swift` for consistency:

### Colors
- Card background: `Color(red: 0.2, green: 0.2, blue: 0.2)` (already correct, could be `.noteCardBackground`)
- Mint accent: `Color.mintAccent` or `Color(red: 0.0, green: 0.784, blue: 0.702)`
- Dark green: `Color(red: 0.102, green: 0.235, blue: 0.204)`
- Text colors:
  - Primary: `.white`
  - Secondary: `.white.opacity(0.85)`
  - Tertiary: `.white.opacity(0.7)`

### Typography
- Episode title: `.bodyRoundedMedium()` (17pt SF Pro Rounded Medium)
- Podcast name: `.system(size: 15, weight: .regular)`
- Metadata: `.caption2Medium()` (12pt SF Pro Medium)

### Spacing
- Card padding: `EchoSpacing.noteCardPadding` (16pt)
- Corner radius: 12pt (could add `EchoSpacing.cardCornerRadius = 12`)
- Element spacing: 8pt, 12pt (standard increments)

---

## Interactive States

### Hover (iOS 17+)
```swift
.hoverEffect(.lift)
```

### Pressed State
The `.buttonStyle(.plain)` prevents default button styling, maintaining custom appearance.

### Accessibility
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("\(episode.title) by \(episode.podcastName)")
.accessibilityHint("Double tap to open episode. \(episode.timeRemaining) remaining with \(episode.notesCount) notes.")
.accessibilityAddTraits(.isButton)
```

---

## Edge Cases

1. **Missing Artwork:** Show placeholder with podcast icon
2. **Long Episode Title:** Limit to 2 lines, truncate with ellipsis
3. **Long Podcast Name:** Limit to 1 line, truncate
4. **Zero Notes:** Hide notes indicator entirely (don't show "0 notes")
5. **Progress = 0:** Show full duration instead of "left" (e.g., "48:23")
6. **Progress = 1.0 (Complete):** Consider showing "Replay" or removing from "Continue listening"

---

## Testing Checklist

- [ ] Artwork loads from URL correctly
- [ ] Placeholder shows when artwork fails to load
- [ ] Episode title truncates at 2 lines
- [ ] Podcast name truncates at 1 line
- [ ] Progress bar displays correct percentage
- [ ] Progress bar uses mint accent color
- [ ] Notes indicator shows correct count
- [ ] Notes indicator hidden when count = 0
- [ ] Time remaining formats correctly (MM:SS or H:MM:SS)
- [ ] Play button tap triggers playback
- [ ] Card tap navigates to full player
- [ ] Card shadow renders correctly
- [ ] Spacing matches Figma exactly (use ruler/measure)
- [ ] Colors match Figma exactly (use color picker)
- [ ] Typography matches Figma exactly (compare side-by-side)

---

## Preview Code

```swift
#Preview("Continue Listening Card - With Notes") {
    ContinueListeningCard(
        episode: ContinueListeningEpisode(
            id: "1",
            title: "I Hate Mysteries",
            podcastName: "This American Life",
            artworkURL: "https://example.com/artwork.jpg",
            progress: 0.65,
            notesCount: 9,
            timeRemaining: "0:48",
            audioURL: "https://example.com/audio.mp3"
        ),
        onTap: { print("Card tapped") },
        onPlayTap: { print("Play tapped") }
    )
    .frame(width: 327)
    .padding()
    .background(Color(red: 0.149, green: 0.149, blue: 0.149))
}

#Preview("Continue Listening Card - No Notes") {
    ContinueListeningCard(
        episode: ContinueListeningEpisode(
            id: "2",
            title: "The Fall of Civilizations: 20. Persia - An Empire in Ashes",
            podcastName: "The Fall of Civilizations Podcast",
            artworkURL: nil,
            progress: 0.23,
            notesCount: 0,
            timeRemaining: "2:14:30",
            audioURL: nil
        ),
        onTap: { print("Card tapped") },
        onPlayTap: { print("Play tapped") }
    )
    .frame(width: 327)
    .padding()
    .background(Color(red: 0.149, green: 0.149, blue: 0.149))
}
```

---

## Figma Comparison Instructions

1. Take a screenshot of the implemented component in Xcode preview
2. Open Figma and overlay the screenshot at 50% opacity
3. Check alignment of:
   - Card corners and shadow
   - Artwork size and position
   - Text baselines and line heights
   - Progress bar width and height
   - Play button size and position
   - All spacing values
4. Use color picker to verify exact color values
5. Measure distances with Figma ruler tool

---

## Success Criteria

✅ The component is considered complete when:
1. All measurements match Figma within ±1pt
2. All colors match Figma exactly (use hex values)
3. Typography renders identically (font, weight, size, line height)
4. Shadows render correctly
5. Interactive states work (tap, hover if applicable)
6. Edge cases handled gracefully
7. Accessibility labels provided
8. Preview renders correctly with sample data
9. Component integrates with existing `HomeView.swift` without breaking changes
10. Side-by-side comparison with Figma shows < 5% visual difference

---

**End of Specification**
