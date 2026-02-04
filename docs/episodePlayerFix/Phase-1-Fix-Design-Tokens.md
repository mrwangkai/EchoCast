# Phase 1: Fix Design Tokens

## Problem
`EpisodePlayerView.swift` can't find `Color.echoBackground`, `EchoSpacing`, etc.

## Root Cause
Either:
1. `EpisodePlayerView.swift` isn't in the Xcode build target
2. `EchoCastDesignTokens.swift` isn't in the build target
3. File is in a folder not added to the project properly

## Fix Steps

### Step 1: Check File Target Membership

**In Xcode:**

1. **Select `EpisodePlayerView.swift` in Project Navigator**
2. **Open File Inspector** (right sidebar, first tab - folder icon)
3. **Find "Target Membership" section**
4. **Ensure "EchoNotes" checkbox is CHECKED** ✅

If unchecked, check it now.

---

5. **Select `EchoCastDesignTokens.swift` in Project Navigator**
6. **File Inspector → Target Membership**
7. **Ensure "EchoNotes" checkbox is CHECKED** ✅

### Step 2: Verify Import Statements

**Open `EpisodePlayerView.swift`**

Ensure these imports are at the top:

```swift
import SwiftUI
import CoreData
import AVFoundation
```

**Note:** You do NOT need to import `EchoCastDesignTokens` - Swift extensions are automatically available when files are in the same target.

### Step 3: Build and Check Errors

**In Xcode:**
1. Press `Cmd + B` to build
2. Check if design token errors are gone

**Expected Result:**
- ✅ `Color.echoBackground` errors resolved
- ✅ `EchoSpacing` errors resolved
- ❌ Model type errors still present (we'll fix in Phase 2-4)

### If Still Not Working

**Check file location:**

```bash
# In terminal, verify files exist and are in Views directory
ls -la /path/to/EchoNotes/Views/EchoCastDesignTokens.swift
ls -la /path/to/EchoNotes/Views/Player/EpisodePlayerView.swift
```

**If files are in "New Folder" or oddly named directory:**
1. In Xcode, drag files to proper location (`/Views/` for design tokens, `/Views/Player/` for player)
2. Ensure "Copy items if needed" is UNCHECKED (files should stay in original location)
3. Rebuild

---

## Verification

After Phase 1, these errors should be GONE:
- ✅ `error: type 'Color' has no member 'echoBackground'`
- ✅ `error: cannot find 'EchoSpacing' in scope`

These errors will REMAIN (we'll fix them in Phase 2-4):
- ❌ `cannot convert value of type 'RSSEpisode' to expected argument type 'PodcastEpisode'`
- ❌ `missing argument for parameter 'playerState' in call`

---

## Next Step
Once design tokens are working, proceed to **Phase 2: Create Model Adapter**
