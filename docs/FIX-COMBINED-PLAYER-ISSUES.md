# Fix: Player Issues - Combined Guide

**Date:** February 5, 2026  
**Issues:** (1) Time scrubber doesn't move, (2) "Works on 2nd attempt" bug  
**Priority:** HIGH - Critical UX issues  
**Estimated Time:** 20-30 minutes

---

## Overview

Two separate but related issues:

1. **Player Time Scrubber Doesn't Move**
   - Root Cause: Player rate stays 0.0 (not actually playing audio)
   - Symptoms: Play button works, but progress bar frozen
   
2. **"Works on 2nd Attempt" Bug**
   - Root Cause: .onAppear doesn't fire reliably when sheets open
   - Symptoms: First tap shows blank/loading, second tap works

---

## PART 1: Fix "Works on 2nd Attempt" Bug

**Reference:** docs/player-time-debug.md - Root Cause Analysis

### Issue: .onAppear Unreliable

**Problem:** Sheets open immediately but .onAppear doesn't always fire, causing data to not load on first attempt.

**Solution:** Use `.task` instead of `.onAppear` for data loading.

---

### Fix 1.1: PodcastDetailView - Use .task

**File:** `PodcastDetailView.swift`

**Find this pattern:**
```swift
.onAppear {
    loadEpisodes()
}
```

**Replace with:**
```swift
.task {
    print("📊 [PodcastDetail] Task started for: \(podcast?.title ?? "nil")")
    print("📊 [PodcastDetail] Feed URL: \(podcast?.feedURL ?? "nil")")
    
    await loadEpisodes()
    
    print("✅ [PodcastDetail] Task completed - \(episodes.count) episodes")
}
```

**If .task already exists,** ensure it has proper logging:
```swift
.task {
    print("📊 [PodcastDetail] View task started")
    print("📊 [PodcastDetail] Podcast: \(podcast?.title ?? "nil")")
    print("📊 [PodcastDetail] Feed URL: \(podcast?.feedURL ?? "nil")")
    
    guard let podcast = podcast else {
        print("❌ [PodcastDetail] No podcast provided")
        return
    }
    
    await loadEpisodes()
    
    print("✅ [PodcastDetail] Episodes loaded: \(episodes.count)")
}
```

---

### Fix 1.2: Make loadEpisodes() Properly Async

**File:** `PodcastDetailView.swift`

**Ensure loadEpisodes() function is async and updates on main thread:**

```swift
private func loadEpisodes() async {
    print("📡 [PodcastDetail] Loading episodes...")
    
    guard let feedURL = podcast?.feedURL else {
        print("❌ [PodcastDetail] No feed URL available")
        await MainActor.run {
            errorMessage = "No feed URL available"
        }
        return
    }
    
    print("📡 [PodcastDetail] Fetching from: \(feedURL)")
    
    await MainActor.run {
        isLoadingEpisodes = true
    }
    
    do {
        let service = PodcastRSSService()
        let fetchedEpisodes = try await service.fetchEpisodes(from: feedURL)
        
        print("✅ [PodcastDetail] Fetched \(fetchedEpisodes.count) episodes")
        
        await MainActor.run {
            self.episodes = fetchedEpisodes
            self.isLoadingEpisodes = false
            print("✅ [PodcastDetail] UI updated with \(fetchedEpisodes.count) episodes")
        }
    } catch {
        print("❌ [PodcastDetail] Failed to load episodes: \(error)")
        await MainActor.run {
            self.errorMessage = "Failed to load episodes: \(error.localizedDescription)"
            self.isLoadingEpisodes = false
        }
    }
}
```

---

### Fix 1.3: Add Loading State Properties

**File:** `PodcastDetailView.swift`

**Add these at top of struct (if missing):**
```swift
@State private var isLoadingEpisodes = false
@State private var errorMessage: String?
```

---

### Fix 1.4: Remove Double-Nested DispatchQueue

**File:** `HomeView.swift` or wherever episode tap handler is

**Find this pattern (around lines 74-83):**
```swift
DispatchQueue.main.async {
    DispatchQueue.main.async {
        // navigation code
    }
}
```

**Replace with:**
```swift
Task { @MainActor in
    print("🎧 [Home] Opening episode player")
    // navigation code
}
```

---

### Fix 1.5: Add Loading UI to PodcastDetailView

**File:** `PodcastDetailView.swift`

**In body, wrap episodes list with loading state:**

```swift
var body: some View {
    ScrollView {
        VStack(alignment: .leading, spacing: 16) {
            // Podcast header
            podcastHeader
            
            // Loading/Error/Episodes
            if isLoadingEpisodes {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading episodes...")
                        .font(.bodyEcho())
                        .foregroundColor(.echoTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if let error = errorMessage {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Error")
                        .font(.title2Echo())
                    
                    Text(error)
                        .font(.bodyEcho())
                        .foregroundColor(.echoTextSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task {
                            await loadEpisodes()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else if episodes.isEmpty {
                // Empty state
                Text("No episodes found")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                // Episodes list
                episodesList
            }
        }
    }
    .task {
        // As defined in Fix 1.1
    }
}
```

---

## PART 2: Fix Player Time Scrubber

**Reference:** docs/player-time-debug.md - Player Time Observer Diagnosis

### Issue: Player Rate Stays 0.0

**Problem:** AVPlayer.play() is called but player doesn't actually start playing (rate remains 0.0).

**Solution:** Add comprehensive diagnostics to find why player won't play, then fix based on findings.

---

### Fix 2.1: Enhanced Audio URL Logging

**File:** `GlobalPlayerManager.swift`

**In loadEpisode() function, after getting audio URL (around line 150-170):**

```swift
// Get audio URL
let audioURLString = /* ... existing code ... */

guard let audioURL = URL(string: audioURLString) else {
    print("❌ [Player] Invalid audio URL string: \(audioURLString)")
    return
}

print("✅ [Player] Valid audio URL: \(audioURL.absoluteString)")
print("🔍 [Player] URL scheme: \(audioURL.scheme ?? "none")")
print("🔍 [Player] URL is file: \(audioURL.isFileURL)")
print("🔍 [Player] URL host: \(audioURL.host ?? "none")")
```

---

### Fix 2.2: Enhanced AVPlayerItem Status Logging

**File:** `GlobalPlayerManager.swift`

**After creating AVPlayerItem (around line 210):**

```swift
let playerItem = AVPlayerItem(url: audioURL)
print("🔍 [Player] Created AVPlayerItem")
print("🔍 [Player] Item status immediately: \(playerItem.status.rawValue)")

// Add error observer
playerItem.publisher(for: \.error)
    .sink { error in
        if let error = error {
            print("❌ [Player] Item error: \(error.localizedDescription)")
            print("❌ [Player] Error code: \((error as NSError).code)")
            print("❌ [Player] Error domain: \((error as NSError).domain)")
        }
    }
    .store(in: &cancellables)

player = AVPlayer(playerItem: playerItem)
print("🔍 [Player] Created AVPlayer")
print("🔍 [Player] Player rate: \(player?.rate ?? -1)")
```

---

### Fix 2.3: Enhanced Status Observer

**File:** `GlobalPlayerManager.swift`

**In the status observer (around line 210-243), replace with:**

```swift
playerItem.publisher(for: \.status)
    .sink { [weak self] status in
        guard let self = self else { return }
        
        let statusName = self.statusString(status)
        print("🔍 [Player] Status changed to: \(status.rawValue) (\(statusName))")
        
        switch status {
        case .unknown:
            print("⏳ [Player] Status: unknown - waiting for player item to load...")
            
        case .readyToPlay:
            print("✅ [Player] Status: readyToPlay - player is ready!")
            
            let durationSeconds = CMTimeGetSeconds(playerItem.duration)
            print("🔍 [Player] Duration value: \(durationSeconds)")
            
            if durationSeconds.isFinite && durationSeconds > 0 {
                Task { @MainActor in
                    self.duration = durationSeconds
                    print("✅ [Player] Duration set: \(Int(durationSeconds))s (\(self.formatTime(durationSeconds)))")
                }
            } else {
                print("⚠️ [Player] Duration not available or invalid: \(durationSeconds)")
            }
            
        case .failed:
            print("❌ [Player] Status: FAILED - player item failed to load")
            
            if let error = playerItem.error {
                print("❌ [Player] Error: \(error.localizedDescription)")
                print("❌ [Player] Error code: \((error as NSError).code)")
                print("❌ [Player] Error domain: \((error as NSError).domain)")
                
                // Log user info for more details
                let userInfo = (error as NSError).userInfo
                for (key, value) in userInfo {
                    print("❌ [Player] Error info - \(key): \(value)")
                }
            } else {
                print("❌ [Player] No error object available")
            }
            
        @unknown default:
            print("⚠️ [Player] Unknown status: \(status.rawValue)")
        }
    }
    .store(in: &cancellables)
```

---

### Fix 2.4: Add Status Helper Function

**File:** `GlobalPlayerManager.swift`

**Add this helper function to the class:**

```swift
private func statusString(_ status: AVPlayerItem.Status) -> String {
    switch status {
    case .unknown:
        return "unknown"
    case .readyToPlay:
        return "readyToPlay"
    case .failed:
        return "FAILED"
    @unknown default:
        return "unknown_default"
    }
}
```

---

### Fix 2.5: Enhanced play() Function

**File:** `GlobalPlayerManager.swift`

**Replace play() function with enhanced version:**

```swift
func play() {
    print("▶️ [Player] Play called")
    
    guard let player = player else {
        print("❌ [Player] Cannot play - no player exists")
        return
    }
    
    guard let item = player.currentItem else {
        print("❌ [Player] Cannot play - no current item")
        return
    }
    
    let statusName = statusString(item.status)
    print("🔍 [Player] Current item status: \(item.status.rawValue) (\(statusName))")
    
    if item.status != .readyToPlay {
        print("⚠️ [Player] Item not ready to play! Status: \(statusName)")
        
        if let error = item.error {
            print("❌ [Player] Item has error: \(error.localizedDescription)")
        } else {
            print("⚠️ [Player] Item is still loading, will play when ready")
        }
    }
    
    print("🔍 [Player] Player rate before play(): \(player.rate)")
    print("🔍 [Player] Current time before play(): \(currentTime)")
    
    player.play()
    isPlaying = true
    
    print("✅ [Player] play() executed, isPlaying set to true")
    print("🔍 [Player] Player rate immediately after play(): \(player.rate)")
    
    // Check rate after short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        guard let self = self, let player = self.player else { return }
        print("🔍 [Player] Player rate 0.5s after play(): \(player.rate)")
        
        if player.rate == 0.0 {
            print("⚠️ [Player] WARNING: Player rate is still 0.0 after 0.5s")
            print("⚠️ [Player] This means audio is NOT playing")
            
            if let item = player.currentItem {
                print("🔍 [Player] Item status: \(self.statusString(item.status))")
                if let error = item.error {
                    print("❌ [Player] Item error: \(error.localizedDescription)")
                }
            }
        } else {
            print("✅ [Player] Player is playing! Rate: \(player.rate)")
        }
    }
    
    updateNowPlayingInfo()
}
```

---

### Fix 2.6: Enhanced Time Observer Callback

**File:** `GlobalPlayerManager.swift`

**In time observer setup (around line 253), modify callback:**

```swift
let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
    guard let self = self else { return }
    
    let currentSeconds = time.seconds
    
    // ALWAYS print first to see if callback fires
    print("⏱️ [Player] Observer fired: \(Int(currentSeconds))s (stored: \(Int(self.currentTime))s, diff: \(abs(self.currentTime - currentSeconds)))")
    
    // Only update if changed significantly (avoid excessive UI updates)
    if abs(self.currentTime - currentSeconds) > 0.1 {
        self.currentTime = currentSeconds
        print("✅ [Player] Updated currentTime: \(Int(currentSeconds))s / \(Int(self.duration))s")
    } else {
        // Log why we're not updating
        // print("⏸️ [Player] Skipped update - diff too small: \(abs(self.currentTime - currentSeconds))")
    }
    
    // Update Now Playing info
    self.updateNowPlayingInfo()
    
    // Update playback history every 10 seconds
    if self.currentTime - self.lastHistoryUpdate >= 10.0 {
        self.savePlaybackHistory()
        self.lastHistoryUpdate = self.currentTime
    }
}

print("✅ [Player] Time observer setup complete")
```

---

### Fix 2.7: Verify Audio Session Configuration

**File:** `GlobalPlayerManager.swift` or `EchoNotesApp.swift`

**Check if audio session is configured. If NOT found, add to GlobalPlayerManager.init():**

```swift
init() {
    print("🎵 [Player] GlobalPlayerManager initializing")
    
    setupAudioSession()
    setupRemoteCommandCenter()
    
    print("✅ [Player] GlobalPlayerManager initialized")
}

private func setupAudioSession() {
    print("🔊 [Player] Setting up audio session")
    
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(.playback, mode: .default, options: [])
        print("✅ [Player] Audio session category set to .playback")
        
        try audioSession.setActive(true)
        print("✅ [Player] Audio session activated")
        
    } catch {
        print("❌ [Player] Audio session setup failed: \(error.localizedDescription)")
    }
}
```

---

## TESTING PROCEDURE

### Test Part 1: "Works on 2nd Attempt" Fix

1. Clean build (Cmd+Shift+K)
2. Run app
3. Tap Find → Browse
4. Tap any podcast **ONCE** (first attempt)
5. Check console:

**Expected logs (WORKING):**
```
🔓 [Browse] Opening sheet for: NPR News
📊 [PodcastDetail] Task started for: NPR News
📡 [PodcastDetail] Loading episodes...
📡 [PodcastDetail] Fetching from: https://...
✅ [PodcastDetail] Fetched 50 episodes
✅ [PodcastDetail] UI updated with 50 episodes
✅ [PodcastDetail] Task completed - 50 episodes
```

**Verify:** Episodes appear on FIRST tap (no second tap needed)

---

### Test Part 2: Player Audio Fix

1. From browse, tap any episode
2. Player sheet opens
3. Tap play button
4. Check console:

**Expected logs (identify which pattern):**

**PATTERN A - Audio URL Invalid:**
```
❌ [Player] Invalid audio URL string: ...
```

**PATTERN B - Status Stuck at Unknown:**
```
✅ Valid audio URL: https://...
🔍 Created AVPlayerItem
⏳ Status: unknown - waiting...
(Never reaches readyToPlay)
```

**PATTERN C - Ready But Won't Play:**
```
✅ Status: readyToPlay
✅ Duration set: 180s
▶️ Play called
🔍 Player rate before: 0.0
🔍 Player rate after: 0.0  ← PROBLEM
⚠️ WARNING: Player rate is still 0.0 after 0.5s
```

**PATTERN D - Working:**
```
✅ Status: readyToPlay
✅ Duration set: 180s
▶️ Play called
🔍 Player rate after: 1.0  ← GOOD!
⏱️ Observer fired: 0s
⏱️ Observer fired: 1s
✅ Updated currentTime: 1s / 180s
```

5. Report which pattern you see

---

## EXPECTED OUTCOMES

### After Part 1:
- ✅ Podcasts load on first tap
- ✅ Episodes display immediately
- ✅ No more "blank sheet on first tap"
- ✅ Loading spinner shows while fetching

### After Part 2:
- ✅ Identify exact reason player won't play
- ✅ Console shows detailed diagnostics
- ✅ Pattern A/B/C/D tells us what to fix next

---

## COMMIT MESSAGES

After Part 1 works:
```
Fix: Use .task instead of .onAppear for reliable sheet data loading

- Replace .onAppear with .task in PodcastDetailView
- Ensure loadEpisodes() properly async with MainActor
- Add loading/error states with retry
- Remove double-nested DispatchQueue
- Episodes now load on first tap

Fixes "works on 2nd attempt" bug
```

After Part 2 diagnostics complete:
```
Debug: Add comprehensive player diagnostics

- Enhanced audio URL logging
- AVPlayerItem status tracking
- Error observer for player items
- Rate monitoring in play() function
- Time observer callback logging
- Audio session configuration

Prepares for player audio fix based on diagnostic pattern
```

---

## NEXT STEPS

**After running these fixes:**

1. Test Part 1 → Should fix "works on 2nd attempt" immediately
2. Test Part 2 → Will tell us which pattern (A/B/C/D)
3. Based on pattern, we create specific fix for player audio
4. Both issues resolved

---

**END OF COMBINED FIX GUIDE**
