TASK: Diagnose Why Player Won't Play Audio

Confirmed issue: Player rate stays 0.0 after play() is called

Focus: Find why AVPlayer won't start playback

═══════════════════════════════════════════════════════════

FILE: GlobalPlayerManager.swift

Add diagnostics to loadEpisode() function:

1. After getting audioURL (around line 150-170):
```swift
guard let audioURL = URL(string: audioURLString) else {
    print("❌ [Player] Invalid audio URL: \(audioURLString)")
    return
}
print("✅ [Player] Valid audio URL: \(audioURL)")
print("🔍 [Player] URL scheme: \(audioURL.scheme ?? "none")")
print("🔍 [Player] URL is file: \(audioURL.isFileURL)")
```

2. After creating AVPlayerItem (around line 210):
```swift
let playerItem = AVPlayerItem(url: audioURL)
print("🔍 [Player] Created AVPlayerItem")
print("🔍 [Player] Item status immediately: \(playerItem.status.rawValue)")

// Add error observer
playerItem.publisher(for: \.error)
    .sink { error in
        if let error = error {
            print("❌ [Player] Item error: \(error.localizedDescription)")
        }
    }
    .store(in: &cancellables)
```

3. In the status observer (around line 210-243), enhance logging:
```swift
playerItem.publisher(for: \.status)
    .sink { [weak self] status in
        print("🔍 [Player] Status: \(status.rawValue) (\(self?.statusString(status) ?? "unknown"))")
        
        switch status {
        case .unknown:
            print("⏳ [Player] Status: unknown - waiting...")
        case .readyToPlay:
            print("✅ [Player] Status: readyToPlay")
            let duration = CMTimeGetSeconds(playerItem.duration)
            if duration.isFinite && duration > 0 {
                await MainActor.run {
                    self?.duration = duration
                    print("✅ [Player] Duration set: \(Int(duration))s")
                }
            } else {
                print("⚠️ [Player] Duration not available: \(duration)")
            }
        case .failed:
            print("❌ [Player] Status: FAILED")
            if let error = playerItem.error {
                print("❌ [Player] Error: \(error.localizedDescription)")
                print("❌ [Player] Error code: \((error as NSError).code)")
                print("❌ [Player] Error domain: \((error as NSError).domain)")
            }
        @unknown default:
            print("⚠️ [Player] Unknown status")
        }
    }
    .store(in: &cancellables)
```

4. Add helper function:
```swift
private func statusString(_ status: AVPlayerItem.Status) -> String {
    switch status {
    case .unknown: return "unknown"
    case .readyToPlay: return "readyToPlay"
    case .failed: return "FAILED"
    @unknown default: return "unknown default"
    }
}
```

5. In play() function, add pre-flight checks:
```swift
func play() {
    print("▶️ [Player] Play called")
    
    guard let player = player else {
        print("❌ [Player] No player exists")
        return
    }
    
    guard let item = player.currentItem else {
        print("❌ [Player] No current item")
        return
    }
    
    print("🔍 [Player] Item status before play: \(statusString(item.status))")
    
    if item.status != .readyToPlay {
        print("⚠️ [Player] Item not ready to play! Status: \(statusString(item.status))")
        if let error = item.error {
            print("❌ [Player] Item error: \(error.localizedDescription)")
        }
    }
    
    print("🔍 [Player] Player rate before: \(player.rate)")
    player.play()
    isPlaying = true
    print("🔍 [Player] Player rate after: \(player.rate)")
    
    // Check after small delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        print("🔍 [Player] Player rate after 0.5s: \(player.rate)")
    }
    
    updateNowPlayingInfo()
}
```

═══════════════════════════════════════════════════════════

TESTING PROCEDURE:

1. Clean build
2. Run app
3. Play any episode
4. Watch console carefully

Expected patterns:

PATTERN A - Audio URL invalid:
✅ Valid audio URL: https://...
❌ [Player] Item status: FAILED
❌ Error: Cannot decode

PATTERN B - Status stuck at unknown:
✅ Valid audio URL: https://...
🔍 Status: 0 (unknown)
⏳ Status: unknown - waiting...
(Never reaches readyToPlay)

PATTERN C - Ready but won't play:
✅ Status: readyToPlay
✅ Duration set: 180s
▶️ Play called
🔍 Player rate before: 0.0
🔍 Player rate after: 0.0  ← PROBLEM
🔍 Player rate after 0.5s: 0.0  ← Still 0

PATTERN D - Audio session issue:
✅ Status: readyToPlay
▶️ Play called
🔍 Player rate after: 1.0
(But no audio output)

═══════════════════════════════════════════════════════════

ALSO CHECK:

Audio session configuration (should be in app startup):
```swift
let audioSession = AVAudioSession.sharedInstance()
do {
    try audioSession.setCategory(.playback, mode: .default)
    try audioSession.setActive(true)
    print("✅ Audio session configured")
} catch {
    print("❌ Audio session failed: \(error)")
}
```

Is this being called? Check in EchoNotesApp.swift or GlobalPlayerManager.init

═══════════════════════════════════════════════════════════

OUTPUT: Update docs/player-time-debug.md

Section: Why Player Won't Play - Root Cause
- Full console log from play attempt
- Which pattern matched (A/B/C/D)
- Exact error messages if any
- Audio URL that failed
- Item status progression
- Player rate values

Next step depends on pattern found.