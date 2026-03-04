# EchoCast TODO

Instruction: 
- please automatically assign ID (e.g. T{xx}) for any item that a) does not have an assigned ID, or if it is moved from Inbox.
- please move any item into 🧬 Possible Duplicates if you identify it as such
- for any issue that has been marked as or moved to Done, please also attach the corresponding commit ID. 
- If a task you are working on does not exist in this file, create it in "Currently working on" section with the next available T-ID before starting work.

## 🔥 Currently working on

- [ ] T02 (P0): Scrubber appears too small (hitbox / visual size)
- [ ] T03 (P1): Siri "add note to EchoCast" is not working — tablestake
- [ ] T04 (P1): What happens when a podcast or episode is deleted? Retain notes?
- [ ] T05 (P1): How to remove/delete a podcast you no longer want (or nearly finished)
- [ ] T20 (P2): Adjusting element placement on miniplayer — button height 40 (from 44), button spacing 8 (from 12)


## 🧭 Backlog

- [ ] T07 (P2): Add Note sheet — series, episode, timestamp should read as body text, not input fields
- [ ] T08 (P2): Spacing between Play/Pause and control buttons too close
- [ ] T09 (P2): Add Note sheet is rendering in light mode
- [ ] T10 (P2): Download section — where does this live?
- [ ] T11 (P2): "View all" for Continue Listening — sheet or new screen?
- [ ] T12 (P2): "View all" for Following Podcasts — sheet or new screen?
- [ ] T14 (P2): Hide Browse tab — reduces redundant ingress point into browse
- [ ] T21 (P2): What does "Following" mean? download the latest episode? if so, should there be series level control similar to overcast? We need something like that but hopefully not overly complicating things.
- [] T22 (P1): add a "Add note at current time" on CarPlay. This will support, alongside, Siri input, more ways to add notes to the app



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

## 🧬 Possible Duplicates

