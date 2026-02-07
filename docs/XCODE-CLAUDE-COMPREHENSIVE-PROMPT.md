# EchoCast: Comprehensive Player System Audit & Fix

**Purpose:** Break the patch→hole→patch cycle with systematic, holistic fix  
**Target:** Xcode Claude coding assistant  
**Approach:** Audit first, then fix ALL issues consistently

---

## PROJECT CONTEXT

**App:** EchoCast - iOS podcast player built with SwiftUI  
**Status:** Post-crash recovery with cascading architectural issues  
**Problem:** Each fix reveals new bugs, suggesting systemic disconnection rather than isolated issues

### Technology Stack
- **UI:** SwiftUI with custom design tokens (EchoCastDesignTokens.swift)
- **Audio:** AVPlayer wrapped in GlobalPlayerManager singleton
- **Data:** iTunes Search API → RSS feeds → Core Data (SwiftData)
- **Navigation:** Mix of NavigationStack and .sheet() modals
- **State:** Mix of @State, @ObservedObject, @StateObject

### Design System
- **Colors:** Mint (#00c8b3), Dark Green (#1a3c34), custom semantic colors
- **Typography:** SF Pro with custom modifiers (.title2Echo(), .bodyEcho(), etc.)
- **Spacing:** EchoSpacing constants (screenPadding, cardPadding, etc.)
- **Components:** Figma-designed with specific measurements and layouts

---

## CURRENT STATE: Critical Issues

### ISSUE 1: "Works on 2nd Attempt" Bug ⚠️
**Symptom:**
- User taps podcast in Browse → Sheet opens with blank/loading state
- User closes sheet
- User taps same podcast again → NOW it works, episodes appear

**Console Behavior:**
```
First tap:
🔓 [Browse] Opening sheet for: NPR News
(Sheet opens but nothing loads)

Second tap:
🔓 [Browse] Opening sheet for: NPR News
📊 [PodcastDetail] Task started for: NPR News  ← Only appears on 2nd attempt
📡 [PodcastDetail] Loading episodes...
✅ [PodcastDetail] Episodes loaded: 50 episodes
```

**Root Cause Analysis:**
- Sheet opens immediately when `showingPodcastDetail = true`
- But `selectedPodcast` state hasn't propagated through SwiftUI yet
- `.task` depends on `podcast` being non-nil
- First tap: podcast is nil when .task evaluates
- Second tap: podcast is still set from first attempt

**Attempted Fixes:**
- Added `DispatchQueue.main.asyncAfter(deadline: .now() + 0.05)` delay
- Changed `.onAppear` to `.task`
- Still occurs intermittently

**Files Involved:**
- `PodcastDiscoveryView.swift` - Browse view where podcast tap happens
- `PodcastDetailView.swift` - Sheet that displays episodes
- `HomeView.swift` - Continue Listening and Following sections
- `ContentView.swift` (LibraryView section) - Library podcast navigation

**Entry Points:**
1. Browse → Tap podcast carousel
2. Browse → Tap "View all" → Tap podcast
3. Browse → Search → Tap result
4. Home → Following section → Tap podcast
5. Library → Tap podcast (uses NavigationLink, not sheet)

---

### ISSUE 2: Play Button Does Nothing ❌
**Symptom:**
- User opens episode player sheet
- User taps play button
- Nothing happens - no audio, no visual feedback
- Console NEVER shows: `▶️ [Player] Play called`

**Console Behavior:**
```
When sheet opens:
🎬 [PlayerSheet] Player sheet appeared
⚠️ Episode sheet opened but selectedEpisode is nil

When play button tapped:
(Absolute silence - no logs at all)
```

**Root Cause Analysis:**
- `PlayerSheetWrapper` creates `EpisodePlayerView` but never calls `player.loadEpisode()`
- Play button exists but isn't connected to `GlobalPlayerManager.play()`
- Even if connected, there's no episode loaded to play
- Player UI may be using local state instead of observing GlobalPlayerManager

**Attempted Fixes:**
- Added `.onAppear` to `PlayerSheetWrapper` that calls `player.loadEpisode()`
- Added logging to play button action
- Still not working

**Files Involved:**
- `EpisodePlayerView.swift` - Full-screen player UI with play button
- `PlayerSheetWrapper.swift` (in ContentView.swift) - Container for player
- `GlobalPlayerManager.swift` - Singleton audio player manager
- Multiple entry points that open player sheet

**Entry Points:**
1. Browse → Tap episode in podcast detail
2. Home → Continue Listening → Tap episode
3. Library → Downloaded episodes → Tap episode
4. Mini player → Tap to expand
5. Note tap → Seek to timestamp → Opens player

---

### ISSUE 3: Time Scrubber Frozen ⏱️
**Symptom:**
- Player UI appears
- Play button shows (pause icon after "playing")
- Progress bar exists but doesn't move
- Time labels show "0:00 / 0:00"

**Console Behavior:**
```
✅ [Player] Time observer setup complete
▶️ [Player] Play called
✅ [Player] isPlaying: true
🔍 [Player] Player rate before: 0.0
🔍 [Player] Player rate immediately after: 0.0
⚠️ [Player] WARNING: Player rate is still 0.0 after 0.5s

Missing (should appear every 0.5s):
⏱️ [Player] Observer fired: 1s
⏱️ [Player] Observer fired: 2s
```

**Root Cause Analysis:**
- Time observer is set up correctly
- But player rate stays 0.0 (not actually playing)
- Possible causes:
  - Audio URL invalid
  - AVPlayerItem status never reaches `.readyToPlay`
  - Audio session not configured
  - Player item has error

**Diagnostic Needed:**
- Check audio URL validity
- Monitor AVPlayerItem status transitions
- Check for player item errors
- Verify audio session configuration

**Files Involved:**
- `GlobalPlayerManager.swift` - Time observer setup and play() function
- `EpisodePlayerView.swift` - Progress bar and time display bindings
- Audio session configuration (location TBD)

---

### ISSUE 4: Episode Sheet Opens with Nil Episode ⚠️
**Symptom:**
- Console shows: `⚠️ Episode sheet opened but selectedEpisode is nil`
- This happens in `PodcastDetailView` when opening episode player

**Location:**
`PodcastDetailView.swift:151`

**Context:**
```swift
.sheet(isPresented: $showPlayerSheet) {
    if let episode = selectedEpisode {
        PlayerSheetWrapper(...)
    } else {
        print("⚠️ Episode sheet opened but selectedEpisode is nil")
        // Fallback UI shown
    }
}
```

**This is the SAME pattern as Issue #1** - sheet opens before state propagates.

---

### ISSUE 5: Inconsistent Sheet Opening Patterns
**Problem:** Three different approaches to opening the same destination

**Pattern A: Simple (Broken)**
```swift
.onTapGesture {
    selectedPodcast = podcast
    showingPodcastDetail = true  // Opens immediately
}
```

**Pattern B: With Delay (Attempted Fix)**
```swift
.onTapGesture {
    selectedPodcast = podcast
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        showingPodcastDetail = true
    }
}
```

**Pattern C: NavigationLink (Different Approach)**
```swift
NavigationLink(destination: PodcastDetailView(podcast: podcast)) {
    // Library uses this
}
```

**Issue:** Patterns A and B used inconsistently across entry points, causing bugs in some places but not others.

---

## DESIGN MISMATCHES

### MISMATCH 1: Continue Listening Card
**Figma Spec:** (node-id=1878-4000)
- 88x88 artwork with play overlay
- Progress bar with mint accent
- Time remaining in negative format (e.g., "-12:34")
- Horizontal carousel on home

**Current Implementation:**
- Card exists but artwork may be wrong size
- Time format might not be negative
- Progress bar color might not match mint (#00c8b3)
- Need verification

**Files:** `HomeView.swift`, `ContinueListeningCard.swift` (if exists)

---

### MISMATCH 2: Note Card Layout
**Figma Spec:** (node-id=1878-4052)
- **Top section:** Note text + timestamp badge (left) + tags with max width 225px (right) + overflow indicator ("+2" etc.)
- **Divider separator**
- **Bottom section:** 88x88 artwork + episode info (8px gap, Caption 1 for episode, Caption 2 for series)

**Current Implementation:**
- Layout might not match 3-section design
- Tag overflow handling unclear
- Artwork size might be incorrect
- Spacing might not match 8px gap

**Files:** `NoteCardView.swift` (in ContentView.swift around line 3124)

---

### MISMATCH 3: Browse Genre Carousels
**Figma Spec:** (node-id=1416-7312)
- Horizontal scrolling carousels
- 10 podcasts per genre
- Artwork only (no titles) - 120x120
- No corner radius on artwork
- Section background with 8pt corner radius
- "View all" link per category
- 16-24px bottom padding between sections

**Current Implementation:**
- Genre carousels exist
- Artwork might have corner radius (should be 0)
- Section backgrounds might not have 8pt radius
- Spacing might not match spec

**Files:** `PodcastDiscoveryView.swift`, `CategoryCarouselSection.swift`

---

### MISMATCH 4: Following Section
**Figma Spec:**
- Horizontal carousel on home screen
- Shows followed podcasts
- 120x120 artwork cards
- Part of 3-section home layout: Continue Listening, Following, Recent Notes

**Current Implementation:**
- Following section exists
- Artwork size might be incorrect
- May not be prominently displayed
- Need verification

**Files:** `HomeView.swift`

---

### MISMATCH 5: Episode Player Design
**Figma Spec:** (node-id from episode_player_spec.md)
- 3 tabs: Listening, Notes, Episode Info
- Player controls sticky at bottom across all tabs
- Large album artwork on Listening tab
- Progress bar with note markers
- Time display: current / remaining

**Current Implementation:**
- 3 tabs exist
- Player controls might not be sticky
- Note markers on progress bar unclear
- Time format might not match

**Files:** `EpisodePlayerView.swift`

---

### MISMATCH 6: Mini Player
**Figma Spec:**
- Compact bar at bottom when episode playing
- Shows artwork (small), title, play/pause
- Tap to expand to full player
- Always visible when audio active

**Current Implementation:**
- Mini player exists in `MiniPlayerView.swift`
- Might not be always visible when playing
- Tap behavior might not work
- Need verification

**Files:** `MiniPlayerView.swift`

---

## ARCHITECTURAL CONSTRAINTS (MUST FOLLOW)

### 1. Single Source of Truth
**Rule:** `GlobalPlayerManager.shared` is THE ONLY audio player instance
- ❌ NEVER create new AVPlayer instances elsewhere
- ❌ NEVER duplicate playback state
- ✅ ALL player views MUST observe GlobalPlayerManager

### 2. View Observation Pattern
**Rule:** All views that show player state MUST use @ObservedObject
```swift
// CORRECT:
@ObservedObject private var player = GlobalPlayerManager.shared

// WRONG:
var player = GlobalPlayerManager.shared  // Missing @ObservedObject
@State private var player = ...  // Wrong property wrapper
let player = GlobalPlayerManager.shared  // Not observed
```

### 3. Episode Loading Sequence
**Rule:** MUST call `player.loadEpisode()` before playback
```swift
// CORRECT sequence:
1. Sheet opens
2. .onAppear or .task runs
3. player.loadEpisode(episode, podcast: podcast) called
4. Wait for status == .readyToPlay
5. NOW user can tap play

// WRONG - missing step 3:
1. Sheet opens
2. User taps play
3. Nothing happens (no episode loaded)
```

### 4. State Before Sheet Pattern
**Rule:** State MUST be fully set BEFORE sheet opens
```swift
// CORRECT:
selectedPodcast = podcast
// Ensure state propagates:
DispatchQueue.main.async {  // or .asyncAfter with small delay
    showingPodcastDetail = true
}

// WRONG:
selectedPodcast = podcast
showingPodcastDetail = true  // Too fast, state not propagated
```

### 5. Design Token Usage
**Rule:** MUST use EchoCastDesignTokens, not hardcoded values
```swift
// CORRECT:
.foregroundColor(.echoMint)
.padding(EchoSpacing.screenPadding)
.font(.bodyEcho())

// WRONG:
.foregroundColor(Color(hex: "00c8b3"))
.padding(16)
.font(.system(size: 14))
```

### 6. Navigation Consistency
**Rule:** Use same navigation method for same destination type
- Sheets for modal content (player, note capture)
- NavigationStack for hierarchical browsing
- Don't mix approaches for same destination

---

## TASK: Comprehensive Audit & Fix

### STEP 1: AUDIT (Don't code yet - just analyze and report)

#### A. Player System Mapping
Search entire codebase and create inventory:

**1.1 EpisodePlayerView Instantiation**
- List EVERY location where `EpisodePlayerView` is created
- Note which entry point each serves
- Check if `player.loadEpisode()` is called for each
- Report: Working vs Broken

**1.2 Play/Pause Buttons**
- Find ALL play/pause buttons in the UI
- Check if connected to `GlobalPlayerManager.play()`
- Check if using `@ObservedObject` to observe player
- Report: Which are connected, which aren't

**1.3 Sheet State Management**
- Find ALL sheet presentations with state dependencies
- Check order: State set → Sheet opened?
- Check for timing issues (immediate vs delayed)
- Report: Consistent pattern or mixed?

**1.4 Player Observation**
- Find ALL views that display player state
- Check property wrapper: @ObservedObject vs @State vs var
- Check if observing GlobalPlayerManager.shared
- Report: Which views properly observe

**1.5 Navigation Patterns**
- Map ALL entry points to PodcastDetailView
- Map ALL entry points to EpisodePlayerView
- Check if same destination uses same navigation method
- Report: Consistency issues

#### B. Design Compliance Mapping
Compare implementation to Figma specs:

**1.6 Continue Listening Card**
- Artwork size: 88x88? (Figma spec)
- Time format: Negative remaining? (e.g., "-12:34")
- Progress bar color: Mint #00c8b3?
- Location: Home screen horizontal carousel?

**1.7 Note Card**
- Layout: 3-section (top | divider | bottom)?
- Top: Note text + timestamp + tags (max 225px)?
- Bottom: 88x88 artwork + episode info (8px gap)?
- Tags: Overflow handling with "+n" indicator?

**1.8 Browse Carousels**
- Artwork: 120x120 no corner radius?
- Section background: 8pt corner radius?
- Spacing: 16-24px between sections?
- "View all" links present?

**1.9 Following Section**
- Present on home screen?
- Horizontal carousel?
- 120x120 artwork cards?
- Part of 3-section layout?

**1.10 Episode Player**
- 3 tabs present and working?
- Controls sticky across tabs?
- Note markers on progress bar?
- Time format correct?

#### C. Console Log Analysis
Review diagnostic logs to identify patterns:

**1.11 Timing Issues**
- When does "Task started" appear relative to sheet opening?
- Are there delays between state setting and sheet opening?
- Which entry points log correctly vs incorrectly?

**1.12 Player Connection**
- Where does "Play called" appear?
- Where does "Observer fired" appear?
- What's the sequence when working correctly?
- What's missing when broken?

---

### STEP 2: IDENTIFY PATTERNS

Based on audit, report:

**2.1 What Works Correctly?**
- Which entry points function properly?
- What patterns do they use?
- What makes them different from broken ones?

**2.2 What's Broken?**
- Which entry points fail?
- What patterns do they use?
- What's the common thread?

**2.3 Consistency Analysis**
- Are patterns applied uniformly?
- Where do patterns diverge?
- Which pattern is "correct"?

**2.4 Root Cause Summary**
- Is this a timing issue?
- Is this a connection issue?
- Is this an observation issue?
- Is this multiple issues?

---

### STEP 3: COMPREHENSIVE FIX PLAN

Create detailed plan addressing:

**3.1 Standardize Sheet Opening**
- Define ONE correct pattern
- List ALL locations needing update
- Specify exact code changes for each
- Ensure consistency across ALL entry points

**3.2 Fix Player Connections**
- Ensure ALL play buttons call `player.play()`
- Ensure ALL player views observe properly
- Ensure `player.loadEpisode()` called from ALL entry points
- Add logging to verify connections

**3.3 Fix Design Mismatches**
- List ALL components needing design updates
- Specify exact measurements/colors/layouts
- Reference Figma node IDs
- Ensure design token usage

**3.4 Architectural Alignment**
- Verify single source of truth maintained
- Verify no duplicate state management
- Verify consistent navigation patterns
- Verify proper observation everywhere

**3.5 Change Order & Dependencies**
- What should be changed first?
- What depends on what?
- How to avoid breaking working features?
- Rollback strategy if needed?

---

### STEP 4: IMPLEMENTATION

Provide complete code changes for:

**4.1 Core Fixes (by file)**
For each file requiring changes:
- Show BEFORE (current broken code)
- Show AFTER (fixed code)
- Explain WHY the change is needed
- Note any side effects or risks

**4.2 Consistency Updates**
For each pattern being standardized:
- Show the correct pattern
- List ALL locations using old pattern
- Provide replacement code for each
- Confirm no locations missed

**4.3 Design Updates**
For each design mismatch:
- Show current implementation
- Show Figma-accurate implementation
- Reference specific measurements
- Use proper design tokens

**4.4 Logging Additions**
For verification:
- Add logs at critical points
- Use emoji prefixes for clarity
- Include context in log messages
- Cover all user flows

---

### STEP 5: VERIFICATION PLAN

Provide comprehensive testing:

**5.1 Entry Point Testing**
For EACH entry point (Browse, Home, Library, Search):
```
Entry Point: [Name]
Test: Tap podcast
Expected Console:
  🔓 [Source] Setting selectedPodcast
  🔓 [Source] Opening sheet
  📊 [PodcastDetail] Task started
  ✅ [PodcastDetail] Episodes loaded: X

Expected UI:
  ✅ Sheet opens immediately
  ✅ Episodes appear on FIRST tap
  ✅ No blank screen

Result: [ ] PASS  [ ] FAIL
```

**5.2 Player Testing**
For EACH player entry point:
```
Entry Point: [Name]
Test: Play episode
Expected Console:
  🎬 [PlayerSheet] Calling player.loadEpisode()
  🎵 [Player] Loading episode
  ✅ [Player] Time observer setup
  ▶️ [Player] Play called
  🔍 [Player] Player rate: 1.0
  ⏱️ [Player] Observer fired: 1s
  ⏱️ [Player] Observer fired: 2s

Expected UI:
  ✅ Play button works
  ✅ Audio plays
  ✅ Scrubber moves
  ✅ Time updates

Result: [ ] PASS  [ ] FAIL
```

**5.3 Design Verification**
For each component:
```
Component: [Name]
Figma Spec: [node-id]
Measurements:
  [ ] Artwork: XXxXX
  [ ] Spacing: Xpx
  [ ] Colors: Correct tokens
  [ ] Layout: Matches spec

Result: [ ] PASS  [ ] FAIL
```

**5.4 Regression Testing**
For existing working features:
```
Feature: [Name]
Test: [Action]
Expected: [Result]
Result: [ ] PASS  [ ] FAIL (broken by changes)
```

**5.5 Console Log Verification**
Expected vs Actual:
```
Scenario: [Description]
Expected Logs: [List]
Actual Logs: [Paste from console]
Analysis: [Do they match?]
```

---

### STEP 6: ROLLBACK PROCEDURE

If fixes introduce new issues:

**6.1 Commit Strategy**
- One commit per logical change
- Clear commit messages
- Enable easy revert

**6.2 Rollback Steps**
```bash
# If specific change breaks:
git revert [commit-hash]

# If multiple changes break:
git reset --hard [last-good-commit]
```

**6.3 Fallback Plan**
- Which fixes are critical vs nice-to-have?
- Which can be reverted independently?
- What's the minimal working state?

---

## DELIVERABLES

Please provide:

1. **AUDIT REPORT** (Step 1 & 2)
   - Complete inventory of player system
   - Pattern analysis
   - Root cause identification
   - Design mismatch list

2. **FIX PLAN** (Step 3)
   - Comprehensive change list
   - Priority order
   - Dependencies
   - Risk assessment

3. **CODE CHANGES** (Step 4)
   - All file modifications
   - Before/after comparisons
   - Explanations
   - Logging additions

4. **TESTING PROTOCOL** (Step 5)
   - Complete test scenarios
   - Expected results
   - Console log templates
   - Pass/fail checklist

5. **ROLLBACK GUIDE** (Step 6)
   - Commit strategy
   - Revert procedures
   - Fallback options

---

## SUCCESS CRITERIA

The fix is complete when:

✅ **Functionality:**
- All entry points work on FIRST attempt (no "2nd tap" bug)
- Play button starts audio immediately
- Time scrubber moves in real-time
- All console logs appear as expected
- No new bugs introduced

✅ **Consistency:**
- Same pattern used everywhere for similar actions
- All sheet openings use same timing approach
- All player connections use same observation pattern
- All entry points behave identically

✅ **Architecture:**
- GlobalPlayerManager is single source of truth
- No duplicate player instances or state
- All views properly observe with @ObservedObject
- Episode loading happens before playback

✅ **Design:**
- All components match Figma specs
- Correct measurements and spacing
- Proper color usage (design tokens)
- Consistent with design system

✅ **Verification:**
- All test scenarios pass
- Console logs match expected output
- No regressions in working features
- Code is maintainable and clear

---

## NOTES FOR XCODE CLAUDE

- **Think holistically**: Fix patterns, not just instances
- **Be consistent**: Same solution for same problem everywhere
- **Verify first**: Check your assumptions before coding
- **Log everything**: Add diagnostic logs for debugging
- **Test thoroughly**: Consider all entry points and edge cases
- **Explain clearly**: Help developer understand WHY changes are needed
- **Be complete**: Don't leave similar issues unfixed
- **Stay architectural**: Respect single source of truth

---

**BEGIN WITH STEP 1: COMPREHENSIVE AUDIT**

Do not write any code yet. First, analyze the entire project and provide the audit report identifying ALL instances of the patterns and issues described above.
