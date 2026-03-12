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


## 🧭 Backlog

- [ ] T08 (P2): Spacing between Play/Pause and control buttons too close. (LOE: S)
- [ ] T10 (P2): Download section — where does this live? (LOE: M - requires product decision)
- [ ] T11 (P2): add a "View all" for Continue Listening — sheet or new screen? (LOE: M - requires product decision)
- [ ] T12 (P2): add a "View all" for Following Podcasts — sheet or new screen? (LOE: M - requires product decision)
- [ ] T21 (P2): What does "Following" mean? download the latest episode? if so, should there be series level control similar to overcast? We need something like that but hopefully not overly complicating things. (LOE: M - product + feature work)
- [ ] T25 (P1): Note Sheet Text Field Activation Lag — Keyboard Cursor Delayed on First Tap During Active Playback. (LOE: M - performance investigation)
- [ ] T32 (P3): UX investigation — Home tab re-tap behavior when Browse is in navigation stack. Currently tapping Home tab while on Library returns user to Browse (last navigation state) rather than Home root. Investigate iOS convention: should tab re-tap always pop to root, or preserve navigation state? Reference: Apple Music, Overcast, Podcasts app behavior. If pop-to-root is preferred, implement navigationPath.removeLast() or .removeAll() on tab re-selection. (LOE: S)
- [ ] T33 (P2): Add paywall options — number of notes, number of times you can use advice option(s) such as ai summary/synthesis (LOE: L - business logic + UI)
- [ ] T34 (P2): Think through AI use cases: select podcast episode or individual notes (including after filtered) and ask AI to take pre-defined actions such as summarize, generate action items, etc (LOE: L - product + implementation)
- [ ] T36 (P2): Add/update interaction with individual episodes on podcast series sheet (e.g. swipe to delete) (LOE: M)
- [ ] T37 (P1): Refactor the top section of home screen to have the search and settings button be similar to library tab. This was previously changed to reduce space at the top. Can probably find more info from previous commits. (LOE: S)
- [ ] T45 (P2): Remove these from Note sheet/detail: time "passed", the section header "details" (LOE: S)
- [ ] T47 (P2): Improve search/browse: more relevant options (LOE: L)
- [ ] T58 #CarPlay (P0): Episode playback stops after ~2 seconds with no audio — Observed in Build 8: tapping an episode in CarPlay (from Continue Listening on Home) initiates playback briefly then stops — no audio heard and the playback timer freezes on both the CarPlay screen and the phone. Root cause is likely GlobalPlayerManager not being properly configured for background/CarPlay audio session activation, or the AVAudioSession category not being set before playback begins. Investigate CarPlayNowPlayingController play action handler and confirm AVAudioSession.sharedInstance().setCategory(.playback) is called and activated before AVPlayer begins. Also confirm GlobalPlayerManager.shared is the same instance being used by CarPlay (not a new one). Do not modify EpisodePlayerView or any non-CarPlay files. (Commit: 02f0e22)
- [ ] T59 #CarPlay (P1): Album artwork not loading on Now Playing screen — Observed in Build 8: the CarPlay Now Playing screen shows a generic music note placeholder instead of the episode's podcast artwork. The CPNowPlayingImageButton or MPNowPlayingInfoCenter metadata is not being populated with artwork. Investigate CarPlayNowPlayingController — confirm MPMediaItemArtwork is being created from the episode's artwork URL and set on MPNowPlayingInfoCenter.default().nowPlayingInfo. Artwork fetch may need to happen asynchronously before setting. Do not modify phone-side player UI. (Commit: 0f9799d)
- [ ] T60 #CarPlay (P1): App crashes on first launch, recovers on second — Observed in Build 8: the first time EchoCast is opened via CarPlay it crashes; the second attempt succeeds and stays open. Likely a race condition in CarPlaySceneDelegate — scene is connecting before GlobalPlayerManager or Core Data stack is fully initialized. Investigate CarPlaySceneDelegate.templateApplicationScene(_:didConnect:) — add a guard or deferred initialization to ensure the persistent store is loaded before building CarPlay templates. Check for force-unwraps or synchronous Core Data fetches happening at scene connection time. (LOE: M)
- [ ] T64 CarPlay — Audio + visual confirmation after Add Note capture Priority: P2 | LOE: S Description: After a note is successfully saved via the CarPlay Add Note button (handleAddNoteTap() in CarPlayNowPlayingController.swift), there is currently no feedback to the driver. Add two forms of confirmation: (1) Audio — use AVSpeechSynthesizer to speak a short confirmation e.g. "Note saved at 4:32" using the current playback timestamp from GlobalPlayerManager.shared.currentTime; format the time as M:SS. (2) Visual — show a brief CPAlertTemplate with title "Note Saved" and a single dismiss action, pushed via interfaceController.presentTemplate(_:animated:) then auto-dismissed after ~2 seconds. Both should only trigger on success, not on the error path. Do not modify AddNoteIntent.swift or any non-CarPlay files.


## 📨 Inbox (raw ideas)
- [ ] T38 (P1): Notes listing on notes tab feel … improvement needed (LOE: L - redesign work)
- [ ] T39 (P1): Update button style for play — maybe more rounded (LOE: XS)
- [ ] T48 (P3): Update animation for how the markers show up. Right now its flying in from the left, which feels a bit buggy. And this is happening after the skeleton loading screen. (LOE: M)
- [ ] T50 (P2): "Search is weird". when typing fast, "Con" does not have "Conan" as a top choice; when typing "Co", "Conan" shows up as a top choice. (LOE: M - diagnostic)
- [ ] T53 (P3): CarPlay notes incorrectly write sourceApp = 'Siri' via AddNoteIntent — should write 'CarPlay'. Fix CarPlayNowPlayingController to pass sourceApp directly to createNote rather than routing through AddNoteIntent. (LOE: XS)
- [ ] T54 (P1): CarPlay crash on row tap — Fixed handleEpisodeTap to actually load and play the episode through GlobalPlayerManager. Added CoreData import, fetches PodcastEntity from Core Data using podcastID, constructs RSSEpisode from PlaybackHistoryItem, and calls GlobalPlayerManager.shared.loadEpisodeAndPlay() with seekTo currentTime. Cold-start guard not needed — PlaybackHistoryManager.recentlyPlayed defaults to empty array safely. Build confirmed successful. (Commit: fb4e779)

## ✅ Done

- [x] T46: Add method that note was added as a source badge — Added sourceApp badge to NoteRowDetailView and NoteCardView. Shows "Siri" with waveform icon for Siri notes, raw string for other sources. NoteDetailSheet already had source display. Build confirmed successful. (Commit: 93b6ca1)
- [x] T49: Remove "time since added" timer from note rows — Removed `Text(createdAt, style: .relative)` from NoteRowDetailView and NoteDetailSheet. The playback timestamp (e.g., "12:45") remains. Build confirmed successful. (Commit: 84ccfd8)
- [x] T22: CarPlay "Add note" feature — Fixed CarPlay scene registration: UIApplicationSupportsCarPlay added to Info.plist, AppDelegate.swift created with application(_:configurationForConnecting:options:) implementation, CarPlaySceneDelegate and CarPlayNowPlayingController added to Xcode target. CarPlay now loads in simulator showing "No recent episodes" state. Physical device validation pending TestFlight build. (Commit: e4ef845) Root cause found: Xcode Build Setting "Application Scene Manifest (Generation)" was set to Yes, causing Xcode to overwrite UIApplicationSceneManifest at build time and strip the CarPlay scene config from the archive. Fixed by setting to No in Build Settings → Info.plist Values. Clean build required after change. Rebuild and submit as Build 7 to TestFlight for device validation.
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
- [x] T55 (P2): Update CarPlay display style — Added CPTabBarTemplate with Home and My Podcasts tabs. Home tab has "Continue Listening" (1 episode) and "Latest Episodes" (up to 5) sections. My Podcasts tab shows followed podcasts. Fixed artwork loading: added artworkURL to PlaybackHistoryItem, placeholder SF Symbol while loading, corrected loadAndCacheImage error handling. Also fixed pre-existing bugs (EpisodeEntity references, CPListSection API, async image loading). (Commit: 4fb9c15)
- [x] T56 (P3): Upgrade Claude Code model to GLM-5 — Updated ~/.claude/settings.json: changed ANTHROPIC_DEFAULT_SONNET_MODEL and ANTHROPIC_DEFAULT_OPUS_MODEL to "glm-5". Verified with `/status` in Claude Code. No code commit — config file update only.
- [x] T57 (P1): Diagnose and fix "Continue Listening" disappears on Home Screen after app termination — Added restoreLastPlayedEpisode() to GlobalPlayerManager that reconstructs RSSEpisode from PlaybackHistoryManager and restores currentEpisode/currentPodcast on app launch WITHOUT auto-playing. Fixed HomeView section guards to check continueListeningEpisodes. (Commit: 952c084)
- [x] T62 (P2): App display name shows "EchoNotes" instead of "EchoCast" on iOS and CarPlay home screens — Added CFBundleDisplayName = "EchoCast" to Info.plist. Changes display name on iOS home screen and CarPlay from "EchoNotes" to "EchoCast". Does not affect App Store Connect listing ("EchoCast: Podcast Notes"). (Commit: 6e8e953)
- [x] T61 #CarPlay (P2): Tapping a podcast in "My Podcasts" tab does nothing — Fixed by implementing RSS episode fetch and episode list template push. Replaced empty podcast row handler with full episode list flow: fetches RSS feed via PodcastRSSService.shared.fetchPodcast(from:), builds CPListTemplate with episode items (title + duration/pubDate), creates PlaybackHistoryItem from episode data, and pushes template via interfaceController.pushTemplate. Added parseDurationString helper for duration parsing. (Commit: f1caea6)
- [x] T63 CarPlay — Add Note button crash or silent failure when tapped — Fixed CarPlayNowPlayingController: replaced force-unwrap UIImage(systemName:)! with nil-coalescing fallback, added debug print in catch block for error tracking. MainActor wrapper and interfaceController guard were already in place. (Commit: 87a1c43)

## Reported bug 🐞
- [ ] T44 (P1): "There doesn't appear to be a way to get back to the episodes list when you start an episode". This is an assumption that user are familiar with the swipe down action, which may not be the case. (LOE: S - add back button or dismiss)

## 🧬 Possible Duplicates

- T24 → T07: Note sheet metadata styling (combined into T07 with more detailed requirements)
- T26 → T07/T09: NoteCaptureSheetWrapper styling refinements — addressed by T07 refactoring and T09 light mode fix

## 🚫 Audit recommendations but does not agree

- [ ] T51 (DECLINED): Gemini recommends increasing Play/Pause button visual prominence by applying mint/teal color to make it the focal point of the player. EchoCast intentionally weights the "Add note" action as the primary CTA since timestamped capture is the app's differentiator — rebalancing toward Play/Pause would undermine the product's positioning and should not be acted on.
- [ ] T52 (DECLINED): Gemini flags secondary text contrast (podcast name, timestamps) as a potential WCAG failure. The design tokens echoTextSecondary (white 85%) and echoTextTertiary (white 65%) on #262626 background pass WCAG AA at normal text sizes — this is an intentional tiered hierarchy, not an oversight, and should be validated against actual contrast ratios before any change is considered. Revisit post-beta with real device testing.

