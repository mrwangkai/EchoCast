# Home Note Card Component Specification

**Figma Reference:** https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1696-3954&t=SU77v8sJhvfLAWBE-4

**Component Purpose:** Display a podcast note with episode metadata in a card format for the "Your notes" section on the Home screen.

---

## Visual Reference

The card displays:
- Top: Episode artwork + episode title + podcast name
- Middle: Note content text (expandable)
- Bottom: Timestamp + tags

---

## Component Structure

```
HomeNoteCard (VStack)
├── Header (HStack)
│   ├── Episode Artwork (AsyncImage - 48x48pt)
│   └── Episode Info (VStack)
│       ├── Episode Title (Text)
│       └── Podcast Name (Text)
├── Note Content (Text - expandable)
└── Footer (HStack)
    ├── Timestamp (Text)
    ├── Spacer
    └── Tags (FlowLayout/HStack)
        ├── Tag 1 (Text with background)
        ├── Tag 2 (Text with background)
        └── +N indicator (if more tags)
```

---

## Measurements & Layout

### Card Container
- **Background Color:** `#333333` (rgb 51, 51, 51) → `Color(red: 0.2, green: 0.2, blue: 0.2)`
- **Corner Radius:** 8pt
- **Padding (internal):** 16pt all sides
- **Shadow:** 
  - Primary: `Color.black.opacity(0.3)`, radius: 3, x: 0, y: 1
  - Secondary: `Color.black.opacity(0.15)`, radius: 2, x: 0, y: 1
- **Spacing between sections:** 16pt

### Header Section (HStack)
- **Alignment:** `.top`
- **Spacing:** 16pt between artwork and text

#### Episode Artwork
- **Size:** 48x48pt (square)
- **Corner Radius:** 8pt
- **Placeholder:** `podcast.fill` icon if artwork unavailable
- **Background (placeholder):** `Color.gray.opacity(0.3)`

#### Episode Info (VStack)
- **Alignment:** `.leading`
- **Spacing:** 4pt between title and podcast name
- **Max Width:** Flexible (fills available space)

##### Episode Title (Text)
- **Font:** SF Pro Rounded Medium, 15pt → `.system(size: 15, weight: .medium, design: .rounded)`
- **Color:** White 85% → `Color.white.opacity(0.85)`
- **Line Limit:** 2 lines
- **Truncation:** Tail

##### Podcast Name (Text)
- **Font:** SF Pro Regular, 13pt → `.system(size: 13, weight: .regular)`
- **Color:** White 65% → `Color.white.opacity(0.65)`
- **Line Limit:** 1 line
- **Truncation:** Tail

### Note Content Section (Text)
- **Font:** SF Pro Rounded Medium, 17pt → `.system(size: 17, weight: .medium, design: .rounded)`
- **Color:** White 95% → `Color(red: 1, green: 1, blue: 1, opacity: 0.95)`
- **Line Limit:** 3 lines when collapsed, unlimited when expanded
- **Line Spacing:** Default (approximately 4-6pt between lines)
- **Top Margin:** 16pt from header
- **Bottom Margin:** 16pt to footer
- **Interaction:** Tap to expand/collapse

### Footer Section (HStack)
- **Alignment:** `.center`
- **Spacing:** Space between timestamp and tags (Spacer())

#### Timestamp (Text)
- **Font:** SF Pro Medium, 12pt → `.system(size: 12, weight: .medium)`
- **Color:** White 70% → `Color.white.opacity(0.7)`
- **Format:** "MM:SS" or "H:MM:SS" (e.g., "12:09", "1:23:45")
- **Position:** Leading edge

#### Tags Section (FlowLayout or HStack)
- **Spacing:** 4pt between tags
- **Max Visible Tags:** 3 (show "+N" for remaining)
- **Position:** Trailing edge

##### Individual Tag
- **Font:** SF Pro Medium, 12pt → `.system(size: 12, weight: .medium)`
- **Text Color:** White 70% → `Color.white.opacity(0.7)`
- **Background Color:** `Color(red: 0.141, green: 0.141, blue: 0.141, opacity: 0.65)` → Semi-transparent dark
- **Padding:** 
  - Horizontal: 6pt
  - Vertical: 4pt
- **Corner Radius:** 8pt
- **Format:** Plain text (e.g., "question", "thought provoking")

##### Overflow Indicator (+N)
- **Font:** Same as tag (SF Pro Medium, 12pt)
- **Text Color:** White 70% → `Color.white.opacity(0.7)`
- **Background:** `Color.clear` (no background)
- **Format:** "+N" (e.g., "+2" if 2 more tags exist)

---

## SwiftUI Implementation Structure

```swift
struct HomeNoteCard: View {
    // MARK: - Properties
    let note: NoteEntity
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with artwork and episode info
            headerView
            
            // Note content (expandable)
            noteContentView
            
            // Footer with timestamp and tags
            footerView
        }
        .padding(16)
        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack(alignment: .top, spacing: 16) {
            // Episode artwork
            artworkView
            
            // Episode info
            VStack(alignment: .leading, spacing: 4) {
                if let episodeTitle = note.episodeTitle {
                    Text(episodeTitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
                
                if let showTitle = note.showTitle {
                    Text(showTitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var artworkView: some View {
        // TODO: Fetch actual artwork from episode/podcast data
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 48, height: 48)
            .overlay(
                Image(systemName: "podcast.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.5))
            )
    }
    
    private var noteContentView: some View {
        Group {
            if let noteText = note.noteText, !noteText.isEmpty {
                Text(noteText)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 1, green: 1, blue: 1, opacity: 0.95))
                    .lineLimit(isExpanded ? nil : 3)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }
            }
        }
    }
    
    private var footerView: some View {
        HStack(alignment: .center, spacing: 8) {
            // Timestamp
            if let timestamp = note.timestamp {
                Text(timestamp)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Tags
            if !note.tagsArray.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(Array(note.tagsArray.prefix(3).enumerated()), id: \.offset) { _, tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.141, green: 0.141, blue: 0.141, opacity: 0.65))
                            .cornerRadius(8)
                    }
                    
                    if note.tagsArray.count > 3 {
                        Text("+\(note.tagsArray.count - 3)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}
```

---

## Data Model Integration

### Using Existing NoteEntity
The component uses the existing `NoteEntity` from Core Data:
- `episodeTitle` → Episode name in header
- `showTitle` → Podcast name in header
- `noteText` → Main note content
- `timestamp` → Timestamp display (e.g., "12:09")
- `tagsArray` → Tags in footer (uses existing extension)

### Artwork Fetching Strategy
Since `NoteEntity` doesn't store artwork URLs, implement one of these approaches:

**Option 1: Look up by episode title**
```swift
func getArtworkURL(for note: NoteEntity) -> String? {
    // Query PlaybackHistoryManager or downloaded episodes
    // Match by episodeTitle
    // Return artworkURL if found
}
```

**Option 2: Store artwork URL in NoteEntity**
Add `artworkURL` field to NoteEntity schema (requires Core Data migration)

**Option 3: Use placeholder always**
Simplest - just show podcast.fill icon (can improve later)

**Recommended for now:** Option 3 (placeholder), upgrade to Option 1 in future iteration

---

## Usage Example

```swift
// In HomeView.swift "Your notes" section
VStack(alignment: .leading, spacing: 16) {
    // Section header
    HStack {
        Image(systemName: "doc.text.fill")
            .font(.system(size: 20))
            .foregroundColor(.white.opacity(0.7))
        
        Text("Your notes")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.white)
        
        Spacer()
        
        Button("View all") {
            // Navigate to LibraryView
        }
    }
    
    // Notes list
    VStack(spacing: 16) {
        ForEach(notes.prefix(10)) { note in
            HomeNoteCard(note: note)
        }
    }
}
```

---

## Integration with Existing Code

### Replace Current Implementation
**File:** `HomeView.swift`
**Section:** Lines 313-378 (current HomeNoteCardView)

Replace the existing `HomeNoteCardView` with this new implementation that matches Figma exactly.

### Keep These Features from Current Code
- ✅ Expand/collapse on tap (isExpanded state)
- ✅ Animation on expand/collapse
- ✅ Tag array support (note.tagsArray)
- ✅ Core Data integration

### Update These to Match Figma
- 📐 Spacing values (16pt between sections)
- 🎨 Colors (exact opacity values)
- 📝 Typography (exact font sizes and weights)
- 🖼️ Artwork size (48x48pt, not current size)
- 🏷️ Tag styling (background color and padding)

---

## Design Tokens to Use

Reference `EchoCastDesignTokens.swift` for consistency:

### Colors
- Card background: `Color(red: 0.2, green: 0.2, blue: 0.2)` or `.noteCardBackground`
- Text primary (note content): `Color(red: 1, green: 1, blue: 1, opacity: 0.95)`
- Text secondary (episode title): `.white.opacity(0.85)`
- Text tertiary (podcast name, timestamp, tags): `.white.opacity(0.7)` or `.white.opacity(0.65)`
- Tag background: `Color(red: 0.141, green: 0.141, blue: 0.141, opacity: 0.65)`

### Typography
- Episode title: `.system(size: 15, weight: .medium, design: .rounded)` or `.subheadlineRounded()`
- Podcast name: `.system(size: 13, weight: .regular)` or `.captionRounded()`
- Note content: `.system(size: 17, weight: .medium, design: .rounded)` or `.bodyRoundedMedium()`
- Timestamp/Tags: `.system(size: 12, weight: .medium)` or `.caption2Medium()`

### Spacing
- Card padding: `EchoSpacing.noteCardPadding` (16pt)
- Section spacing: 16pt
- Tag spacing: 4pt
- Corner radius: 8pt

---

## Interactive States

### Expand/Collapse Animation
```swift
.onTapGesture {
    withAnimation(.easeInOut(duration: 0.2)) {
        isExpanded.toggle()
    }
}
```

### Accessibility
```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("\(note.episodeTitle ?? "Unknown episode"). \(note.noteText ?? "No content")")
.accessibilityHint("Double tap to expand or collapse note. Taken at \(note.timestamp ?? "unknown time")")
.accessibilityAddTraits(.isButton)
```

---

## Edge Cases

1. **Missing Episode Title:** Show "Unknown Episode" or hide title
2. **Missing Podcast Name:** Show "Unknown Podcast" or hide podcast name
3. **Empty Note Text:** Should not render card at all (filter in parent)
4. **No Timestamp:** Hide timestamp entirely
5. **No Tags:** Hide tags section entirely
6. **Long Note Text:** Truncate at 3 lines when collapsed, show all when expanded
7. **Many Tags (>3):** Show first 3 + "+N" indicator
8. **Very Long Tag Names:** May need truncation or wrapping

---

## Testing Checklist

- [ ] Artwork displays at 48x48pt with 8pt corner radius
- [ ] Placeholder shows when artwork unavailable
- [ ] Episode title truncates at 2 lines
- [ ] Podcast name truncates at 1 line
- [ ] Note content shows 3 lines when collapsed
- [ ] Note content expands to full text on tap
- [ ] Expand/collapse animates smoothly
- [ ] Timestamp displays correctly
- [ ] Tags show maximum 3 visible
- [ ] Overflow indicator shows "+N" when >3 tags
- [ ] Tag styling matches (background, padding, corner radius)
- [ ] Card shadow renders correctly
- [ ] All spacing matches Figma (16pt internal, 16pt between sections)
- [ ] All colors match Figma exactly
- [ ] Typography matches Figma exactly

---

## Preview Code

```swift
#Preview("Home Note Card - Standard") {
    let context = PersistenceController.preview.container.viewContext
    let note = NoteEntity(context: context)
    note.id = UUID()
    note.episodeTitle = "I Hate Mysteries"
    note.showTitle = "This American Life"
    note.timestamp = "12:09"
    note.noteText = "A combination between Yo-yo Ma and West Virginia is unexpected."
    note.tags = "question,thought provoking"
    note.createdAt = Date()
    note.isPriority = false
    
    return HomeNoteCard(note: note)
        .frame(width: 360)
        .padding()
        .background(Color(red: 0.149, green: 0.149, blue: 0.149))
}

#Preview("Home Note Card - Long Content") {
    let context = PersistenceController.preview.container.viewContext
    let note = NoteEntity(context: context)
    note.id = UUID()
    note.episodeTitle = "The Fall of Civilizations Podcast"
    note.showTitle = "Dan Carlin's Hardcore History"
    note.timestamp = "1:23:45"
    note.noteText = "This is a much longer note that spans multiple lines and should be truncated at 3 lines when collapsed. When tapped, it should expand to show the full content with a smooth animation. This allows users to see a preview while keeping the card compact."
    note.tags = "history,important,fascinating,review later,share"
    note.createdAt = Date()
    note.isPriority = true
    
    return HomeNoteCard(note: note)
        .frame(width: 360)
        .padding()
        .background(Color(red: 0.149, green: 0.149, blue: 0.149))
}

#Preview("Home Note Card - Minimal") {
    let context = PersistenceController.preview.container.viewContext
    let note = NoteEntity(context: context)
    note.id = UUID()
    note.episodeTitle = "Quick Episode"
    note.showTitle = "Short Podcast"
    note.timestamp = "0:45"
    note.noteText = "Brief note."
    note.tags = ""
    note.createdAt = Date()
    note.isPriority = false
    
    return HomeNoteCard(note: note)
        .frame(width: 360)
        .padding()
        .background(Color(red: 0.149, green: 0.149, blue: 0.149))
}
```

---

## Figma Comparison Instructions

1. Take a screenshot of the implemented component in Xcode preview
2. Open Figma and place screenshot side-by-side with design
3. Check alignment of:
   - Card padding (16pt all sides)
   - Artwork size (48x48pt) and position
   - Text line heights and spacing
   - Tag backgrounds and padding
   - Section spacing (16pt between header/content/footer)
4. Use color picker to verify exact color values
5. Measure distances with Figma ruler tool
6. Compare collapsed vs expanded states

---

## Success Criteria

✅ The component is considered complete when:
1. All measurements match Figma within ±1pt
2. All colors match Figma exactly (check opacity values)
3. Typography renders identically (font, weight, size, line height)
4. Shadows render correctly
5. Expand/collapse animation works smoothly
6. Edge cases handled gracefully
7. Accessibility labels provided
8. Preview renders correctly with sample data
9. Component replaces existing HomeNoteCardView seamlessly
10. Side-by-side comparison with Figma shows < 5% visual difference

---

**End of Specification**
