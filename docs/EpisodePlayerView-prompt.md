# Claude Code Implementation Prompt

## Task
Consolidate 5 player-related view files into a single reusable `EpisodePlayerView.swift` component following the exact specifications in `EpisodePlayerView-Specification.md`.

## Context
Read the complete specification document at `/docs/EpisodePlayerView-Specification.md` which contains:
- Current state analysis of all 5 existing player files
- Exact Figma design requirements for all 3 tabs
- Complete code implementations with design tokens
- Integration instructions for all entry points
- File deletion checklist

## Implementation Steps

### 1. Read the Specification
```bash
cat /docs/EpisodePlayerView-Specification.md
```

### 2. Create EpisodePlayerView.swift
- **Location**: `/Views/Player/EpisodePlayerView.swift`
- **Base**: Use FullPlayerView (from MiniPlayerView.swift line 292+) as foundation
- **Add**: Segmented control, Episode Info tab, sticky player controls
- **Requirements**:
  - Three-zone layout: Segmented Control (fixed) | Content Container (scrollable) | Player Controls (sticky)
  - 3 tabs: Listening, Notes, Episode Info
  - Uses RSS/Core Data models (RSSEpisode, PodcastEntity)
  - Uses GlobalPlayerManager.shared for state
  - All design tokens from EchoCastDesignTokens.swift
  - "Add note at current time" button in Listening tab
  - Note timeline markers on progress bar
  - HTML stripping for episode descriptions

### 3. Update Integration Points
- **MiniPlayerView.swift**: Replace FullPlayerView sheet presentation with EpisodePlayerView
- **HomeView.swift**: Update "Continue listening" card to use EpisodePlayerView
- **PodcastDetailView.swift**: Update episode tap to use EpisodePlayerView

### 4. Review & Extract (Before Deletion)
Check `/Views/AudioPlayerView.swift` for useful components:
- EpisodeNoteRow
- QuickNoteCaptureView  
- NoteDetailView

If these are well-designed and follow design tokens, extract to new files. Otherwise, proceed to deletion.

### 5. Delete Legacy Files
After confirming EpisodePlayerView works from all entry points:
```bash
rm Views/PlayerView.swift
rm Views/Player/PlayerView.swift
rm Views/AudioPlayerView.swift
rm Views/PlayerSheetWrapper.swift
```

Remove FullPlayerView struct from MiniPlayerView.swift (keep MiniPlayerView itself).

### 6. Verify
- Project compiles without errors
- All entry points open EpisodePlayerView correctly
- Player controls remain sticky across all tabs
- Design matches Figma exactly

## Critical Requirements

1. **Player Controls MUST be sticky** - Outside any ScrollView, visible across all tabs
2. **Use design tokens** - No hardcoded colors, spacing, or fonts
3. **HTML stripping** - Episode descriptions must strip HTML tags before display
4. **Note markers** - Small circles on progress bar at note timestamps
5. **Segmented control + TabView** - Use both for tap-to-switch AND swipe-to-switch

## Success Criteria
- ✅ Single EpisodePlayerView.swift file compiles
- ✅ All 3 tabs display correctly
- ✅ Player controls sticky across tabs
- ✅ All entry points work (mini player, home, podcast detail)
- ✅ Visual matches Figma designs
- ✅ All 4 legacy files deleted
- ✅ FullPlayerView struct removed from MiniPlayerView

## Reference
All implementation details, exact code snippets, and design specifications are in:
`/docs/EpisodePlayerView-Specification.md`

Read it completely before starting implementation.
