# EchoCast TODO

Instructions: 
- At the beginning of the day, with "start the day" command, please do the following: a) assess all open items in all sections and identify top priority tasks, and b) cross reference with estimated level of effort (LOE), and c) propose the top 1~3 task(s) to be focused on based on the combination above. For any tasks that has an estimate, please append to the task the estimated LOE. And for any task that does not have a task ID attached, please add it sequentially.
- please automatically assign ID (e.g. T{xx}) for any item that a) does not have an assigned ID, or b) if it is moved from Inbox.
- please move any item into 🧬 Possible Duplicates if you identify it as such
- for any issue that has been marked as or moved to Done, please also attach the corresponding commit ID. 
- If a task you are working on does not exist in this file, create it in "Currently working on" section with the next available T-ID before starting work.
- For any work that has passed build and commit with an assigned task-id, please include: (Commit history: {commit hash 1}, {commit hash n+1}). Once that task is moved to Done, you can update that with the latest commit (i.e. just showing one: {commit hash})

## 🔥 Currently working on

- [ ] T42 (P2): Unify button icon color to mintAccent token — Commit history: 3a0d1c1, 84ce1a1. PENDING VISUAL TEST.
- [ ] T05 (P1): How to remove/delete a podcast you no longer want (or nearly finished). (LOE: M)
- [ ] T20 (P2): Adjusting element placement on miniplayer — button height 40 (from 44), button spacing 8 (from 12). (LOE: S)
- [ ] T30 (P3): The "Bookmark added" undo toast appears at the top of the sheet, far from the bottom-right bookmark button that triggers it — move the toast anchor to just above the bottom action bar so the user sees it without scanning the full screen. This is especially important given the 10-second undo window; proximity to the action directly affects whether users catch it in time. (LOE: XS)
- [ ] T31 (P3): Verify what data the circular progress ring on the "Go Back" chip is bound to — if it mirrors global playback progress it is redundant with the scrubber and should be removed; if it represents a contextual buffer window (e.g. how far back the action will seek) it should be reframed with a tooltip or label to clarify intent. This needs a diagnostic read of GlobalPlayerManager state before any implementation change. (LOE: XS diagnostic, S if change needed)
- [ ] T43 (P2): "View all" sheets for Continue Listening and Your Shows sections on homescreen — Continue Listening sheet shows vertical list of in-progress episodes with progress bars and note pips. Your Shows sheet shows followed podcasts with context blurb and "Add a show" row. (LOE: M) — Implementation complete. Commit: 029f265


## 🧭 Backlog

- [ ] T08 (P2): Spacing between Play/Pause and control buttons too close. (LOE: S)
- [ ] T10 (P2): Download section — where does this live? (LOE: M - requires product decision)
- [ ] T11 (P2): add a "View all" for Continue Listening — sheet or new screen? (LOE: M - requires product decision)
- [ ] T12 (P2): add a "View all" for Following Podcasts — sheet or new screen? (LOE: M - requires product decision)
- [ ] T21 (P2): What does "Following" mean? download the latest episode? if so, should there be series level control similar to overcast? We need something like that but hopefully not overly complicating things. (LOE: M - product + feature work)
- [] T25 (P1) Note Sheet Text Field Activation Lag — Keyboard Cursor Delayed on First Tap During Active Playback. (LOE: M - performance investigation)
- [ ] T32 (P3): UX investigation — Home tab re-tap behavior when Browse is in navigation stack. Currently tapping Home tab while on Library returns user to Browse (last navigation state) rather than Home root. Investigate iOS convention: should tab re-tap always pop to root, or preserve navigation state? Reference: Apple Music, Overcast, Podcasts app behavior. If pop-to-root is preferred, implement navigationPath.removeLast() or .removeAll() on tab re-selection. (LOE: S)
- [ ] T33 (P2): Add paywall options — number of notes, number of times you can use advice option(s) such as ai summary/synthesis
- [ ] T34 (P2): Think through AI use cases: select podcast episode or individual notes (including after filtered) and ask AI to take pre-defined actions such as summarize, generate action items, etc
- [ ] T36 (P2): Add/update interaction with individual episodes on podcast series sheet (e.g. swipe to delete)
- [ ] T37 (P1): Refactor the top section of home screen to have the search and settings button be similar to library tab. This was previously changed to reduce space at the top. Can probably find more info from previous commits.
- [ ] T42 (P3) Update color of link -- the green color is inconsistent in different context: in mini player, the add note and playback buttons have a brighter green; in the individual player sheet, the "add note..." and "bookmark" buttons have a darker green
- [ ] (P2) Remove these from Note sheet/detail: time "passed", the section header "details"
- [ ] (P2) Add method that note was added (such as Siri or manual or Carplay) as a tag
- [ ] Improve search/browse: more relevant options



## 📨 Inbox (raw ideas)
- [ ] T38 (P1): Notes listing on notes tab feel … improvement needed
- [ ] T39 (P1): Update button style for play — maybe more rounded
- [ ] Update animation for how the markers show up. Right now its flying in from the left, which feels a bit buggy. And this is happening after the skeleton loading screen. Would it be possible to 
- [ ] (P2) Timer in the bottom right of new notes keeps ticking up for some reason -- this is the time since added. we can remove it for now. there's no strong reason to have a timestamp for when the note was added.
- [ ] "Search is weird". when typing fast, "Con" does not have "Conan" as a top choice; when typing "Co", "Conan" shows up as a top choice. Possible need to evaluate common search behavior.

## ✅ Done

- [x] T22: CarPlay "Add note" feature — Fixed CarPlay scene registration: UIApplicationSupportsCarPlay added to Info.plist, AppDelegate.swift created with application(_:configurationForConnecting:options:) implementation, CarPlaySceneDelegate and CarPlayNowPlayingController added to Xcode target. CarPlay now loads in simulator showing "No recent episodes" state. Physical device validation pending TestFlight build. (Commit: {pending})
- [x] T01: Scrubber — make drag smooth by decoupling visual position from seek (1dc4e0d, 33469b5)
- [x] T06: Mini player — visual alignment (9ba80a2, 47a09ce, 9c3e297, 4ee9f7f)
- [x] T13: Balanced single-item "Following Podcast" section layout — inline nudge when count == 1 (e105072)
- [x] T15: Inconsistent sheets (completed as part of T19 mini player work)
- [x] T16: Modernize mini player with floating pill (8680711, 9c3e297, 9ba80a2)
- [x] T17: Add "Add Note" button on mini player (699e8d1, 47a09ce)
- [x] T18: Play/pause button size audit (4ee9f7f, ed896a8)
- [x] T19: Mini player "Add note" sheet auto-dismiss fix — lifted sheet to ContentView level, removed pause/resume logic (0e52239, 5b60839, 61f4bb8, 710ba88, f3ebdf9, bd6e025, 9cf258a, bde5278, a0ec89b, b3a5935, d25ba68, 48e9ca1)
- [x] T23: Fix home screen carousel padding regression — removed outer VStack horizontal padding, applied padding to section headers instead, added .scrollClipDisabled() and .padding(.leading) to horizontal ScrollViews for edge-to-edge carousel effect (4cbc42d)
- [x] T07: Refactored NoteCaptureSheetWrapper — replaced Form with ScrollView+VStack, removed "Mark as Important" toggle, updated podcast metadata to static text with proper typography, added labels to Note/Tags fields, and hardened saveNote() with do/catch error handling and save-failure toast (06da238)
- [x] T28: Individual player sheet AI audit completed — gathered feedback on layout, spacing, and usability. See worklog_20260304.md for summary. Some recommendations acted on (T29-T31), others declined per product strategy. (8f97d8e)
- [x] T27: Individual player sheet spacing — album artwork 240pt, marker→timeline gap 6pt, scrubber→controls spacing 24pt, footer bottom 24pt. (431c845)
- [x] T29: Timeline marker shapes — note markers as filled circles (●), bookmark markers as diamonds (◆). Fixed bookmark x-position offset. (9dff2a7)
- [x] T35: Update individual notes row on episode sheet — created NoteRowView component for episode player notes tab. Redesigned NoteCardView to two-column timestamp/note layout with expand toggle. Adjusted spacing: horizontal padding 32pt, bottom spacing 24pt, footer top padding 24pt. (ddf1c47)
- [x] T03: Siri "add note to EchoCast" working — phrases like "Hey Siri, add a note in EchoCast" or "Hey Siri, note this in EchoCast" successfully trigger AddNoteIntent. Note capture via Siri functional. (12a0a7b, 73e248b, ab048fa, fcef116, 3d95db1)
- [x] T02: Scrubber visual size increased — knob from 14pt to 20pt, track height from 4pt to 6pt for better visibility against 28pt markers. Aligns with Overcast standards. (4ba22fe, ed28456)
- [x] T04: Note persistence fix — changed PodcastEntity.notes deletionRule from Cascade to Nullify so notes survive podcast unfollow. Created new Core Data model version "EchoNotes 2.xcdatamodel" for lightweight migration. (32979e0)
- [x] T09: Add Note sheet light mode fix — forced dark mode with explicit colors. Moved .preferredColorScheme(.dark) to outermost ZStack, replaced system colors with dark RGB values (background: 0.149, fields: 0.2). Sheet now consistently renders in dark mode. (c76f69f, 4b6b54c)
- [x] T14: Remove Browse tab — converted Browse from standalone tab to pushed navigation page. Search icon + "Find more" + empty state CTAs on Home and Library now push PodcastDiscoveryView via NavigationPath. Removed inner NavigationStack from PodcastDiscoveryView, fixed inline title flash. commits: 2a6f186, 5b75454, 72d973c, 30bde23, 4519612 | branch: browse-flow-update
- [x] T26: Refine NoteCaptureSheetWrapper styling — addressed by T07 refactoring (labels, typography) and T09 light mode fix. No further work needed.
- [x] T41: Fix bottom tab bar glass appearance — added .toolbarBackground(Color(red: 0.149, green: 0.149, blue: 0.149), for: .tabBar), .toolbarBackground(.visible, for: .tabBar), .toolbarColorScheme(.dark, for: .tabBar), and .preferredColorScheme(.dark) to TabView. Fixed washed-out white/gray appearance on first app launch. Tab bar now uses dark translucent glass matching app theme immediately. (0f5d1ec)
- [x] T40: Fix player action button visual hierarchy — Add note button remains primary (mint fill), Bookmark button now secondary (white opacity 0.08 background with white icon). Creates clear visual hierarchy between primary and secondary actions. (909ea9d, 9025859, d9e9160, a3019b8)

## Reported bug 🐞
- [ ] (P1) "There doesn’t appear to be a way to get back to the episodes list when you start an episode". This is an assumption that user are familiar with the swipe down action, which may not be the case. #UX

## 🧬 Possible Duplicates

- T24 → T07: Note sheet metadata styling (combined into T07 with more detailed requirements)
- T26 → T07/T09: NoteCaptureSheetWrapper styling refinements — addressed by T07 refactoring and T09 light mode fix

## 🚫 Audit recommendations but does not agree

- (P2): Gemini recommends increasing Play/Pause button visual prominence by applying mint/teal color to make it the focal point of the player. EchoCast intentionally weights the "Add note" action as the primary CTA since timestamped capture is the app's differentiator — rebalancing toward Play/Pause would undermine the product's positioning and should not be acted on. (LOE: N/A)
- (P3): Gemini flags secondary text contrast (podcast name, timestamps) as a potential WCAG failure. The design tokens echoTextSecondary (white 85%) and echoTextTertiary (white 65%) on #262626 background pass WCAG AA at normal text sizes — this is an intentional tiered hierarchy, not an oversight, and should be validated against actual contrast ratios before any change is considered. (LOE: N/A now; revisit post-beta with real device testing)

