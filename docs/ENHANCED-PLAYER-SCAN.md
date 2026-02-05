# Comprehensive Player Variant Detection

## Purpose
Scan entire codebase for ALL episode player variants and duplicates.

## Run This First - Complete Player Audit

```bash
#!/bin/bash
echo "═══════════════════════════════════════════"
echo "  EPISODE PLAYER VARIANT DETECTION SCAN"
echo "═══════════════════════════════════════════"
echo ""

echo "1. FINDING ALL PLAYER FILES..."
echo "-------------------------------------------"
find EchoNotes -type f -name "*.swift" | grep -i "player" | sort

echo ""
echo "2. FINDING PLAYER VIEW STRUCTS..."
echo "-------------------------------------------"
grep -r "struct.*Player.*View" EchoNotes --include="*.swift" | grep -v "Preview" | sort

echo ""
echo "3. FINDING PLAYER-RELATED VIEWS..."
echo "-------------------------------------------"
grep -r "struct.*Player\|struct.*Episode.*View" EchoNotes --include="*.swift" | grep -v "Preview\|//\|Cache" | sort

echo ""
echo "4. CHECKING FOR FULL PLAYER IMPLEMENTATIONS..."
echo "-------------------------------------------"
# Look for views with 3+ tabs or segmented controls
grep -l "Listening\|Notes\|Episode Info\|SegmentedControl" EchoNotes/Views/*.swift EchoNotes/Views/**/*.swift 2>/dev/null | sort

echo ""
echo "5. CHECKING FOR INLINE PLAYER CODE IN OTHER FILES..."
echo "-------------------------------------------"
# Look for player code embedded in ContentView, HomeView, etc.
for file in EchoNotes/ContentView.swift EchoNotes/Views/HomeView.swift EchoNotes/Views/MiniPlayerView.swift; do
    if [ -f "$file" ]; then
        echo "Checking $file..."
        grep -n "struct.*Player\|func.*player\|var.*player" "$file" | head -5
    fi
done

echo ""
echo "6. FINDING NOTE SHEET VARIANTS..."
echo "-------------------------------------------"
find EchoNotes -type f -name "*Note*.swift" | grep -i "sheet\|capture\|add" | sort

echo ""
echo "7. CHECKING FOR DUPLICATE PLAYER PRESENTATIONS..."
echo "-------------------------------------------"
# Find where players are presented (sheets, NavigationLinks)
grep -rn "\.sheet.*Player\|NavigationLink.*Player\|\.fullScreenCover.*Player" EchoNotes --include="*.swift" | cut -d: -f1,2 | sort -u

echo ""
echo "8. PLAYER STATE MANAGEMENT..."
echo "-------------------------------------------"
# Find different player state systems
grep -rn "PlayerState\|@StateObject.*player\|@ObservedObject.*player" EchoNotes --include="*.swift" | cut -d: -f1 | sort -u

echo ""
echo "9. AUDIO PLAYBACK IMPLEMENTATIONS..."
echo "-------------------------------------------"
# Find AVPlayer usage (indicates actual player logic)
grep -l "AVPlayer\|AVAudioPlayer" EchoNotes/**/*.swift 2>/dev/null | sort

echo ""
echo "10. MODEL TYPES USED..."
echo "-------------------------------------------"
# Check which models each player uses
for file in $(find EchoNotes -name "*Player*.swift" -type f); do
    echo "File: $file"
    grep "RSSEpisode\|PodcastEpisode\|iTunesPodcast\|PodcastEntity" "$file" | head -3
    echo ""
done

echo "═══════════════════════════════════════════"
echo "  SCAN COMPLETE"
echo "═══════════════════════════════════════════"
```

## Manual Scan Commands (Run These)

```bash
# 1. Find all player files
find EchoNotes -name "*Player*.swift" -o -name "*player*.swift"

# 2. Find all player structs
grep -r "struct.*Player.*:" EchoNotes/Views --include="*.swift"

# 3. Find episode views
find EchoNotes -name "*Episode*.swift" | grep -i "view\|detail"

# 4. Check file sizes
find EchoNotes/Views -name "*Player*.swift" -exec wc -l {} \;

# 5. Find note sheets
find EchoNotes -name "*Note*.swift" | grep -i "add\|capture\|sheet"
```

---

## Decision Matrix

Fill this out based on scan results:

| File | Lines | Has Tabs? | Models Used | Where Used | Status |
|------|-------|-----------|-------------|------------|--------|
| EpisodePlayerView.swift | ??? | 3 tabs | RSSEpisode | ??? | ✅ KEEP |
| AudioPlayerView.swift | ??? | ??? | ??? | ??? | ❓ CHECK |
| PlayerView.swift | ??? | ??? | ??? | ??? | ❓ CHECK |
| MiniPlayerView.swift | ??? | 0 tabs | N/A | Tab bar | ✅ KEEP |
| GlobalPlayerManager.swift | ??? | N/A | Both | Everywhere | ✅ KEEP |

---

## Decision Rules

### KEEP If:
- ✅ Uses RSSEpisode + PodcastEntity
- ✅ Has 3 tabs (Listening, Notes, Episode Info)
- ✅ Uses GlobalPlayerManager.shared
- ✅ Has sticky player controls
- ✅ Created in Phase 4
- ✅ Has note timeline markers

### DELETE If:
- ❌ Uses PodcastEpisode + iTunesPodcast (old models)
- ❌ Has 2 or fewer tabs
- ❌ Uses local PlayerState
- ❌ Is a simple wrapper
- ❌ Duplicates another file's functionality

### INVESTIGATE If:
- ⚠️ <100 lines (might be needed wrapper)
- ⚠️ Has unique features
- ⚠️ Referenced in many places

---

## Enhanced Claude Code Prompt

```
TASK: Comprehensive Player Deduplication

PHASE 1: Detection & Inventory
Run these commands and document results:
1. find EchoNotes -name "*Player*.swift"
2. grep -r "struct.*Player.*View" EchoNotes --include="*.swift"
3. find EchoNotes -name "*Episode*.swift" | grep -i view
4. Check file sizes: wc -l for each player file

Create inventory table with:
- File name
- Line count
- Number of tabs (if player)
- Models used (RSSEpisode vs PodcastEpisode)
- Where referenced
- Keep/Delete recommendation

PHASE 2: Analysis
For EACH player file found:
1. Check which models it uses
2. Count how many tabs it has
3. Find all references: grep -r "FileName" EchoNotes
4. Determine if it has unique features
5. Make keep/delete decision with evidence

PHASE 3: Safe Consolidation
Only after Phase 1 & 2 complete:
1. Verify EpisodePlayerView has ALL features
2. Update references to deleted files
3. Delete duplicate files
4. Test build

Document everything in docs/player-consolidation-report.md

CRITICAL RULES:
- Do NOT delete until references updated
- Do NOT assume - verify with grep
- Document every decision
- Test after each deletion
```

---

## What's Different from Original Guide?

### Original DEDUPLICATION-GUIDE.md:
- ⚠️ Assumed only AudioPlayerView duplicate
- ⚠️ Didn't check for inline players
- ⚠️ Didn't verify model types
- ⚠️ No comprehensive scan

### This Enhanced Guide:
- ✅ Scans ALL player variants
- ✅ Checks inline code in other files
- ✅ Verifies models used
- ✅ Creates decision matrix
- ✅ Comprehensive before deleting

---

**Use BOTH guides together:**
1. Run **THIS** guide first (comprehensive scan)
2. Fill out decision matrix
3. Then run **original** DEDUPLICATION-GUIDE.md (execution)

This ensures you don't miss ANY player variants! 🔍
