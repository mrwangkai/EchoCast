# Player Sheet Structure

## Sheet Presentation Modifiers (EpisodePlayerView.swift, lines 189-193)

```swift
.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
.background(Color.echoBackground)
.presentationDetents([.fraction(0.82)])              // Sheet height: 82% of screen
.presentationDragIndicator(.visible)                 // Native drag bar at top
.ignoresSafeArea(edges: .bottom)
```

---

## Visual Layout (from Drag Bar to Footer)

```
┌─────────────────────────────────────────────────────────┐
│ 📱 Drag Bar (native, system)                            │ ← Native sheet drag indicator
├─────────────────────────────────────────────────────────┤
│                                                          │ │
│ 24px spacing (.padding(.top, 24))                       │ │
│                                                          │ │
│ ┌─────────────────────────────────────────────────────┐ │ │
│ │ [Listening] [Notes] [Episode Info]                    │ │ │ ← Segmented control
│ │ (height: 36)                                         │ │ │
│ └─────────────────────────────────────────────────────┘ │ │
│                                                          │ │
├─────────────────────────────────────────────────────────┤ │
│ │                                                         │ │
│ │ 16px top padding (.padding(.top, 16))                │ │
│ │                                                         │ │
│ │ ┌─────────────────────────────────────────────────┐ │ │
│ │ │                                                     │ │ │
│ │ │  SECTION 2: MID-SECTION (Content Area)           │ │ │
│ │ │  • Album art (Listening tab)                       │ │ │
│ │ │  • Notes list (Notes tab)                          │ │ │ │ ← Scrollable content
│ │ │  • Episode info (Episode Info tab)                 │ │ │ │
│ │ │                                                     │ │ │
│ │ │  ┌─────────────────────────────────────┐          │ │ │
│ │ │  │  [⏱️ go back] (floating overlay)  │          │ │ │ ← Go Back button
│ │ │  └─────────────────────────────────────┘          │ │ │    (appears when scrubbing)
│ │ │                                                     │ │ │
│ │ └─────────────────────────────────────────────────┘ │ │
│ │                                                         │ │
│ │ Spacer()                                                │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                          │
│ 24px spacing (.padding(.top, 24))                        │ │
│                                                          │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ SECTION 3: FOOTER (Player Controls)                   │ │
│ │                                                         │ │
│ │ ┌─────────────────────────────────────────────────┐ │ │
│ │ │ "Episode Title"                                   │ │ │
│ │ │ "Podcast Series Name"                             │ │ │
│ │ │ (spacing: 6px)                                     │ │ │
│ │ └─────────────────────────────────────────────────┘ │ │
│ │                                                         │ │
│ │ ┌─────────────────────────────────────────────────┐ │ │
│ │ │ Timeline with note markers                        │ │ │
│ │ │ (note markers: -28px above timeline)               │ │ │
│ │ └─────────────────────────────────────────────────┘ │ │
│ │                                                         │ │
│ │ ┌──────┐ ┌─────────┐ ┌──────────────┐ ┌─────────┐  │ │
│ │ │ ⏪15s │ │ ▶️ Play  │ │ ⏩30s        │ │ [+ Note] │  │ │
│ │ └──────┘ └─────────┘ └──────────────┘ └─────────┘  │ │
│ │                                                         │ │
│ │ ┌─────────────────────────────────────────────────┐ │ │
│ │ │ [icon] Add note at current time                  │ │ │ ← Add Note button
│ │ │ (horizontal padding: 24px, bottom padding: 32px)│ │ │
│ │ └─────────────────────────────────────────────────┘ │ │
│ │                                                         │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                          │
└───────────────────────────────────────────────────────────┘
```

---

## Code Structure (lines 100-193)

```swift
var body: some View {
    VStack(spacing: 0) {
        // --- SECTION 1: HEADER (FIXED HEIGHT: ~68px) ---
        VStack(spacing: 0) {
            segmentedControlSection
                .frame(height: 36)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 24)                           // ← 24px from drag bar

        // --- SECTION 2: MID-SECTION (FIXED HEIGHT: 377px) ---
        ZStack(alignment: .top) {
            Group {
                switch selectedSegment {
                case 0:
                    // Listening: Static Art (Not scrollable)
                    ListeningSegmentView(...)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 16)           // ← 16px top padding

                case 1:
                    // Notes: Scrollable List
                    ScrollView {
                        NotesSegmentView(...)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollIndicators(.hidden)
                    .padding(.top, 16)

                case 2:
                    // Info: Scrollable Text
                    ScrollView {
                        InfoSegmentView(...)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollIndicators(.hidden)
                    .padding(.top, 16)

                default:
                    EmptyView()
                }
            }
            .frame(height: 377)

            // Floating Go Back button overlay (CENTERED)
            if showGoBackButton {
                goBackButtonOverlay
                    .padding(.top, 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        Spacer(minLength: 0)                         // ← Pushes footer to bottom

        // --- SECTION 3: FOOTER (FIXED HEIGHT: ~290px) ---
        VStack(spacing: 16) {
            // Metadata (Always visible, 2 lines max)
            episodeMetadataView

            // Scrubber
            timeProgressWithMarkers

            // Playback controls
            playbackControlButtons

            // Add Note CTA (Always visible with player controls)
            addNoteButton
                .sensoryFeedback(.impact, trigger: showingNoteCaptureSheet)
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
        .padding(.top, 24)                         // ← 24px above footer
        .background(Color.echoBackground)
        .footerPadding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(Color.echoBackground)
    .presentationDetents([.fraction(0.82)])          // ← 82% sheet height
    .presentationDragIndicator(.visible)             // ← Drag bar
    .ignoresSafeArea(edges: .bottom)
}
```

---

## Key Spacing Values

| Element | Spacing |
|---------|---------|
| Drag bar to Segmented Control | 24px (`.padding(.top, 24)`) |
| Segmented Control to Content Area | 0px (VStack spacing: 0) |
| Content Area top padding | 16px (`.padding(.top, 16)`) |
| Content Area to Episode Metadata | 24px (footer `.padding(.top, 24)`) |
| Episode Metadata to Timeline | 16px (VStack spacing: 16) |
| Timeline to Controls | 16px (VStack spacing: 16) |
| Controls to Add Note button | 16px (VStack spacing: 16) |
| Note markers above timeline | -28px (`.offset(y: -28)`) |
| Sheet height | 82% of screen (`fraction(0.82)`) |

---

## Section Breakdown

### SECTION 1: HEADER
- **Height**: 60px (36px segmented control + 24px top padding)
- **Components**: Segmented control (3 tabs)

### SECTION 2: MID-SECTION
- **Height**: 393px (16px top + 377px content)
- **Components**: Tab content + optional Go Back button overlay
- **Fixed height**: Constrained by `.frame(height: 377)`

### SECTION 3: FOOTER
- **Height**: Variable (content-driven)
- **Components**: Episode metadata, timeline, playback controls, Add Note button
- **Spacing**: 16px between each element
