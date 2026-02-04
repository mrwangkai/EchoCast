# EpisodePlayerView Implementation Guide - Complete Walkthrough

**Implementation Strategy:** Full Migration to RSS Models (Option 1)  
**Estimated Time:** 2-3 hours  
**Difficulty:** Intermediate

---

## Overview

This guide walks you through consolidating 5 player-related view files into a single, reusable `EpisodePlayerView` component and migrating from dual model system (iTunes + RSS) to unified RSS-based architecture.

### What You'll Accomplish

**Before:**
- 5 player files with mixed data models
- Dual state management (PlayerState + GlobalPlayerManager)
- Inconsistent behavior across entry points
- Technical debt and code duplication

**After:**
- 1 unified player component (EpisodePlayerView)
- Single RSS/Core Data model system
- Consistent behavior everywhere
- Clean, maintainable architecture

---

## Prerequisites

Before starting, ensure you have:
- [ ] Xcode project open
- [ ] All files committed to git (for easy rollback if needed)
- [ ] Project builds successfully (even with errors from missing AudioPlayerView)
- [ ] Both specification documents saved:
  - `EpisodePlayerView-Specification.md`
  - `Claude-Code-Prompt.md`

---

## Implementation Phases

| Phase | Task | Time | Complexity |
|-------|------|------|------------|
| **Phase 1** | Fix Design Tokens | 5 min | Easy |
| **Phase 2** | Create Model Adapter | 30 min | Medium |
| **Phase 3** | Create RSS-based AddNoteSheet | 30 min | Medium |
| **Phase 4** | Update ContentView Integration | 1 hour | Medium |
| **Phase 5** | Testing & Cleanup | 30 min | Easy |

---

## Phase-by-Phase Guide

### Phase 1: Fix Design Tokens (5 minutes)

**Goal:** Ensure `EpisodePlayerView.swift` can access design tokens.

**Instructions:** See `Phase-1-Fix-Design-Tokens.md`

**Quick Summary:**
1. Check file target membership in Xcode
2. Verify `EpisodePlayerView.swift` target = "EchoNotes" ✅
3. Verify `EchoCastDesignTokens.swift` target = "EchoNotes" ✅
4. Build project
5. Confirm design token errors are resolved

**Success Criteria:**
- ✅ No more `Color.echoBackground` errors
- ✅ No more `EchoSpacing` errors
- ❌ Model type errors still present (expected)

---

### Phase 2: Create Model Adapter (30 minutes)

**Goal:** Build a service that converts iTunes search results to RSS/Core Data models.

**Instructions:** See `Phase-2-Model-Adapter.md`

**Quick Summary:**
1. Create `/Services/ModelAdapter.swift`
2. Implement conversion logic:
   - Take iTunes models (PodcastEpisode, iTunesPodcast)
   - Fetch RSS feed from feedUrl
   - Find matching episode
   - Create/fetch PodcastEntity in Core Data
   - Return (RSSEpisode, PodcastEntity)
3. Add file to Xcode project
4. Build to verify it compiles

**Success Criteria:**
- ✅ `ModelAdapter.swift` compiles successfully
- ✅ Has `convertToRSSModels()` async function
- ✅ Handles Core Data creation/fetching

---

### Phase 3: Create RSS-based AddNoteSheet (30 minutes)

**Goal:** Create note capture sheet that works with RSS models and GlobalPlayerManager.

**Instructions:** See `Phase-3-AddNoteSheet-RSS.md`

**Quick Summary:**
1. Create `/Views/AddNoteSheetRSS.swift`
2. Implement sheet with:
   - RSS model parameters (RSSEpisode, PodcastEntity)
   - GlobalPlayerManager for playback state
   - Core Data save functionality
   - EchoCast design tokens
3. Update `EpisodePlayerView.swift` to use `AddNoteSheetRSS`
4. Build to verify

**Success Criteria:**
- ✅ `AddNoteSheetRSS.swift` compiles
- ✅ `EpisodePlayerView` model type errors resolved
- ❌ ContentView `AudioPlayerView` errors still present (expected)

---

### Phase 4: Update ContentView Integration (1 hour)

**Goal:** Replace all 5 AudioPlayerView references with conversion wrapper + EpisodePlayerView.

**Instructions:** See `Phase-4-ContentView-Integration.md`

**Quick Summary:**
1. Add `iTunesPlayerAdapter` view to ContentView.swift
2. Replace all 5 `AudioPlayerView` references:
   - Line 737: Podcasts view sheet
   - Line 1671: PlayerSheetData sheet
   - Line 2142: PlayerSheetWrapper
   - Line 2471: Note edit sheet
   - Line 3605: Downloaded episodes sheet
3. Build project
4. Fix any remaining errors

**Success Criteria:**
- ✅ Project builds with ZERO errors
- ✅ All AudioPlayerView references replaced
- ✅ iTunesPlayerAdapter compiles

---

### Phase 5: Testing & Cleanup (30 minutes)

**Goal:** Verify everything works and clean up legacy code.

**Instructions:** See `Phase-5-Testing-Cleanup.md`

**Quick Summary:**
1. Test all entry points:
   - Browse/Search → Episode play
   - Home "Continue listening"
   - Podcast detail → Episode play
   - Mini player tap
   - Note creation and seeking
2. Verify all 3 tabs work
3. Test player controls
4. Clean up unused code
5. Update documentation

**Success Criteria:**
- ✅ All entry points open EpisodePlayerView correctly
- ✅ All functionality works
- ✅ No crashes or major bugs
- ✅ Performance is acceptable

---

## Quick Start Commands

### For Claude Code

If using Claude Code to implement:

```bash
# Step 1: Read implementation prompt
cat /docs/Claude-Code-Prompt.md

# Step 2: Read full specification
cat /docs/EpisodePlayerView-Specification.md

# Step 3: Implement according to specs
# (Claude Code will handle this automatically)
```

### For Manual Implementation

If implementing manually:

```bash
# Phase 1: Check files
ls -la Views/EchoCastDesignTokens.swift
ls -la Views/Player/EpisodePlayerView.swift

# Phase 2: Create adapter
touch Services/ModelAdapter.swift
# (Then paste code from Phase-2-Model-Adapter.md)

# Phase 3: Create note sheet
touch Views/AddNoteSheetRSS.swift
# (Then paste code from Phase-3-AddNoteSheet-RSS.md)

# Phase 4: Already have ContentView.swift, just edit it
# (Follow Phase-4-ContentView-Integration.md)

# Phase 5: Test everything
# (Follow Phase-5-Testing-Cleanup.md checklist)
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Design tokens not found
**Symptom:** `Cannot find 'EchoSpacing' in scope`  
**Solution:** Check target membership (Phase 1)

#### Issue 2: ModelAdapter conversion fails
**Symptom:** "Failed to load episode" error  
**Solution:** 
- Verify podcast has valid feedUrl
- Check network connectivity
- Add debug logging to see where it fails

#### Issue 3: ContentView still has AudioPlayerView errors
**Symptom:** Build errors on line 737, 1671, etc.  
**Solution:** 
- Ensure you replaced ALL 5 references
- Search codebase: `grep -r "AudioPlayerView" --include="*.swift"`

#### Issue 4: Notes not saving
**Symptom:** Note sheet closes but note doesn't appear  
**Solution:**
- Check Core Data context is being passed correctly
- Verify `viewContext.save()` isn't throwing errors
- Check console for save errors

---

## Testing Checklist

After completing all phases, verify:

### Entry Points
- [ ] Browse/Search → Tap episode → Opens player
- [ ] Home "Continue listening" → Opens player
- [ ] Podcast detail → Tap episode → Opens player
- [ ] Mini player → Tap → Opens full player

### Player Functionality
- [ ] All 3 tabs accessible (Listening, Notes, Episode Info)
- [ ] Player controls sticky across tabs
- [ ] Can add notes from "Add note at current time" button
- [ ] Notes appear in Notes tab
- [ ] Tapping note seeks to timestamp
- [ ] Episode info shows without HTML tags

### Playback Controls
- [ ] Play/Pause works
- [ ] Skip forward/backward works
- [ ] Progress bar updates in real-time
- [ ] Can seek by dragging progress bar
- [ ] Note markers appear on progress bar
- [ ] Playback speed control works

---

## Success Metrics

**Code Quality:**
- ✅ 5 files → 2 files (60% reduction)
- ✅ Single model system (RSS/Core Data)
- ✅ Single state management (GlobalPlayerManager)
- ✅ Zero code duplication

**Functionality:**
- ✅ All features working
- ✅ Consistent behavior across entry points
- ✅ Seamless iTunes → RSS conversion

**Performance:**
- ✅ No memory leaks
- ✅ RSS conversion completes quickly (<2s)
- ✅ Smooth playback

---

## File Structure - Before & After

### Before (Messy)
```
Views/
├─ PlayerView.swift (iTunes models, local state) ❌
├─ Player/
│  └─ PlayerView.swift (duplicate) ❌
├─ AudioPlayerView.swift (legacy) ❌
├─ PlayerSheetWrapper.swift (simple wrapper) ❌
├─ MiniPlayerView.swift (contains FullPlayerView) ⚠️
└─ AddNoteSheet.swift (iTunes models) ⚠️
```

### After (Clean)
```
Views/
├─ Player/
│  └─ EpisodePlayerView.swift (RSS models, unified) ✅
├─ MiniPlayerView.swift (mini bar only) ✅
├─ AddNoteSheetRSS.swift (RSS models) ✅
└─ AddNoteSheet.swift (keep for reference, unused) 📦

Services/
└─ ModelAdapter.swift (iTunes → RSS converter) ✅
```

---

## Help & Support

### If You Get Stuck

1. **Check the specific phase documentation** - Each has detailed steps
2. **Review error messages** - Xcode errors are usually specific
3. **Search for patterns** - Use grep to find related code
4. **Test incrementally** - Don't skip phases
5. **Use git** - Commit after each phase for easy rollback

### Useful Commands

```bash
# Find all references to a type
grep -r "AudioPlayerView" /path/to/project --include="*.swift"

# Check target membership
# (Do this in Xcode File Inspector)

# Clean build
# Xcode: Product → Clean Build Folder (Cmd+Shift+K)

# Build
# Xcode: Product → Build (Cmd+B)

# Run
# Xcode: Product → Run (Cmd+R)
```

---

## Timeline Estimate

| Phase | Estimated Time | Complexity |
|-------|---------------|------------|
| Phase 1: Design Tokens | 5 minutes | ⭐ Easy |
| Phase 2: Model Adapter | 30 minutes | ⭐⭐ Medium |
| Phase 3: AddNoteSheet RSS | 30 minutes | ⭐⭐ Medium |
| Phase 4: ContentView Integration | 1 hour | ⭐⭐ Medium |
| Phase 5: Testing & Cleanup | 30 minutes | ⭐ Easy |
| **Total** | **~2.5 hours** | **⭐⭐ Medium** |

**Note:** Times assume familiarity with Xcode and Swift. First-time implementation may take longer.

---

## Completion Checklist

After finishing all phases:

- [ ] Project builds with zero errors
- [ ] All 5 entry points work correctly
- [ ] Player functionality complete
- [ ] Note taking works
- [ ] No memory leaks
- [ ] Design matches Figma
- [ ] Legacy files deleted
- [ ] Documentation updated
- [ ] Changes committed to git

---

## What's Next?

After successful implementation:

1. **Monitor for edge cases** - Watch for unusual podcasts or episodes
2. **Gather user feedback** - Test with beta users
3. **Add unit tests** - Especially for ModelAdapter
4. **Performance optimization** - If RSS conversion is slow
5. **Consider enhancements:**
   - Cache RSS feed results
   - Preload episodes in background
   - Add offline mode indicator

---

## Resources

- **Full Specification:** `EpisodePlayerView-Specification.md` (900+ lines)
- **Claude Code Prompt:** `Claude-Code-Prompt.md` (concise directive)
- **Phase Guides:**
  - `Phase-1-Fix-Design-Tokens.md`
  - `Phase-2-Model-Adapter.md`
  - `Phase-3-AddNoteSheet-RSS.md`
  - `Phase-4-ContentView-Integration.md`
  - `Phase-5-Testing-Cleanup.md`

---

**Good luck with the implementation! 🚀**

You're consolidating 5 files into 1, eliminating technical debt, and building a cleaner architecture. Take it phase by phase and you'll get there!
