# T22 — CarPlay "Add Note at Current Time" Button

**Branch:** `t22-carplay-add-note`  
**Priority:** P1  
**LOE:** M  

---

## Overview

Add CarPlay support to EchoCast from scratch. The CarPlay interface will show a recently-played episodes list and expose the `CPNowPlayingTemplate` during playback. A custom **"Add Note"** button in the Now Playing button row (same placement as Overcast's chapter/sleep buttons, Spotify's shuffle/repeat) triggers `AddNoteIntent` programmatically, surfacing a Siri dialog on the iPhone so the user can dictate a note hands-free.

---

## Architecture

### New files
| File | Purpose |
|------|---------|
| `CarPlaySceneDelegate.swift` | `CPTemplateApplicationSceneDelegate` — full CarPlay lifecycle |
| `CarPlayNowPlayingController.swift` | Manages `CPNowPlayingTemplate` buttons, keeps button state in sync with `GlobalPlayerManager` |

### Modified files
| File | Change |
|------|--------|
| `EchoNotes.entitlements` | Add `com.apple.developer.carplay-audio` entitlement |
| `Info.plist` | Add CarPlay `UISceneConfiguration` entry |
| `AppDelegate.swift` (or `EchoNotesApp.swift`) | Register CarPlay scene config if needed |

### Data flow
```
CarPlay button tap
  → CarPlayNowPlayingController.handleAddNoteTap()
  → Task { @MainActor in try await AddNoteIntent().perform() }
  → Siri dialog appears on iPhone
  → Note saved via PersistenceController with current timestamp from GlobalPlayerManager
  → CPAlertTemplate confirmation briefly shown in CarPlay ("Note saved at 12:34")
```

### Recently played list
```
CarPlaySceneDelegate.templateApplicationScene(_:didConnect:)
  → Reads PlaybackHistoryManager.shared.recentlyPlayed
  → Builds CPListTemplate with one CPListItem per episode
  → Tapping an item loads episode into GlobalPlayerManager → CPNowPlayingTemplate shown
```

---

## CarPlay UI Spec

### Home screen — `CPListTemplate`
- Title: "EchoCast"
- Section header: "Recently Played"
- Each row: episode title (primary text) + podcast name (secondary text) + artwork image
- Empty state: single item "No recent episodes" (non-interactive)
- Max items: 10 (CarPlay list performance best practice)

### Now Playing button row — `CPNowPlayingTemplate`
- One custom button: `CPNowPlayingImageButton`
  - Icon: SF Symbol `square.and.pencil` (matches the note-taking theme)
  - Displayed below the scrubber alongside any future buttons
  - Handler: calls `CarPlayNowPlayingController.handleAddNoteTap()`

### Post-tap feedback
- `CPAlertTemplate` with title "Note capture started" shown for ~1.5s, then auto-dismissed
- iPhone: Siri dialog opens via `AddNoteIntent().perform()`

---

## Implementation Notes

### Entitlement
The `com.apple.developer.carplay-audio` key must be added to:
1. `EchoNotes.entitlements` (boolean YES)
2. The provisioning profile in developer.apple.com — **manual step required outside Xcode**

### Info.plist scene config
CarPlay requires a separate `UISceneConfiguration` in `UIApplicationSceneManifest`:
```xml
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <!-- existing iPhone scene config stays untouched -->
        <key>CPTemplateApplicationSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneClassName</key>
                <string>CPTemplateApplicationScene</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate</string>
                <key>UISceneConfigurationName</key>
                <string>CarPlay Configuration</string>
            </dict>
        </array>
    </dict>
</dict>
```

### Invoking AddNoteIntent from CarPlay
```swift
// Inside CarPlayNowPlayingController
func handleAddNoteTap() {
    Task { @MainActor in
        do {
            _ = try await AddNoteIntent().perform()
        } catch {
            // Show CPAlertTemplate error fallback
            showCarPlayAlert("Couldn't start note capture")
        }
    }
}
```
`AddNoteIntent` already has `openAppWhenRun: Bool = true` — verify this brings the iPhone app to foreground so the Siri dialog is visible.

### CPNowPlayingTemplate button registration
```swift
// In CarPlayNowPlayingController.setupNowPlayingButtons()
let noteButton = CPNowPlayingImageButton(
    image: UIImage(systemName: "square.and.pencil")!
) { [weak self] _ in
    self?.handleAddNoteTap()
}
CPNowPlayingTemplate.shared.updateNowPlayingButtons([noteButton])
```

### GlobalPlayerManager observation
`CarPlayNowPlayingController` should observe `GlobalPlayerManager.shared.$currentEpisode` to:
- Show/hide `CPNowPlayingTemplate` based on whether something is playing
- Keep the recently-played list fresh after playback starts

### Thread safety
All `CPTemplate` mutations must happen on the **main thread**. Use `DispatchQueue.main.async` or `@MainActor` throughout `CarPlaySceneDelegate` and `CarPlayNowPlayingController`.

---

## Constraints & Guardrails

- Do **not** modify `ContentView.swift`, `GlobalPlayerManager.swift`, or any existing sheet presentation logic
- Do **not** create additional templates beyond `CPListTemplate` (home) and `CPNowPlayingTemplate` (auto) for this task
- Do **not** add CarPlay-specific persistence or data models — reuse `PlaybackHistoryManager` and `PersistenceController` as-is
- `CPNowPlayingTemplate.shared` is a singleton — only configure buttons once; re-registering on every playback event causes flicker
- CarPlay simulator in Xcode: I/O → External Displays → CarPlay for testing without hardware

---

## Phase 1 — Diagnosis prompt (read-only, stop and report)

```
Read docs/TODO.md first.

DIAGNOSIS ONLY — do not modify any files.

Search the codebase and report back on the following. Use targeted grep, do not open files speculatively.

1. grep -r "carplay\|CarPlay\|CPTemplate\|CPNowPlaying\|CPInterfaceController" --include="*.swift" --include="*.plist" --include="*.entitlements" -l
   Report every file path found.

2. cat EchoNotes/EchoNotes.entitlements (or equivalent — find the .entitlements file first)
   Report full contents.

3. grep -A5 -B5 "UISceneConfigurations\|UIApplicationSceneManifest" EchoNotes/Info.plist
   Report the scene configuration block.

4. grep -n "AddNoteIntent\|perform()" EchoNotes/AppIntents/AddNoteIntent.swift
   Report the full perform() signature and openAppWhenRun value.

5. grep -n "PlaybackHistoryManager\|recentlyPlayed" EchoNotes/PlaybackHistoryManager.swift | head -30
   Report the recentlyPlayed property type and PlaybackHistoryItem struct fields.

6. grep -n "BannerView\|showBanner" EchoNotes/Components/BannerView.swift | head -20
   Report the public interface for triggering a banner.

Stop here and report all findings. Do not implement anything.
```

---

## Phase 2 — Implementation prompt

```
Read docs/TODO.md first.

Implement T22: CarPlay "Add Note at Current Time" button. Reference the spec at docs/T22-CarPlay-AddNote.md.

Use the diagnosis findings from Phase 1 to inform exact file paths and existing API signatures.

STEP 1 — Entitlement
In EchoNotes/EchoNotes.entitlements, add:
    <key>com.apple.developer.carplay-audio</key>
    <true/>

STEP 2 — Info.plist scene config
In EchoNotes/Info.plist, inside the existing UISceneConfigurations dict, add a new key:
    CPTemplateApplicationSceneSessionRoleApplication
with an array containing one dict as specified in the T22 spec doc.
Do not remove or modify the existing iPhone UIWindowSceneSessionRoleApplication entry.

STEP 3 — Create CarPlaySceneDelegate.swift
File: EchoNotes/CarPlay/CarPlaySceneDelegate.swift

Implement CPTemplateApplicationSceneDelegate:
- templateApplicationScene(_:didConnect:) — build CPListTemplate from PlaybackHistoryManager.shared.recentlyPlayed (max 10 items), set as root template
- Each CPListItem: primaryText = episode title, secondaryText = podcast title, image = nil (artwork async loading is out of scope)
- Item tap handler: load episode into GlobalPlayerManager, push CPNowPlayingTemplate.shared
- templateApplicationScene(_:didDisconnect:) — clean up
- Call CarPlayNowPlayingController.shared.setup(interfaceController:) from didConnect

STEP 4 — Create CarPlayNowPlayingController.swift
File: EchoNotes/CarPlay/CarPlayNowPlayingController.swift

Implement as a class (not struct) with a shared singleton:
- setup(interfaceController:) — stores reference, calls setupNowPlayingButtons(), begins observing GlobalPlayerManager.$currentEpisode via Combine
- setupNowPlayingButtons() — creates CPNowPlayingImageButton with SF Symbol "square.and.pencil", calls CPNowPlayingTemplate.shared.updateNowPlayingButtons([noteButton])
- handleAddNoteTap() — Task { @MainActor in try await AddNoteIntent().perform() }, on error show CPAlertTemplate with message "Couldn't start note capture"
- showCarPlayAlert(_:) — creates CPAlertTemplate, presents via interfaceController, auto-dismiss after 1.5s
- Observation: when currentEpisode becomes non-nil, push CPNowPlayingTemplate.shared if not already on stack

All CP* API calls must be dispatched on DispatchQueue.main.

STEP 5 — Verify build
Confirm no compilation errors. Do not fix issues in unrelated files.

When complete:
- Update docs/TODO.md: mark T22 as complete with commit ID
- Add any discovered issues to the Inbox section only, do not fix inline

Do not create additional files, structs, extensions, or templates beyond what is specified above.
Stop after Step 5 and report what was changed.
```

---

## Manual step required (outside Xcode)

After implementation, before testing on device:
1. Go to developer.apple.com → Certificates, IDs & Profiles → Identifiers → `com.kai.echocast`
2. Enable **CarPlay Audio** capability
3. Regenerate and download the provisioning profile
4. In Xcode: Signing & Capabilities → select the updated profile

CarPlay Simulator testing (no hardware needed):
- Run on iPhone Simulator → Xcode menu: I/O → External Displays → CarPlay
