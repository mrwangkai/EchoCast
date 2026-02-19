# Fix "Go Back" Button — Convert to Floating Overlay

**Branch:** `fix/go-back-button-overlay`  
**File:** `EpisodePlayerView.swift`  
**Issue:** Go Back button currently pushes content up/down when appearing. Should float as overlay in top-right of content area instead.

---

## Current Implementation (Lines 411-456)

The button is currently positioned **inside the timeline controls VStack**, causing layout shifts:

```swift
// WRONG: Inside layout flow
VStack {
    // ... timeline stuff ...
    
    if showGoBackButton {
        HStack { /* button code */ }  // <-- This pushes content
    }
}
```

---

## Target Design (Overcast-style)

**Reference:** See attached Overcast screenshot — "Jump Back" button floats in **top-right corner** of the content area as an overlay.

**Key requirements:**
1. Button floats **above** the content (album art / notes list / episode info)
2. Positioned in **top-right corner** with safe padding from edges
3. **Does not affect layout** — content doesn't shift when button appears/disappears
4. Still auto-dismisses after 8 seconds with countdown animation
5. Still seeks back to previous position on tap

---

## Implementation Steps

### Step 1: Remove Button from Timeline Section

**Find lines 411-456** (the current Go Back button code inside the timeline section).

**Delete the entire `if showGoBackButton { ... }` block** from its current location.

Do NOT delete the state variables (lines 67-71) or the drag gesture logic (lines 364-394) or the cleanup (lines 208-210). Only remove the UI rendering block.

---

### Step 2: Add Button as ZStack Overlay on Content Switcher

**Find the content switcher** (the part that shows different tabs based on `selectedSegment`). It will look something like:

```swift
// Content area that changes based on selected tab
switch selectedSegment {
case 0:
    listeningTabContent
case 1:
    episodeInfoTabContent
default:
    EmptyView()
}
```

**Wrap this entire content switcher in a ZStack** and add the Go Back button as an overlay:

```swift
ZStack(alignment: .topTrailing) {
    // Original content switcher
    switch selectedSegment {
    case 0:
        listeningTabContent
    case 1:
        episodeInfoTabContent
    default:
        EmptyView()
    }
    
    // Floating Go Back button overlay
    if showGoBackButton {
        goBackButtonOverlay
            .padding(.top, 16)      // Distance from top edge
            .padding(.trailing, 16)  // Distance from right edge
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .zIndex(100)  // Ensure it's above all content
    }
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

**Key changes:**
- `ZStack(alignment: .topTrailing)` — positions overlay in top-right
- `.padding(.top, 16)` and `.padding(.trailing, 16)` — safe margin from edges
- `.transition(.opacity.combined(with: .scale))` — smooth pop-in/out animation
- `.zIndex(100)` — ensures button is above scrolling content

---

### Step 3: Extract Go Back Button as Computed Property

Add this new computed property to `EpisodePlayerView` (place it near other view components):

```swift
// MARK: - Go Back Button Overlay

private var goBackButtonOverlay: some View {
    HStack(spacing: 8) {
        // Circular countdown indicator
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)
            
            Circle()
                .trim(from: 0, to: goBackCountdown / 8.0)
                .stroke(Color.mintAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: goBackCountdown)
        }
        
        Button {
            // Jump back to previous position
            player.seek(to: previousPlaybackPosition)
            
            // Hide button immediately
            withAnimation {
                showGoBackButton = false
            }
            goBackTimer?.invalidate()
            previousPlaybackPosition = 0
            
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .medium))
                Text("go back")
                    .font(.caption2Medium())
            }
            .foregroundColor(.mintAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)  // Add shadow for depth
}
```

**Key addition:** `.shadow()` modifier gives the floating button visual depth against any background.

---

### Step 4: Verify Safe Area Handling

If the button is cut off by the notch/status bar on iPhone, adjust the top padding:

```swift
if showGoBackButton {
    goBackButtonOverlay
        .padding(.top, 24)  // Increase if needed for safe area
        .padding(.trailing, 16)
        // ...
}
```

Alternatively, use `.safeAreaInset` if available in your deployment target.

---

## Visual Result

**Before:** Button appears inline with timeline → content jumps up/down  
**After:** Button floats in top-right corner → content stays put, button fades in/out

**Positioning:**
```
┌─────────────────────────────────┐
│                   [⏱️ go back]   │ ← Floating overlay, top-right
│                                  │
│   (Notes list / Artwork /        │ ← Content area (unchanged)
│    Episode info — depending      │
│    on selected tab)              │
│                                  │
│                                  │
└─────────────────────────────────┘
     [Timeline and controls]        ← Sticky bottom (unchanged)
```

---

## Testing Checklist

- [ ] Button appears in **top-right corner** when user scrubs timeline
- [ ] Button **does not push content** up/down when appearing
- [ ] Button floats **above** scrolling content (notes list in Listening tab)
- [ ] Countdown circle animates correctly (8 seconds)
- [ ] Tapping button seeks back to saved position
- [ ] Button auto-dismisses after 8 seconds
- [ ] Button fades in with scale transition (smooth pop-in)
- [ ] Button has shadow for visual depth
- [ ] Button respects safe area (not cut off by notch/status bar)
- [ ] Works correctly across all 3 tabs (Listening, Notes, Episode Info)
- [ ] Timer cleanup still happens on `.onDisappear`

---

## Code Changed

- **Added:** `goBackButtonOverlay` computed property
- **Modified:** Content switcher wrapped in `ZStack(alignment: .topTrailing)`
- **Removed:** Go Back button code from timeline section (lines 411-456)
- **Unchanged:** State variables, drag gesture logic, timer logic, cleanup

---

## Notes

**Why ZStack on content switcher, not on entire view?**  
Because the button should float **above content** but **below the segmented control** and **not overlap sticky player controls**. Placing it on the content switcher achieves this hierarchy:

1. Segmented control (top, fixed)
2. Content area with floating button overlay ← Button here
3. Player controls (bottom, sticky)

**Alternative positioning:** If you want the button to appear in a different corner (e.g., top-left), change `ZStack(alignment: .topTrailing)` to `.topLeading` and swap `.padding(.trailing, 16)` with `.padding(.leading, 16)`.
