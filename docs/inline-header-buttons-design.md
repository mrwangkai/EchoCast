# Inline Header Buttons Design - Future Implementation

**Date:** February 24, 2026
**Status:** Deferred (trade-off analysis complete)

---

## Overview

This document explores the option of placing search and settings buttons **inline with the "EchoCast" title** rather than in the navbar toolbar.

**Current state:** Buttons are in `.toolbar { ToolbarItem(placement: .topBarTrailing) }`

**Proposed state:** Buttons are in an HStack next to "EchoCast" title

---

## Trade-offs

### What We Gain (Inline Buttons)
- More unique/custom visual design
- Buttons appear next to the title they control
- Slightly more compact initial view
- Can have different spacing/alignment than standard navbar

### What We Lose (Native Navbar)
- **Large title → small title collapse behavior on scroll**
- **Centered title in navbar when scrolling down**
- Native iOS animation smoothness
- Familiar iOS user experience patterns

---

## The Core Conflict

**SwiftUI's `.navigationTitle()`** provides two things:
1. A large title display at the top
2. Automatic collapse to a centered small title in the navbar on scroll

**But `.navigationTitle()`** forces all content below the navbar — you cannot place custom views inline with the title.

**Custom header approach** (inline buttons) means:
- You remove `.navigationTitle()` and `.navigationBarTitleDisplayMode(.large)`
- You build your own header with HStack containing title + buttons
- You lose the automatic collapse behavior
- The header scrolls away like any other content

---

## Implementation Options

### Option A: Native Navbar (Current) ✅

**What it looks like:**
```swift
.navigationTitle("EchoCast")
.navigationBarTitleDisplayMode(.large)
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 16) {
            Button(action: { selectedTab = 1 }) {
                Image(systemName: "magnifyingglass")
            }
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
            }
        }
    }
}
```

**Pros:**
- Native large → small title collapse
- Centered title in navbar on scroll
- Familiar iOS UX

**Cons:**
- Buttons not inline with title

---

### Option B: Custom Inline Header

**What it looks like:**
```swift
// Add computed property
private var headerSection: some View {
    HStack {
        Text("EchoCast")
            .font(.largeTitleEcho())
        Spacer()
        HStack(spacing: 16) {
            Button(action: { selectedTab = 1 }) {
                Image(systemName: "magnifyingglass")
            }
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
            }
        }
    }
    .padding(.horizontal, EchoSpacing.screenPadding)
    .padding(.top, 16)  // Important: prevents tight layout
}

// In body
ScrollView {
    VStack(alignment: .leading, spacing: 32) {
        headerSection  // Add as first item
        // ... rest of content
    }
}
// NO .navigationTitle, NO .navigationBarTitleDisplayMode, NO .toolbar
```

**Pros:**
- Buttons inline with title
- Custom design control

**Cons:**
- No large → small title collapse
- Header scrolls away like regular content
- Need to add top padding manually
- Loses native iOS feel

---

### Option C: Scroll-Synchronized Custom Header (Advanced)

**Concept:** Track scroll offset and manually animate header between large and small states.

**What it looks like:**
```swift
@State private var scrollOffset: CGFloat = 0.0

// In ScrollView
ScrollViewReader { proxy in
    ScrollView {
        GeometryReader { geo in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: geo.frame(in: .named("scroll")).minY
            )
        }
        // ... content
    }
    .coordinateSpace(name: "scroll")
}
.onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
    scrollOffset = value
    // Animate header between large/small based on offset
}

// Header responds to scrollOffset
private var headerSection: some View {
    HStack {
        Text("EchoCast")
            .font(scrollOffset < -50 ? .body : .largeTitleEcho())
        // ...
    }
    .offset(y: max(0, scrollOffset + 50))
}
```

**Pros:**
- Can have both inline buttons AND collapse behavior
- Custom animation control

**Cons:**
- Complex to implement
- Hard to match native iOS animation curves
- Maintenance burden
- May feel "off" if not perfectly matched to native behavior

---

### Option D: Leading/Trailing Toolbar Items

**What it looks like:**
```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button(action: { selectedTab = 1 }) {
            Image(systemName: "magnifyingglass")
        }
    }
    ToolbarItem(placement: .topBarTrailing) {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gearshape")
        }
    }
}
```

**Pros:**
- Keeps native collapse behavior
- More balanced layout

**Cons:**
- Buttons still not inline with title
- Less conventional (users expect actions on right)

---

## Recommendation

**Stick with Option A (Native Navbar)** unless:
1. Custom branding is critical and worth UX trade-off
2. You're willing to invest in Option C (complex custom implementation)

**Reasoning:**
- Native iOS behavior is familiar to users
- Large → small title collapse is a key iOS navigation pattern
- The difference between "navbar buttons" and "inline buttons" is minor for most users

---

## Files Referenced

- `EchoNotes/Views/HomeView.swift` - Main home screen
- `EchoNotes/Views/BrowseView.swift` - Has similar navbar pattern
- `EchoNotes/Views/LibraryView.swift` - Has similar navbar pattern

---

## Related Commits

- `8db3739` - Home UI: "Podcasts" + "Find more" link (kept)
- `7942d62` - Move search/settings inline (reverted)
- `4d342b7` - Revert inline header buttons

---

## Decision Record

**Date:** February 24, 2026
**Decision:** Keep native navbar with toolbar buttons
**Reason:** Preserves native iOS large → small title collapse behavior, which is a key UX pattern

**To revisit this decision:**
- If custom branding becomes a higher priority
- If user testing indicates navbar buttons are confusing
- If a simpler implementation approach is discovered
