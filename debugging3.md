Debugging Prompt for Claude Code – SwiftUI Version

You can paste this into Claude Code for debugging your collapsible podcast player built in SwiftUI.

---

# 🎧 Debugging Prompt for SwiftUI Mini Player → Full Player Collapse Issue

I’m building a podcast player UI in SwiftUI with a persistent mini-player at the bottom of the screen (similar to Spotify or Overcast). When the user taps the mini-player, it should expand into a full-screen player using `.sheet` or a custom animated container.

### **The Issue**
On iOS, when I tap the mini player, it expands briefly, but within 1–2 seconds it automatically collapses back to the mini player. This happens consistently.

### **Current Architecture**
- The root view uses a `TabView` (SwiftUI equivalent of `UITabBarController`).
- The mini-player is rendered above the tab bar using:
  - A `ZStack` overlay in the root view  
  - Or a persistent `View` attached at the root level
- The full player appears using **one** of the following:
  - `.sheet(isPresented:)`
  - A full-screen cover (`.fullScreenCover`)
  - A custom transition using `matchedGeometryEffect`

I also have a global audio engine (`AVPlayer`) with a model object using `@Observable`, `@StateObject`, or `@EnvironmentObject`.

### **What I suspect**
The collapse may be due to:
- A state update in my audio player model resetting `isExpanded`
- A parent view recreating because of `@State` or `@ObservedObject` changes
- The full player view being re-rendered or unmounted (similar to `viewDidDisappear`)
- The sheet being dismissed automatically due to:
  - `presentationDetents` changing
  - A gesture recognizer from the sheet dismissing unintentionally
- Conflicting animation states:
  - `matchedGeometryEffect` resetting its namespace
- Multiple sources updating the same expansion state (`isExpanded`)

### **What I want from you**
Please help me debug the issue step-by-step, focusing on SwiftUI’s view lifecycle and state system.

---

## **1. Identify Likely Root Causes**
Analyze potential causes referencing SwiftUI-specific components, including:

- `@State` vs `@StateObject` vs `@ObservedObject` vs `@EnvironmentObject`
- Whether my `PlayerViewModel` is being re-created because it is not stored correctly
- SwiftUI’s implicit view destruction and recreation
- `.sheet` using `item:` vs `isPresented:` APIs
- Whether `presentationDetents` are causing dismissal  
- Gesture conflicts:
  - `DragGesture` on the sheet
  - interactive dismiss via `interactiveDismissDisabled(false)`
- `matchedGeometryEffect` inconsistencies across different view hierarchies
- Whether `TabView` switching triggers re-rendering of ancestors

---

## **2. Steps to Diagnose**
List concrete debugging steps, such as:

- Print logs whenever:
  - MiniPlayer mounts/unmounts
  - FullPlayerView mounts/unmounts
  - `isExpanded` changes  
- Verify whether `PlayerViewModel` is initialized once:
  - Should be stored at the app root (`@StateObject` in App struct or root view)
- Inspect whether `FullPlayerView` uses any `@State` that resets on re-render
- Log SwiftUI view identity using `.id(...)`
- Confirm `.sheet` dismissal events (`onDismiss`) are not being triggered unintentionally
- Validate that audio engine callbacks (`AVPlayer.timeControlStatusPublisher`) are not mutating UI state

---

## **3. Recommend Fixes (High-Level)**
Provide guidance such as:

- Centralize player UI state in a single source of truth:
  ```swift
  @Observable class PlayerUIState {
      var isExpanded = false
      var currentEpisode: Episode?
  }
  ```
- Move `PlayerUIState` and `PlayerViewModel` into:
  - `@StateObject` at root
  - or `@EnvironmentObject` throughout app
- Ensure mini-player is **never destroyed**:
  - Place it in a `ZStack` overlay inside the root `TabView`
- Ensure `.sheet` is not dismissed unless explicitly requested:
  - Use `.interactiveDismissDisabled(true)`
- If using `matchedGeometryEffect`, ensure both views share the same namespace and hierarchy
- Debounce expansion taps:
  - Prevent immediate collapse during animation
- Use an imperative coordinator (e.g., a struct with `@MainActor` functions) to handle expansion:
  ```swift
  withAnimation(.spring()) {
      uiState.isExpanded = true
  }
  ```

---

## **4. Provide a Suggested Architecture (SwiftUI-Safe)**
Describe how I should structure the app:

```
App
 └── RootView
      ├── TabView
      ├── MiniPlayerView (persistent)
      └── FullPlayerView (sheet or overlay, always driven by global state)
```

- `PlayerViewModel` → `@StateObject` at the highest possible level
- `PlayerUIState` → `@EnvironmentObject`
- Only global state mutates the expansion/collapse state

---

Please reason carefully using SwiftUI behaviors, view lifecycle, state propagation, and sheet dismissal logic. Think like an iOS engineer debugging view invalidation or premature sheet dismissal in SwiftUI.

