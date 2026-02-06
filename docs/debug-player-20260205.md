TASK: Comprehensive Player Time Observer Diagnosis

Problem: Player shows playing but time scrubber doesn't move

Console shows:
▶️ [Player] Play called
✅ [Player] isPlaying: true

But MISSING (should see every 0.5s):
⏱️ [Player] Current time: XXs / YYYs

Reference: Master-Implementation-Guide.md Phase 4 mentions TimeObserver setup
Reference: BROWSE-HOME-REFINEMENTS.md Part 4 has TimeObserver implementation

═══════════════════════════════════════════════════════════

DIAGNOSTIC CHECKLIST - GlobalPlayerManager.swift:

1. Does setupTimeObserver() function exist?
   - Search for: func setupTimeObserver()
   - If YES: Is it being called in loadEpisode()?
   - If NO: Function is missing (needs to be added)
   - Add print at start: print("⏱️ [Player] Setting up time observer")

2. Does loadEpisode() call setupTimeObserver()?
   - Look for: setupTimeObserver() inside loadEpisode()
   - Should be called after creating AVPlayer
   - If missing: Add the call

3. Are @Published properties present?
   - @Published var currentTime: TimeInterval = 0
   - @Published var duration: TimeInterval = 0
   - @Published var isPlaying = false
   - If missing: Add them to class definition

4. Is timeObserver callback firing?
   - Inside addPeriodicTimeObserver callback, add:
     print("⏱️ [Player] Time observer fired: \(currentSeconds)s")
   - This should print every 0.5 seconds when playing

5. Is timeObserver stored as instance variable?
   - private var timeObserver: Any?
   - Must keep reference or it gets deallocated
   - If missing: Add to class properties

6. Does timeObserver use main thread?
   - Check: queue: .main in addPeriodicTimeObserver
   - Should be: player?.addPeriodicTimeObserver(..., queue: .main)
   - If queue: nil or missing: Change to .main

7. Is timeObserver removed properly?
   - Check for: player?.removeTimeObserver(timeObserver)
   - Should be in: deinit or before creating new observer
   - If missing: Add cleanup code

8. Check duration observer setup:
   - Look for: setupDurationObserver() or duration observation
   - Should observe AVPlayerItem.status
   - If missing: Duration won't be set

═══════════════════════════════════════════════════════════

DIAGNOSTIC CHECKLIST - EpisodePlayerView.swift:

9. Is GlobalPlayerManager being observed?
   - Check for: @ObservedObject var player = GlobalPlayerManager.shared
   - OR: @StateObject private var player = GlobalPlayerManager.shared
   - If plain var (no wrapper): Won't observe changes

10. Is progress bar bound to player state?
    - Check Slider binding: Slider(value: $player.currentTime, ...)
    - Should bind to player.currentTime
    - Range should be: in: 0...max(player.duration, 1)
    - If not bound: Scrubber won't update

11. Are time labels bound to player state?
    - Current time: Text(formatTime(player.currentTime))
    - Remaining time: Text(formatTime(player.duration - player.currentTime))
    - If hardcoded: Labels won't update

═══════════════════════════════════════════════════════════

ADD COMPREHENSIVE LOGGING TO:

GlobalPlayerManager.swift:
- loadEpisode() - "🎵 Loading episode: [title]"
- setupTimeObserver() - "⏱️ Setting up time observer"
- setupDurationObserver() - "⏱️ Setting up duration observer"
- Time observer callback - "⏱️ Time: \(currentSeconds)s / \(duration)s"
- play() - "▶️ Play called"
- pause() - "⏸️ Pause called"
- seek() - "⏩ Seeking to: [time]"

EpisodePlayerView.swift:
- onAppear - "🎬 Player view appeared"
- Tab changes - "📑 Switched to tab: [index]"

═══════════════════════════════════════════════════════════

TESTING PROCEDURE:

1. Play any episode
2. Watch console output
3. Check for these logs every 0.5 seconds:
   ⏱️ [Player] Time observer fired: 1s
   ⏱️ [Player] Time observer fired: 2s
   ⏱️ [Player] Time observer fired: 3s

4. If logs appear → UI binding issue (check point 9-11)
5. If logs don't appear → TimeObserver not set up (check point 1-8)

═══════════════════════════════════════════════════════════

OUTPUT: Create docs/player-time-debug.md with:

1. Which functions exist / don't exist
2. Which properties are @Published
3. Where setupTimeObserver() is called (or not called)
4. How player is observed in UI
5. Console log output when playing episode
6. Root cause analysis
7. Recommended fix approach

DO NOT FIX YET - ONLY DIAGNOSE AND REPORT

═══════════════════════════════════════════════════════════

Expected completion time: 5-10 minutes
Priority: HIGH - Player is critical functionality