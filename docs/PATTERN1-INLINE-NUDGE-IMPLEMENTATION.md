# Implementation Guide: Pattern 1 — Inline Text Nudge
## Single-Item "Podcasts" Section on Home Screen

**Branch:** `ui/single-podcast-inline-nudge`  
**Scope:** `HomeView.swift` only — surgical modification, no new files  
**Risk:** Very low — purely additive conditional rendering  
**Estimated time:** 15–20 minutes

---

## Context

When a user follows exactly one podcast, the Podcasts section on the home screen
shows a single tile floating to the left with a large empty void to the right.
This reads as broken rather than intentional.

**The fix:** When `followedPodcasts.count == 1`, render a subtle text prompt
("Follow more →") in the empty horizontal space to the right of the lone tile.
When count reaches 2+, the nudge disappears automatically — the second tile fills
the slot. Zero layout changes, zero new components, zero transition risk.

**What does NOT change:**
- The grid layout at any count
- The "Find more" link in the section header
- Any other section (Continue Listening, Recent Notes)
- Any other file in the codebase

---

## Step 1 — Create the branch

Run this in your project root before opening Claude Code:

```bash
git checkout main
git pull origin main
git checkout -b ui/single-podcast-inline-nudge
```

Confirm you're on the right branch:

```bash
git branch --show-current
# should print: ui/single-podcast-inline-nudge
```

---

## Step 2 — Locate the relevant code

Before writing any code, ask Claude Code to read the file and confirm the exact
structure. Copy this diagnostic prompt verbatim:

---

```
READ ONLY — do not modify anything yet.

Open HomeView.swift and find the Podcasts section (also called "Following" section).
I need to understand exactly how it currently renders the podcast tiles.

Tell me:
1. The name of the computed property or view builder that renders the podcast tile row
2. The exact variable name for the followed podcasts array (e.g. followedPodcasts, subscribedPodcasts)
3. Whether the tile row uses HStack, ScrollView + HStack, or LazyHGrid
4. The exact frame/size used for each podcast tile's artwork (width × height)
5. Any spacing values already set on the row (e.g. HStack(spacing: 12))
6. The exact lines that render the horizontal tile row, quoted verbatim

Do not suggest any changes. Just report back what you find.
```

---

Wait for the response before continuing. Verify the findings match what you see in
Xcode. If Claude Code reports a different structure than expected, adjust the
implementation prompt in Step 3 accordingly.

---

## Step 3 — Implement the nudge

Once you have confirmed the structure, send this implementation prompt. Fill in
the bracketed values using the findings from Step 2:

---

```
TASK: Add inline nudge text to the Podcasts section in HomeView.swift
when the user follows exactly one podcast.

File to modify: HomeView.swift
Do NOT create any new files, structs, extensions, or helper views.
Make only the minimal change necessary inside the existing tile row.

--- CONTEXT FROM DIAGNOSIS ---
- Followed podcasts array variable: [PASTE VARIABLE NAME FROM STEP 2]
- Tile row container: [PASTE — HStack / ScrollView+HStack / LazyHGrid]
- Tile artwork size: [PASTE WIDTH × HEIGHT FROM STEP 2]
- Row spacing: [PASTE SPACING VALUE FROM STEP 2]

--- THE CHANGE ---

Inside the existing tile row (wherever the ForEach renders podcast tiles),
wrap the current content in a conditional block so that:

WHEN followedPodcasts.count == 1:
  Render the existing single tile AS-IS (no changes to the tile itself),
  then immediately after it (as a sibling inside the same HStack),
  render this nudge view:

    Spacer()
    Text("Follow more")
      .font(.system(size: 12, weight: .regular))
      .foregroundColor(Color.white.opacity(0.28))
    Image(systemName: "arrow.right")
      .font(.system(size: 11, weight: .regular))
      .foregroundColor(Color.white.opacity(0.28))
    Spacer()

  The Spacers ensure the nudge text is centred in the remaining horizontal space.

WHEN followedPodcasts.count != 1:
  Render exactly what exists today — the ForEach loop with all tiles.
  No changes whatsoever to this path.

--- CONSTRAINTS ---
- Do not use a separate @ViewBuilder or helper function
- Do not modify the tile's frame, corner radius, or label
- Do not modify the section header row (title + "Find more" link)
- Do not add animation modifiers — the nudge appears/disappears without animation
- Do not change spacing in the HStack
- This should be a straightforward if/else inside the existing container

After making the change, show me only the modified section of the file
(from the section header to the closing brace of the tile row container).
Do not show me the entire file.
```

---

## Step 4 — Review before running

Read the diff carefully before building. The change should be:

- **~15–25 lines added** — an `if/else` block replacing the current `ForEach`
- **0 lines deleted** from elsewhere in the file
- **0 new types** declared anywhere
- **Only one `if/else` condition** — `followedPodcasts.count == 1`

If the diff is larger than this, or touches any other section, stop and ask
Claude Code to explain why those additional changes were needed.

---

## Step 5 — Build and verify

```bash
# Build from command line to check for compiler errors before opening simulator
xcodebuild -project EchoNotes.xcodeproj \
           -scheme EchoNotes \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           build 2>&1 | grep -E "error:|warning:|BUILD"
```

**Manual test checklist — run through these in the simulator:**

| Scenario | Expected result |
|---|---|
| 0 podcasts followed | Podcasts section hidden entirely (existing behaviour) |
| 1 podcast followed | Single tile on left, "Follow more →" centred in remaining space |
| 2 podcasts followed | Two tiles side by side, nudge text completely gone |
| 3+ podcasts followed | Tiles in scrolling row, nudge text completely gone |
| Follow a second podcast while on home screen | Nudge disappears, second tile animates in (default SwiftUI) |
| Unfollow second podcast (back to 1) | Nudge reappears, second tile gone |

---

## Step 6 — Commit

Once all checklist items pass:

```bash
git add EchoNotes/Views/HomeView.swift
git commit -m "ui: add inline nudge when only one podcast is followed

When followedPodcasts.count == 1, show a subtle 'Follow more →' prompt
in the empty horizontal space next to the single tile. Disappears
automatically when a second podcast is followed.

- No new files or types
- No layout changes at count 2+
- No animation added (intentional — simple conditional render)

Part of single-item section balance work."
```

---

## Step 7 — Merge to main

```bash
git checkout main
git merge ui/single-podcast-inline-nudge --no-ff \
  -m "Merge ui/single-podcast-inline-nudge: inline nudge for single podcast"
git push origin main

# Clean up branch
git branch -d ui/single-podcast-inline-nudge
git push origin --delete ui/single-podcast-inline-nudge
```

---

## Rollback

If anything is wrong and you want to revert completely:

```bash
# While still on the feature branch — discard all changes
git checkout main
git branch -D ui/single-podcast-inline-nudge

# If you already merged and want to undo
git revert HEAD --no-edit
git push origin main
```

---

## Visual spec summary

```
┌─────────────────────────────────────────────┐
│ Podcasts                          Find more  │  ← section header, unchanged
├─────────────────────────────────────────────┤
│ ┌──────┐                                    │
│ │  HL  │     Follow more  →                 │  ← count == 1
│ └──────┘                                    │
│ Huberman Lab                                 │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│ Podcasts                          Find more  │
├─────────────────────────────────────────────┤
│ ┌──────┐  ┌──────┐                          │
│ │  HL  │  │  AJ  │                          │  ← count == 2, nudge gone
│ └──────┘  └──────┘                          │
│ Huberman   Art Juice                         │
└─────────────────────────────────────────────┘
```

**Nudge text style:**
- Font: `.system(size: 12, weight: .regular)` — lighter than tile labels
- Color: `Color.white.opacity(0.28)` — matches `var(--text-subtle)` from design tokens
- Arrow: SF Symbol `arrow.right`, same size and opacity as text
- No border, no background, no tap action — purely informational
