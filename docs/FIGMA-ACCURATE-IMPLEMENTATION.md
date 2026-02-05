# EchoCast Figma-Accurate Implementation Guide

## Figma Design References

1. **Home Empty State**: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1416-7172
2. **Home With Content**: https://www.figma.com/design/BX4rcdUUTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1696-3836
3. **Player - Listening Tab**: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-4405
4. **Player - Notes Tab**: https://www.figma.com/design/BX4rcdUUTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-5413
5. **Player - Episode Info Tab**: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-5414

---

## IMPLEMENTATION TASKS

Use Figma MCP tools to extract exact specifications before implementing each component.

---

## TASK 1: Home Screen - Empty State

### Figma URL
https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1416-7172

### Implementation Steps

#### Step 1: Extract Figma Specs
```
Use Figma MCP tools:
1. get_design_context for node 1416-7172
2. get_metadata for exact measurements
3. get_screenshot for visual reference

Document:
- Screen title text and font
- Icon size and position
- Empty state message text
- Button styling (if any)
- Spacing between elements
- Background color
- Status bar height
- Top icon buttons (Find + Settings)
```

#### Step 2: Identify Key Elements
- [ ] Navigation bar with title "Home" or "EchoCast"
- [ ] Top-right icon buttons (Find + Settings)
- [ ] Empty state icon/illustration
- [ ] Empty state heading text
- [ ] Empty state body text
- [ ] Call-to-action button (if exists)
- [ ] Tab bar at bottom (Home + Library)

#### Step 3: Create Component
**File**: `EchoNotes/Views/HomeView.swift`

```swift
// Use exact Figma specifications:
// - Navigation bar: Extract from design
// - Icon buttons: SF Symbols with exact size from Figma
// - Empty state: Center-aligned with exact spacing
// - Typography: Match Figma text styles exactly
// - Colors: Use design tokens or extract from Figma
```

#### Step 4: Verification Checklist
- [ ] Title matches Figma (text + font + size + color)
- [ ] Icon buttons in correct positions
- [ ] Icon sizes match Figma exactly
- [ ] Empty state vertically centered
- [ ] Text content matches exactly
- [ ] Spacing between elements matches Figma
- [ ] Tab bar visible at bottom

---

## TASK 2: Home Screen - With Content

### Figma URL
https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1696-3836

### Implementation Steps

#### Step 1: Extract Figma Specs
```
Use Figma MCP tools:
1. get_design_context for node 1696-3836
2. Identify all sections:
   - Navigation bar
   - "Continue Listening" section
   - "Recent Notes" section
   - Individual card components
3. Extract card specifications:
   - ContinueListeningCard dimensions
   - Note card dimensions
   - Spacing between cards
   - Section headers styling
```

#### Step 2: Identify Sections
- [ ] Navigation bar (same as empty state)
- [ ] "Continue Listening" header + card(s)
- [ ] "Recent Notes" header + cards
- [ ] Horizontal scroll for Continue Listening?
- [ ] Vertical scroll for Recent Notes?
- [ ] Card shadows and corner radius

#### Step 3: Extract Card Specs

**ContinueListeningCard:**
```
Use Figma MCP for node inside 1696-3836:
- Card dimensions (width x height)
- Album artwork size + corner radius
- Episode title font + size + color
- Podcast name font + size + color
- Progress bar styling
- Time remaining position
- Play button overlay
- Note markers on progress bar (if visible)
- Card background color
- Shadow specifications
```

**Recent Note Card:**
```
Use Figma MCP:
- Card dimensions
- Podcast name styling
- Note preview text (lines + truncation)
- Timestamp badge styling
- Tags display (if visible)
- Card padding
- Background color
- Shadow
```

#### Step 4: Implementation Priority
1. Update `HomeView.swift` with content sections
2. Create/refine `ContinueListeningCard.swift` (Figma-exact)
3. Create note card component (if separate file)
4. Wire up data to display real content

#### Step 5: Verification Checklist
- [ ] Section headers match Figma (text + font + spacing)
- [ ] ContinueListeningCard dimensions exact
- [ ] Album artwork size + corner radius correct
- [ ] Progress bar matches design
- [ ] Note cards match design
- [ ] Spacing between sections matches Figma
- [ ] Horizontal padding matches Figma
- [ ] Scroll behavior matches design

---

## TASK 3: Episode Player - Listening Tab

### Figma URL
https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-4405

### Implementation Steps

#### Step 1: Extract Complete Specs
```
Use Figma MCP tools for node 1878-4405:

1. Sheet Header:
   - Minimize button (chevron down) - size, position
   - Tab segmented control - position, styling

2. Album Artwork:
   - Exact dimensions (likely 335x335 or similar)
   - Corner radius
   - Shadow specifications
   - Vertical position from top

3. Episode Metadata:
   - Podcast name: font, size, color, spacing
   - Episode title: font, size, color, max lines
   - Spacing between name and title

4. Progress Slider:
   - Track height
   - Thumb size
   - Active color (mint #00c8b3)
   - Inactive color
   - Note markers: size (8pt circles?), color, positions
   - Spacing from title

5. Time Labels:
   - Current time (left): font, size, color
   - Remaining time (right): font, size, color
   - Format: "19:34" / "-24:58"
   - Spacing from slider

6. Playback Controls:
   - Rewind 15s button: icon, size
   - Play/Pause button: icon, size (larger)
   - Forward 30s button: icon, size
   - Button spacing
   - Vertical position

7. "Add note" Button:
   - Width (full width with padding?)
   - Height (56pt?)
   - Background color (dark green #1a3c34?)
   - Text: font, size, color
   - Icon: position, size
   - Corner radius
   - Bottom spacing (safe area)
```

#### Step 2: Critical Measurements
Extract these exact values:
- Album artwork: ??? x ??? pt
- Artwork corner radius: ??? pt
- Spacing between elements: ??? pt each
- Progress bar track height: ??? pt
- Progress bar thumb: ??? pt diameter
- Note marker circles: ??? pt diameter
- Play/Pause button: ??? pt diameter
- Skip buttons: ??? pt diameter
- Add note button height: ??? pt

#### Step 3: Implementation
**File**: `EchoNotes/Views/Player/EpisodePlayerView.swift`

Focus on Listening tab:
```swift
// Listening Tab Content
VStack(spacing: 0) {
    // Album artwork (exact size from Figma)
    
    // Vertical spacer (exact from Figma)
    
    // Episode metadata (exact fonts)
    
    // Vertical spacer
    
    // Progress slider with note markers
    
    // Time labels
    
    // Vertical spacer
    
    // Playback controls (exact sizes)
    
    // Spacer (push to bottom)
    
    // Add note button (exact styling)
}
.padding(.horizontal, EchoSpacing.screenPadding)
```

#### Step 4: Note Markers on Progress Bar
```swift
// Overlay note markers at exact timestamp positions
ZStack(alignment: .leading) {
    // Progress bar
    Slider(value: $currentTime, in: 0...duration)
    
    // Note markers
    GeometryReader { geo in
        ForEach(notesForEpisode) { note in
            Circle()
                .fill(Color.mintAccent)
                .frame(width: 8, height: 8)  // Verify size in Figma
                .position(
                    x: geo.size.width * (note.timestamp / duration),
                    y: geo.size.height / 2
                )
        }
    }
}
```

#### Step 5: Verification Checklist
- [ ] Album artwork exact size from Figma
- [ ] All spacing matches exactly
- [ ] Progress bar track height correct
- [ ] Note markers at 8pt diameter (verify)
- [ ] Note markers positioned correctly
- [ ] Play/Pause button larger than skip buttons
- [ ] Button sizes match Figma
- [ ] "Add note" button full width with padding
- [ ] Button heights exact
- [ ] Typography matches exactly
- [ ] Colors match design tokens

---

## TASK 4: Episode Player - Notes Tab

### Figma URL
https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-5413

### Implementation Steps

#### Step 1: Extract Specs
```
Use Figma MCP for node 1878-5413:

1. Tab content area:
   - Background color
   - Padding

2. Empty state (if no notes):
   - Icon/illustration
   - Message text
   - Styling

3. Notes list (if notes exist):
   - Note card dimensions
   - Card padding
   - Card background
   - Card corner radius
   - Spacing between cards

4. Individual note card:
   - Timestamp badge: size, color, position
   - Note content: font, size, lines, color
   - Tags: styling, spacing
   - Card tap area
   - Dividers between cards?

5. Scroll behavior:
   - Can scroll vertically?
   - List or ScrollView?
```

#### Step 2: Note Card Component
```swift
struct NoteCardInPlayer: View {
    let note: NoteEntity
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timestamp badge (exact from Figma)
            HStack {
                Image(systemName: "clock.fill")
                Text(note.timestamp ?? "")
            }
            .padding(...)  // Extract from Figma
            .background(Color.mintAccent.opacity(0.2))
            .cornerRadius(...)  // Extract from Figma
            
            // Note content (exact styling)
            Text(note.noteText ?? "")
                .font(...)  // Extract from Figma
                .lineLimit(...)  // Extract from Figma
            
            // Tags (if visible in design)
            if !note.tagsArray.isEmpty {
                // Tag chips
            }
        }
        .padding(...)  // Card padding from Figma
        .background(Color.noteCardBackground)
        .cornerRadius(...)  // From Figma
        .onTapGesture(perform: onTap)
    }
}
```

#### Step 3: Verification Checklist
- [ ] Empty state matches Figma (if shown)
- [ ] Note cards match exact dimensions
- [ ] Timestamp badge styling correct
- [ ] Note text truncation matches design
- [ ] Tags display correctly (if in design)
- [ ] Spacing between cards exact
- [ ] Card background color correct
- [ ] Tap to seek functionality works
- [ ] Scrolling smooth

---

## TASK 5: Episode Player - Episode Info Tab

### Figma URL
https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects?node-id=1878-5414

### Implementation Steps

#### Step 1: Extract Specs
```
Use Figma MCP for node 1878-5414:

1. Content layout:
   - ScrollView vertical
   - Padding (horizontal + vertical)

2. Episode metadata section:
   - Duration label + value
   - Release date label + value
   - File size label + value (if downloaded)
   - Label styling
   - Value styling
   - Spacing between rows

3. Description section:
   - Section header "Episode Description"
   - Description text styling
   - Line height
   - HTML stripping requirement

4. Podcast description section:
   - Section header "About This Podcast"
   - Podcast description text
   - Same styling as episode description?

5. Download section (if not downloaded):
   - Download button styling
   - Progress indicator when downloading
   - "Downloaded" state styling
```

#### Step 2: HTML Stripping Implementation
```swift
extension String {
    func strippingHTML() -> String {
        // Remove HTML tags
        let stripped = self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        
        // Decode HTML entities
        let decoded = stripped
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
        
        return decoded.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

#### Step 3: Implementation
```swift
// Episode Info Tab Content
ScrollView {
    VStack(alignment: .leading, spacing: 24) {
        // Episode metadata
        VStack(alignment: .leading, spacing: 12) {
            metadataRow(label: "Duration", value: episode.duration ?? "Unknown")
            metadataRow(label: "Released", value: formattedDate(episode.pubDate))
            if isDownloaded {
                metadataRow(label: "File Size", value: fileSize)
            }
        }
        
        Divider()
        
        // Episode description
        VStack(alignment: .leading, spacing: 8) {
            Text("Episode Description")
                .font(...)  // From Figma
            
            Text(episode.description?.strippingHTML() ?? "No description")
                .font(...)  // From Figma
                .lineSpacing(...)  // From Figma
        }
        
        Divider()
        
        // Podcast description
        VStack(alignment: .leading, spacing: 8) {
            Text("About This Podcast")
                .font(...)  // From Figma
            
            Text(podcast.podcastDescription?.strippingHTML() ?? "")
                .font(...)  // From Figma
        }
        
        // Download section (if applicable)
        if !isDownloaded {
            downloadButton
        }
    }
    .padding(EchoSpacing.screenPadding)
}
```

#### Step 4: Verification Checklist
- [ ] Metadata labels match Figma styling
- [ ] Description text styling correct
- [ ] Line spacing matches design
- [ ] HTML tags completely removed
- [ ] HTML entities decoded correctly
- [ ] Section headers match Figma
- [ ] Dividers positioned correctly
- [ ] Scrolling smooth
- [ ] Download button matches design (if shown)

---

## TASK 6: Player Controls - Sticky Bottom Bar

### Critical Requirement
**Player controls MUST remain visible across ALL 3 tabs** (not inside TabView content).

### Layout Structure
```swift
struct EpisodePlayerView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Zone 1: Segmented control (fixed top)
            segmentedControl
            
            // Zone 2: Content area (scrollable, changes per tab)
            TabView(selection: $selectedTab) {
                listeningTabContent.tag(0)
                notesTabContent.tag(1)
                episodeInfoTabContent.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Zone 3: Player controls (fixed bottom) - ALWAYS VISIBLE
            playerControlsBar
                .background(Color.echoBackground)
        }
    }
}
```

### Player Controls Bar Specs
```
Extract from Figma (all 3 tabs should show same controls):
- Progress bar with note markers
- Time labels (current / remaining)
- Playback buttons
- Background color
- Height
- Shadow (if any)
- Safe area bottom padding
```

---

## COMPREHENSIVE IMPLEMENTATION CHECKLIST

### Pre-Implementation
- [ ] Run Figma MCP tools on all 5 node IDs
- [ ] Extract all measurements and save to reference doc
- [ ] Document all colors used
- [ ] Document all typography specs
- [ ] Screenshot each screen for comparison

### During Implementation
- [ ] Use exact measurements from Figma
- [ ] Match colors to design tokens
- [ ] Match fonts to design token extensions
- [ ] Test on actual device (not just simulator)
- [ ] Compare side-by-side with Figma screenshots

### Post-Implementation
- [ ] Visual comparison test (Figma vs App)
- [ ] Measure elements with rulers
- [ ] Verify colors match exactly
- [ ] Verify fonts and sizes match exactly
- [ ] Test all interactions
- [ ] Test on multiple screen sizes
- [ ] Document any intentional deviations

---

## FIGMA MCP WORKFLOW

### For Each Screen:

```bash
# 1. Get design context
figma get_design_context --node-id [NODE_ID]

# 2. Get exact metadata
figma get_metadata --node-id [NODE_ID]

# 3. Get screenshot for visual reference
figma get_screenshot --node-id [NODE_ID]

# 4. Document findings
# Create measurement reference doc with:
# - Component dimensions
# - Spacing values
# - Font specifications
# - Color values
# - Shadow specs
# - Corner radius values
```

### Node IDs to Process:
1. `1416-7172` - Home Empty
2. `1696-3836` - Home Content
3. `1878-4405` - Player Listening
4. `1878-5413` - Player Notes
5. `1878-5414` - Player Episode Info

---

## SUCCESS CRITERIA

### Visual Accuracy
- ✅ 95%+ match to Figma designs
- ✅ All measurements within 2pt tolerance
- ✅ Colors exact match (use design tokens)
- ✅ Fonts exact match (size + weight)
- ✅ Spacing exact match

### Functional Accuracy
- ✅ Player controls sticky across tabs
- ✅ Note markers positioned correctly
- ✅ Tapping notes seeks correctly
- ✅ HTML stripped from descriptions
- ✅ All interactions smooth
- ✅ Scrolling performant

### Code Quality
- ✅ Uses design tokens throughout
- ✅ No hardcoded values
- ✅ Clean component structure
- ✅ Reusable components
- ✅ Well-documented code

---

## CLAUDE CODE IMPLEMENTATION PROMPT

```
TASK: Implement Figma-Accurate EchoCast Components

CRITICAL: Use Figma MCP tools to extract exact specifications before coding.

PHASE 1: Figma Analysis
For each of these 5 screens, use Figma MCP tools:

1. Home Empty (node 1416-7172)
2. Home Content (node 1696-3836)
3. Player Listening (node 1878-4405)
4. Player Notes (node 1878-5413)
5. Player Episode Info (node 1878-5414)

Extract and document:
- All component dimensions
- All spacing values
- All font specifications
- All color values
- Shadow specifications
- Corner radius values

Save findings to: docs/figma-measurements.md

PHASE 2: Implementation
Using exact measurements from Phase 1:

1. Update HomeView.swift
   - Empty state (exact from Figma)
   - Content state (exact from Figma)
   - Navigation with icon buttons

2. Create/update ContinueListeningCard.swift
   - Exact dimensions from Figma
   - Progress bar with note markers
   - All styling matches exactly

3. Update EpisodePlayerView.swift
   - 3 tabs (exact layouts from Figma)
   - Sticky player controls
   - Note markers on progress bar
   - HTML stripping for descriptions

PHASE 3: Verification
- Compare screenshots side-by-side
- Measure elements to verify accuracy
- Test all interactions
- Document any deviations

REQUIREMENTS:
- Use EchoCastDesignTokens for all styling
- No hardcoded values
- 95%+ visual match to Figma
- Player controls ALWAYS sticky
- Commit after each component

Figma file: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects
```

---

**END OF FIGMA-ACCURATE IMPLEMENTATION GUIDE**
