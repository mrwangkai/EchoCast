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
ZStack(alignment: .top) {  // Changed to .top for center alignment
    // Original content switcher
    switch selectedSegment {
    case 0:
        listeningTabContent
    case 1:
        episodeInfoTabContent
    default:
        EmptyView()
    }
    
    // Floating Go Back button overlay (CENTERED)
    if showGoBackButton {
        goBackButtonOverlay
            .padding(.top, 16)  // Distance from top edge
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
            .zIndex(100)  // Ensure it's above all content
    }
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

**Key changes:**
- `ZStack(alignment: .top)` — centers button horizontally, aligns to top
- Remove `.padding(.trailing, 16)` — button is now centered, not right-aligned
- `.transition(.opacity.combined(with: .scale))` — smooth pop-in/out animation
- `.zIndex(100)` — ensures button is above scrolling content

---

### Step 3: Extract Go Back Button as Computed Property

Add this new computed property to `EpisodePlayerView` (place it near other view components):

```swift
// MARK: - Go Back Button Overlay

private var goBackButtonOverlay: some View {
    HStack(spacing: 10) {
        // Circular countdown indicator (LARGER, more prominent)
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2.5)
                .frame(width: 32, height: 32)  // Increased from 24
            
            Circle()
                .trim(from: 0, to: goBackCountdown / 8.0)
                .stroke(Color.mintAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .frame(width: 32, height: 32)  // Increased from 24
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
                    .font(.system(size: 15, weight: .semibold))  // Slightly larger, bolder
                Text("go back")
                    .font(.system(size: 15, weight: .semibold))  // Match weight
            }
            .foregroundColor(.white)  // Pure white for better contrast
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                // Darker, more opaque background like Overcast
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.75))
            )
        }
        .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(
        // Darker pill background for entire button group
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.6))
    )
    .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 4)  // Stronger shadow
}
```

**Key changes for better visibility:**
1. **Larger countdown circle:** 32x32pt (up from 24x24pt)
2. **Bolder text:** Semibold weight at 15pt (up from 14pt medium)
3. **Pure white text:** Better contrast than mint accent
4. **Darker backgrounds:** Black at 75% opacity for inner button, 60% for outer pill
5. **Stronger shadow:** Radius 12 with higher opacity for more depth
6. **Pill-shaped outer container:** Wraps entire button group for cohesive look

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
**After:** Button floats centered at top → content stays put, button fades in/out

**Positioning:**
```
┌─────────────────────────────────┐
│        [⏱️ go back]              │ ← Floating overlay, CENTERED at top
│                                  │
│   (Notes list / Artwork /        │ ← Content area (unchanged)
│    Episode info — depending      │
│    on selected tab)              │
│                                  │
│                                  │
└─────────────────────────────────┘
     [Timeline and controls]        ← Sticky bottom (unchanged)
```

**Styling matches Overcast:**
- Centered horizontally (not top-right)
- Darker backgrounds (black 60-75% opacity) for better contrast
- Larger countdown circle (32pt) for visibility
- Pure white text (not mint) for maximum readability
- Pill-shaped outer container wrapping countdown + button
- Strong shadow for depth

---

## Testing Checklist

- [ ] Button appears **centered horizontally** at top when user scrubs timeline
- [ ] Button **does not push content** up/down when appearing
- [ ] Button floats **above** scrolling content (notes list in Listening tab)
- [ ] Button has **dark backgrounds** (black 60-75% opacity) for contrast
- [ ] Countdown circle is **32pt** diameter (larger, more visible)
- [ ] Text is **pure white** and **semibold** at 15pt (readable)
- [ ] Pill-shaped outer container wraps countdown + button
- [ ] Strong shadow gives depth (radius 12, black 50% opacity)
- [ ] Countdown circle animates correctly (8 seconds)
- [ ] Tapping button seeks back to saved position
- [ ] Button auto-dismisses after 8 seconds
- [ ] Button fades in with scale transition (smooth pop-in)
- [ ] Button respects safe area (not cut off by notch/status bar)
- [ ] Works correctly across all tabs (Listening, Episode Info)
- [ ] Timer cleanup still happens on `.onDisappear`

---

## Code Changed

- **Added:** `goBackButtonOverlay` computed property
- **Modified:** Content switcher wrapped in `ZStack(alignment: .topTrailing)`
- **Removed:** Go Back button code from timeline section (lines 411-456)
- **Unchanged:** State variables, drag gesture logic, timer logic, cleanup

---

## Notes

**Why centered instead of top-right?**  
Following the Overcast reference design you provided — the "Jump Back" button is centered at the top for maximum visibility and easier thumb reach. Center positioning also avoids the "easy to miss" problem you experienced with top-right alignment.

**Why darker backgrounds?**  
The black 60-75% opacity backgrounds provide strong contrast against any content (light album art, white text in notes list, etc.). This matches Overcast's approach and ensures the button is always prominent.

**Why ZStack on content switcher, not on entire view?**  
Because the button should float **above content** but **below the segmented control** and **not overlap sticky player controls**. Placing it on the content switcher achieves this hierarchy:

1. Segmented control (top, fixed)
2. Content area with floating button overlay ← Button here
3. Player controls (bottom, sticky)

**Alternative positioning:** If you want the button in a different vertical position (e.g., middle of screen), adjust `.padding(.top, 16)` to a larger value or use `Spacer()` before the button.
