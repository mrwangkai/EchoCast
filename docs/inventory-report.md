# Component Inventory Report

**Date:** February 4, 2026
**Phase:** 1 - Inventory & Analysis
**Status:** Complete - Ready for Review

---

## Executive Summary

Found **3 episode player implementations** and **1 duplicate inline player** that need consolidation.

**Recommendation:** Keep EpisodePlayerView.swift, remove AudioPlayerView.swift and FullPlayerView (inline).

---

## Player Files Found

### 1. EpisodePlayerView.swift ✅ KEEP

| Property | Value |
|----------|-------|
| **Location** | `EchoNotes/Views/Player/EpisodePlayerView.swift` |
| **Lines** | 724 |
| **Created** | Phase 4 (recent) |
| **Models** | RSSEpisode, PodcastEntity |
| **Tabs** | 3 tabs: Listening, Notes, Episode Info |
| **Features** | Sticky controls, note timeline markers, HTML stripping, segmented control + swipe |

**Where Used:**
- ContentView.swift:74 (full player sheet)
- HomeView.swift:107 (continue listening card)
- Self-references only

**Status:** ✅ **PRIMARY PLAYER** - Most complete implementation with all features

---

### 2. AudioPlayerView.swift ❌ DELETE

| Property | Value |
|----------|-------|
| **Location** | `EchoNotes/Views/AudioPlayerView.swift` |
| **Lines** | 840 |
| **Created** | Older implementation |
| **Models** | RSSEpisode, PodcastEntity |
| **Tabs** | 0 tabs (single scroll view) |
| **Features** | Basic player with note capture, no tab navigation |

**Where Used:**
- ContentView.swift (self-reference in commented code)
- No active references found

**Status:** ❌ **DUPLICATE** - Older single-view player, superseded by EpisodePlayerView

---

### 3. MiniPlayerView.swift ✅ KEEP (with cleanup)

| Property | Value |
|----------|-------|
| **Location** | `EchoNotes/Views/MiniPlayerView.swift` |
| **Lines** | 451 |
| **Created** | Original |
| **Models** | RSSEpisode, PodcastEntity |
| **Tabs** | N/A (mini player component) |
| **Features** | Mini player bar at bottom, tap to open full player |

**ISSUE:** Contains inline `FullPlayerView` struct (line 152) that duplicates AudioPlayerView functionality.

**Where Used:**
- ContentView.swift:63 (mini player in tab bar)

**Status:** ✅ **KEEP** - Required for mini player, but **remove FullPlayerView struct**

---

### 4. FullPlayerView (inline) ❌ DELETE

| Property | Value |
|----------|-------|
| **Location** | Inside MiniPlayerView.swift (lines 152-480) |
| **Lines** | ~328 (embedded) |
| **Models** | RSSEpisode, PodcastEntity |
| **Tabs** | 0 tabs (single scroll view) |
| **Features** | Duplicate of AudioPlayerView functionality |

**Where Used:**
- Nowhere (defined but never instantiated)

**Status:** ❌ **DELETE** - Dead code, defined but never used

---

## Note Capture Components

### 1. NoteCaptureView.swift ✅ KEEP

| Property | Value |
|----------|-------|
| **Location** | `EchoNotes/Views/NoteCaptureView.swift` |
| **Purpose** | Note capture sheet with voice input |
| **Features** | Text editor, voice recording, priority flag, tags |

**Status:** ✅ **KEEP** - Primary note capture interface

---

## Navigation State

### Current Tab Structure (ContentView.swift)

```swift
TabView(selection: $selectedTab) {
    HomeView().tag(0)           // ✅ Keep
    LibraryView().tag(1)        // ✅ Keep
    [BrowseView].tag(2)         // ❌ Find if exists
    [SettingsView].tag(3)       // ❌ Find if exists
}
```

**Status:** Need to verify if Browse/Settings tabs exist and should be converted to icon buttons.

---

## Decision Matrix

| File | Lines | Has Tabs? | Models | Where Used | Decision | Reason |
|------|-------|-----------|--------|------------|----------|--------|
| EpisodePlayerView.swift | 724 | ✅ 3 tabs | RSSEpisode | ContentView, HomeView | **KEEP** | Complete implementation |
| AudioPlayerView.swift | 840 | ❌ 0 tabs | RSSEpisode | None (dead) | **DELETE** | Superseded duplicate |
| MiniPlayerView.swift | 451 | N/A | RSSEpisode | ContentView | **KEEP** | Required component |
| FullPlayerView (inline) | 328 | ❌ 0 tabs | RSSEpisode | Nowhere | **DELETE** | Dead code |
| GlobalPlayerManager.swift | - | N/A | - | Everywhere | **KEEP** | State manager |

---

## Consolidation Plan

### Phase 2 Actions:

1. **Remove FullPlayerView** from MiniPlayerView.swift (lines 150-480)
2. **Delete AudioPlayerView.swift** entirely
3. **Verify navigation** has only 2 tabs (Home + Library)
4. **Add icon buttons** for Find and Settings in navigation bar
5. **Update all references** to use EpisodePlayerView

### Expected Results:

- ✅ Single episode player: EpisodePlayerView.swift
- ✅ Single mini player: MiniPlayerView.swift (cleaned)
- ✅ 2-tab navigation: Home + Library
- ✅ Icon buttons: Find + Settings
- ✅ No duplicate code

---

## Git Safety Checkpoint

Before proceeding to Phase 2, create checkpoint:

```bash
git add .
git commit -m "Phase 1 complete: Inventory report created"
git push origin after-laptop-crash-recovery
```

---

## Approval Required

**Review findings above and approve before proceeding to Phase 2:**

- [ ] Confirm AudioPlayerView.swift can be deleted
- [ ] Confirm FullPlayerView inline code can be removed
- [ ] Approve consolidation plan
- [ ] Ready to proceed to Phase 2

---

**Report Generated:** 2026-02-04
**Next Phase:** DEDUPLICATION-GUIDE.md
