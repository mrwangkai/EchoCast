# EchoCast TODO

Instructions: 
- At the beginning of the day, with "start the day" command, please do the following: a) assess all open items in all sections and identify top priority tasks, and b) cross reference with estimated level of effort (LOE), and c) propose the top 1~3 task(s) to be focused on based on the combination above. For any tasks that has an estimate, please append to the task the estimated LOE
- please automatically assign ID (e.g. T{xx}) for any item that a) does not have an assigned ID, or b) if it is moved from Inbox.
- please move any item into 🧬 Possible Duplicates if you identify it as such
- for any issue that has been marked as or moved to Done, please also attach the corresponding commit ID. 
- If a task you are working on does not exist in this file, create it in "Currently working on" section with the next available T-ID before starting work.
- For any work that has passed build and commit with an assigned task-id, please include: (Commit history: {commit hash 1}, {commit hash n+1}). Once that task is moved to Done, you can update that with the latest commit (i.e. just showing one: {commit hash})

## 🔥 Currently working on

- [ ] T04 (P1): What happens when a podcast or episode is deleted? Retain notes? Currently PodcastEntity.notes uses Cascade deletion — notes are lost when podcast deleted. Desired: keep notes even if user unfollows/deletes podcast or episode.
- [ ] T05 (P1): How to remove/delete a podcast you no longer want (or nearly finished)
- [ ] T27 (P1): Individual player sheet styling — give bottom section more spacing/breathing room. Current: VStack spacing 16pt, top pad 12pt, bottom pad 48pt, horizontal pad 16pt.
- [ ] T20 (P2): Adjusting element placement on miniplayer — button height 40 (from 44), button spacing 8 (from 12)
- [ ] T29 (P1): Timeline markers must use distinct shapes to differentiate notes (filled circle ●) from bookmarks (diamond ◆) — currently all solid teal circles, which breaks the core note-vs-bookmark distinction that is fundamental to EchoCast's value prop. Target timeProgressWithMarkers in EpisodePlayerView.swift only; bookmark markers already have a diamond spec from prior work that needs to be enforced here. (LOE: S)
- [ ] T30 (P2): The "Bookmark added" undo toast appears at the top of the sheet, far from the bottom-right bookmark button that triggers it — move the toast anchor to just above the bottom action bar so the user sees it without scanning the full screen. This is especially important given the 10-second undo window; proximity to the action directly affects whether users catch it in time. (LOE: XS)
- [ ] T31 (P1): Verify what data the circular progress ring on the "Go Back" chip is bound to — if it mirrors global playback progress it is redundant with the scrubber and should be removed; if it represents a contextual buffer window (e.g. how far back the action will seek) it should be reframed with a tooltip or label to clarify intent. This needs a diagnostic read of GlobalPlayerManager state before any implementation change. (LOE: XS diagnostic, S if change needed)


## 🧭 Backlog

- [ ] T08 (P2): Spacing between Play/Pause and control buttons too close
- [ ] T09 (P2): Add Note sheet is rendering in light mode
- [ ] T10 (P2): Download section — where does this live?
- [ ] T11 (P2): add a "View all" for Continue Listening — sheet or new screen?
- [ ] T12 (P2): add a "View all" for Following Podcasts — sheet or new screen?
- [ ] T14 (P2): Hide Browse tab — reduces redundant ingress point into browse
- [ ] T21 (P2): What does "Following" mean? download the latest episode? if so, should there be series level control similar to overcast? We need something like that but hopefully not overly complicating things.
- [] T22 (P1): add a "Add note at current time" on CarPlay. This will support, alongside, Siri input, more ways to add notes to the app
- [] T25 (P1) Note Sheet Text Field Activation Lag — Keyboard Cursor Delayed on First Tap During Active Playback
- [ ] T26 (P2): Refine NoteCaptureSheetWrapper styling — fix light mode rendering, review and update label font sizes for consistency




## 📨 Inbox (raw ideas)
- [ ] (P2): 
- [ ] (P2): 

## ✅ Done

- [x] T01: Scrubber — make drag smooth by decoupling visual position from seek (1dc4e0d, 33469b5)
- [x] T06: Mini player — visual alignment (9ba80a2, 47a09ce, 9c3e297, 4ee9f7f)
- [x] T13: Balanced single-item "Following Podcast" section layout — inline nudge when count == 1 (e105072)
- [x] T15: Inconsistent sheets
- [x] T16: Modernize mini player with floating pill
- [x] T17: Add "Add Note" button on mini player
- [x] T18: Play/pause button size audit
- [x] T19: Mini player "Add note" sheet auto-dismiss fix — lifted sheet to ContentView level, removed pause/resume logic (0e52239, 5b60839, 61f4bb8, 710ba88, f3ebdf9, bd6e025, 9cf258a, bde5278, a0ec89b, b3a5935, d25ba68, 48e9ca1)
- [x] T23: Fix home screen carousel padding regression — removed outer VStack horizontal padding, applied padding to section headers instead, added .scrollClipDisabled() and .padding(.leading) to horizontal ScrollViews for edge-to-edge carousel effect (4cbc42d)
- [x] T07: Refactored NoteCaptureSheetWrapper — replaced Form with ScrollView+VStack, removed "Mark as Important" toggle, updated podcast metadata to static text with proper typography, added labels to Note/Tags fields, and hardened saveNote() with do/catch error handling and save-failure toast (06da238)
- [x] T28: Individual player sheet AI audit completed — gathered feedback on layout, spacing, and usability. See worklog_20260304.md for summary. Some recommendations acted on (T29-T31), others declined per product strategy.
- [x] T03: Siri "add note to EchoCast" working — phrases like "Hey Siri, add a note in EchoCast" or "Hey Siri, note this in EchoCast" successfully trigger AddNoteIntent. Note capture via Siri functional.
- [x] T02: Scrubber visual size increased — knob from 14pt to 20pt, track height from 4pt to 6pt for better visibility against 28pt markers. Aligns with Overcast standards. (4ba22fe, ed28456)

## 🧬 Possible Duplicates

- T24 → T07: Note sheet metadata styling (combined into T07 with more detailed requirements)

## 🚫 Audit recommendations but does not agree

- (P2): Gemini recommends increasing Play/Pause button visual prominence by applying mint/teal color to make it the focal point of the player. EchoCast intentionally weights the "Add note" action as the primary CTA since timestamped capture is the app's differentiator — rebalancing toward Play/Pause would undermine the product's positioning and should not be acted on. (LOE: N/A)
- (P3): Gemini flags secondary text contrast (podcast name, timestamps) as a potential WCAG failure. The design tokens echoTextSecondary (white 85%) and echoTextTertiary (white 65%) on #262626 background pass WCAG AA at normal text sizes — this is an intentional tiered hierarchy, not an oversight, and should be validated against actual contrast ratios before any change is considered. (LOE: N/A now; revisit post-beta with real device testing)

