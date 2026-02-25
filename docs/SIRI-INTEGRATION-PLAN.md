# Siri Integration: "Add Note at Current Time"
## Incremental Implementation Plan for Claude Code

**Branch:** `feature/siri-add-note`  
**Goal:** Enable "Hey Siri, add a note in EchoCast" to trigger a timestamped note capture with a dictated message and confirmation UI, mirroring the Messages app Siri flow.

**App context:**
- App target: `EchoNotes`
- App entry point: `EchoNotesApp.swift`
- Bundle ID: check `EchoNotes.xcodeproj` — you'll need the real bundle ID for the App Group suite name
- Persistence: `PersistenceController.shared`, Core Data with `NoteEntity`
- Player state: `GlobalPlayerManager.shared` (`currentTime: TimeInterval`, `isPlaying: Bool`)
- Note fields: `id`, `showTitle`, `episodeTitle`, `timestamp` (formatted String e.g. "4:32"), `noteText`, `isPriority`, `tags`, `createdAt`, `sourceApp`
- Design tokens: mint accent `#00c8b3`, dark green `#1a3c34`, use `Color.echoBackground`, `Color.mintAccent`, `EchoSpacing.screenPadding` etc.

---

## Before You Start

Create and check out the feature branch:

```bash
git checkout -b feature/siri-add-note
git push -u origin feature/siri-add-note
```

Work through each chunk sequentially. **Do not proceed to the next chunk until the checkpoint passes.**

---

## Chunk 1: App Group + Shared Player State

**Goal:** Write live player state to a shared UserDefaults container so the intent process can read it later. No intent yet — just the plumbing.

**Files to modify:** `GlobalPlayerManager.swift` only.

**Instructions:**

1. At the top of `GlobalPlayerManager.swift`, add a private constant:
   ```swift
   private let sharedDefaults = UserDefaults(suiteName: "group.com.echonotes.app202601302226.echocast")
   ```
   The suite name is: `group.com.echonotes.app202601302226.echocast`

2. Create a private method `writeSharedPlayerState()`:
   ```swift
   private func writeSharedPlayerState() {
       sharedDefaults?.set(currentTime, forKey: "siri_currentTime")
       sharedDefaults?.set(isPlaying, forKey: "siri_isPlaying")
       // Write episode info — read from whatever properties hold current episode
       // Adjust property names to match your actual GlobalPlayerManager properties:
       sharedDefaults?.set(currentEpisode?.title, forKey: "siri_episodeTitle")
       sharedDefaults?.set(currentPodcast?.title, forKey: "siri_podcastTitle")
       sharedDefaults?.set(currentEpisode?.audioURL, forKey: "siri_episodeID")
   }
   ```
   Adjust `currentEpisode` and `currentPodcast` to match the actual property names in `GlobalPlayerManager`. Use whatever uniquely identifies the episode (audio URL, Core Data object ID, etc.) for `siri_episodeID`.

3. Call `writeSharedPlayerState()` in two places:
   - Inside the time observer callback (already fires every 0.5s — just append the call)
   - Inside `loadEpisode()` (or equivalent) after a new episode is set

4. Add a temporary **debug label** to `HomeView.swift` inside the main VStack (anywhere visible) so we can verify the shared defaults are being written:
   ```swift
   // TEMPORARY DEBUG — remove after Chunk 1 checkpoint passes
   if let time = UserDefaults(suiteName: "group.com.echonotes.app202601302226.echocast")?.double(forKey: "siri_currentTime"),
      let title = UserDefaults(suiteName: "group.com.echonotes.app202601302226.echocast")?.string(forKey: "siri_episodeTitle") {
       Text("Shared state: \(title) @ \(Int(time))s")
           .font(.caption2)
           .foregroundColor(.secondary)
           .padding(.top, 4)
   }
   ```

5. **Add the App Group entitlement** — this requires a manual Xcode step that Claude Code cannot do:
   - In Xcode → select `EchoNotes` target → Signing & Capabilities → + Capability → App Groups
   - Add group: `group.com.echonotes.app202601302226.echocast`
   - ⚠️ Claude Code: output a reminder message telling the user to do this manually before testing.

6. Build. Fix any compile errors.

**Commit message:** `feat: write player state to App Group UserDefaults for Siri`

---

### ✅ CHECKPOINT 1 — STOP AND WAIT FOR USER

Output this message and stop:

```
CHECKPOINT 1 COMPLETE

Before I continue, please do the following:

1. In Xcode → EchoNotes target → Signing & Capabilities → + Capability → App Groups
   Add: group.[YOUR_BUNDLE_ID].echocast
   (Make sure the suite name in GlobalPlayerManager.swift matches exactly)

2. Build and run the app on a real device or simulator.

3. Start playing any podcast episode.

4. Check HomeView — you should see a small debug label like:
   "Shared state: My Podcast Episode @ 42s"
   ...and it should update as the episode plays.

Reply "checkpoint 1 passed" when the debug label appears and updates correctly.
Reply "checkpoint 1 failed" with a description of what you see if it doesn't work.

DO NOT proceed to Chunk 2 until this checkpoint passes.
```

---

## Chunk 2: Bare-Minimum Intent + Siri Phrase Registration

**Goal:** Create the intent and shortcut registration so Siri can invoke EchoCast. The intent will only read shared state and speak a confirmation — no note saving yet. This proves the Siri → intent → shared state pipeline works.

**Files to create:**
- `EchoNotes/Intents/AddNoteAtCurrentTimeIntent.swift`
- `EchoNotes/Intents/EchoCastShortcuts.swift`

**Files to modify:**
- `EchoNotesApp.swift`

**Instructions:**

1. Create folder `EchoNotes/Intents/` if it doesn't exist.

2. Create `AddNoteAtCurrentTimeIntent.swift`:
   ```swift
   import AppIntents

   struct AddNoteAtCurrentTimeIntent: AppIntent {
       static var title: LocalizedStringResource = "Add Note at Current Time"
       static var description = IntentDescription(
           "Adds a timestamped note to the currently playing podcast episode in EchoCast."
       )
       static var openAppWhenRun: Bool = false

       func perform() async throws -> some IntentResult & ProvidesDialog {
           let sharedDefaults = UserDefaults(suiteName: "group.com.echonotes.app202601302226.echocast")
           let timestamp = sharedDefaults?.double(forKey: "siri_currentTime") ?? 0
           let episodeTitle = sharedDefaults?.string(forKey: "siri_episodeTitle") ?? ""
           let isPlaying = sharedDefaults?.bool(forKey: "siri_isPlaying") ?? false

           guard isPlaying || timestamp > 0 else {
               return .result(dialog: "No podcast is currently playing in EchoCast.")
           }

           let formattedTime = formatTime(timestamp)
           return .result(dialog: "EchoCast is at \(formattedTime) in \(episodeTitle). Note saving coming soon.")
       }

       private func formatTime(_ seconds: TimeInterval) -> String {
           let mins = Int(seconds) / 60
           let secs = Int(seconds) % 60
           return String(format: "%d:%02d", mins, secs)
       }
   }
   ```

3. Create `EchoCastShortcuts.swift`:
   ```swift
   import AppIntents

   struct EchoCastShortcuts: AppShortcutsProvider {
       static var appShortcuts: [AppShortcut] {
           AppShortcut(
               intent: AddNoteAtCurrentTimeIntent(),
               phrases: [
                   "Add a note in \(.applicationName)",
                   "Add note at current time in \(.applicationName)",
                   "Note this in \(.applicationName)",
                   "Capture this in \(.applicationName)",
                   "Timestamp this in \(.applicationName)"
               ],
               shortTitle: "Add Podcast Note",
               systemImageName: "note.text.badge.plus"
           )
       }
   }
   ```

4. In `EchoNotesApp.swift`, inside the `App` struct, add an `.onAppear` to the `WindowGroup` (or in `init()`) to register shortcuts:
   ```swift
   .onAppear {
       EchoCastShortcuts.updateAppShortcutParameters()
   }
   ```
   Place this alongside the existing `.onAppear` call if one already exists — don't create a duplicate modifier. Just append `EchoCastShortcuts.updateAppShortcutParameters()` inside the existing `setupApp()` or `.onAppear` block.

5. Build. Fix any compile errors.

**Commit message:** `feat: add bare-minimum Siri intent and shortcut registration`

---

### ✅ CHECKPOINT 2 — STOP AND WAIT FOR USER

Output this message and stop:

```
CHECKPOINT 2 COMPLETE

Please test on a REAL DEVICE (Siri does not work reliably in Simulator):

1. Build and run on your iPhone.
2. Start playing any podcast episode in EchoCast.
3. Say: "Hey Siri, add a note in EchoCast"
4. Siri should respond with something like:
   "EchoCast is at 4:32 in [episode name]. Note saving coming soon."

If Siri says it doesn't know the phrase, wait ~30 seconds after launch and try again
(shortcut registration can take a moment).

Reply "checkpoint 2 passed" when Siri responds with the timestamp.
Reply "checkpoint 2 failed" with what Siri said if it doesn't work.

DO NOT proceed to Chunk 3 until this checkpoint passes.
```

---

## Chunk 3: Core Data Note Save from Intent (Silent Capture Complete)

**Goal:** Wire up the actual note save inside `perform()`. After this chunk, saying the Siri phrase saves a blank timestamped note to Core Data. This is the full "silent capture" feature.

**Files to modify:** `AddNoteAtCurrentTimeIntent.swift` only.

**Instructions:**

1. Replace the `perform()` body in `AddNoteAtCurrentTimeIntent.swift` with:
   ```swift
   func perform() async throws -> some IntentResult & ProvidesDialog {
       let sharedDefaults = UserDefaults(suiteName: "group.com.echonotes.app202601302226.echocast")
       let timestamp = sharedDefaults?.double(forKey: "siri_currentTime") ?? 0
       let episodeTitle = sharedDefaults?.string(forKey: "siri_episodeTitle") ?? ""
       let podcastTitle = sharedDefaults?.string(forKey: "siri_podcastTitle") ?? ""
       let isPlaying = sharedDefaults?.bool(forKey: "siri_isPlaying") ?? false

       guard isPlaying || timestamp > 0 else {
           return .result(dialog: "No podcast is currently playing in EchoCast.")
       }

       // Save note to Core Data
       let context = PersistenceController.shared.container.viewContext
       await context.perform {
           let note = NoteEntity(context: context)
           note.id = UUID()
           note.episodeTitle = episodeTitle
           note.showTitle = podcastTitle
           note.timestamp = self.formatTime(timestamp)
           note.noteText = ""   // blank — user can edit in app
           note.isPriority = false
           note.tags = ""
           note.createdAt = Date()
           note.sourceApp = "Siri"

           do {
               try context.save()
           } catch {
               print("❌ [Siri Intent] Failed to save note: \(error)")
           }
       }

       let formattedTime = formatTime(timestamp)
       return .result(dialog: "Note saved at \(formattedTime) in \(episodeTitle). Open EchoCast to add details.")
   }
   ```

2. Build. Fix any compile errors. Pay attention to `NoteEntity` field names — verify they match the actual Core Data model (cross-reference `EchoNotes.xcdatamodeld`). Adjust field names if needed.

**Commit message:** `feat: save timestamped NoteEntity from Siri intent (silent capture)`

---

### ✅ CHECKPOINT 3 — STOP AND WAIT FOR USER

Output this message and stop:

```
CHECKPOINT 3 COMPLETE — Silent Capture is fully working.

Please test on your real device:

1. Start playing a podcast episode.
2. Say: "Hey Siri, add a note in EchoCast"
3. Siri should confirm: "Note saved at [timestamp] in [episode name]."
4. Open EchoCast → Library/Notes → verify a new note appears with:
   - Correct episode title
   - Correct timestamp
   - Empty note text
   - sourceApp = "Siri"

Also verify the note appears in the Home screen's recent notes section if applicable.

Reply "checkpoint 3 passed" when you can see the note in the app.
Reply "checkpoint 3 failed" with what went wrong.

At this point you can also remove the temporary debug label from HomeView.swift
that was added in Chunk 1 — it's no longer needed.

DO NOT proceed to Chunk 4 until this checkpoint passes.
```

---

## Chunk 4: Dictated Note Content via `@Parameter`

**Goal:** Add a `noteContent` parameter so Siri asks "What's your note?" after the trigger phrase. The dictated text gets saved as the note body instead of leaving it blank.

**Files to modify:** `AddNoteAtCurrentTimeIntent.swift` only.

**Instructions:**

1. Add the `@Parameter` property to the intent struct (before `perform()`):
   ```swift
   @Parameter(
       title: "Note",
       requestValueDialog: IntentDialog("What's your note?")
   )
   var noteContent: String
   ```

2. In `perform()`, replace `note.noteText = ""` with:
   ```swift
   note.noteText = noteContent
   ```

3. Update the confirmation dialog to include the dictated content:
   ```swift
   return .result(dialog: "Saved: \"\(noteContent)\" at \(formattedTime).")
   ```

4. Build. Fix any compile errors.

**Commit message:** `feat: add @Parameter so Siri prompts for note content via dictation`

---

### ✅ CHECKPOINT 4 — STOP AND WAIT FOR USER

Output this message and stop:

```
CHECKPOINT 4 COMPLETE

Please test on your real device:

1. Start playing a podcast episode.
2. Say: "Hey Siri, add a note in EchoCast"
3. Siri should ask: "What's your note?"
4. Dictate something, e.g. "This is a really interesting point about AI"
5. Siri should confirm: "Saved: 'This is a really interesting point about AI' at 4:32."
6. Open EchoCast → verify the note has the correct text, timestamp, and episode title.

Reply "checkpoint 4 passed" when dictated notes appear correctly.
Reply "checkpoint 4 failed" with what went wrong.

DO NOT proceed to Chunk 5 until this checkpoint passes.
```

---

## Chunk 5: Custom Snippet View (Visual Preview)

**Goal:** Add a SwiftUI snippet view that Siri renders as a visual card when confirming the save. This replaces the plain text Siri response with a branded EchoCast UI overlay.

**Files to create:** `EchoNotes/Intents/NoteSnippetView.swift`

**Files to modify:** `AddNoteAtCurrentTimeIntent.swift`

**Instructions:**

1. Create `NoteSnippetView.swift`:
   ```swift
   import SwiftUI

   // Siri snippet view — must be lightweight, no async loading, no @State
   struct NoteSnippetView: View {
       let noteContent: String
       let timestamp: String        // pre-formatted e.g. "4:32"
       let episodeTitle: String
       let podcastTitle: String
       let isSaved: Bool            // false = confirming, true = saved

       var body: some View {
           VStack(alignment: .leading, spacing: 10) {

               // Podcast context header
               HStack(spacing: 6) {
                   Image(systemName: "waveform")
                       .font(.system(size: 12, weight: .medium))
                       .foregroundColor(Color(hex: "#00c8b3"))
                   Text(podcastTitle)
                       .font(.system(size: 12))
                       .foregroundColor(.secondary)
                       .lineLimit(1)
               }

               // Episode title
               Text(episodeTitle)
                   .font(.system(size: 14, weight: .semibold))
                   .foregroundColor(.primary)
                   .lineLimit(2)

               // Timestamp badge
               HStack(spacing: 4) {
                   Image(systemName: "clock")
                       .font(.system(size: 11))
                   Text(timestamp)
                       .font(.system(size: 12, weight: .semibold, design: .monospaced))
               }
               .foregroundColor(Color(hex: "#00c8b3"))
               .padding(.horizontal, 8)
               .padding(.vertical, 3)
               .background(Color(hex: "#00c8b3").opacity(0.15))
               .cornerRadius(6)

               // Divider
               Rectangle()
                   .fill(Color.secondary.opacity(0.2))
                   .frame(height: 1)

               // Note content
               Text(noteContent.isEmpty ? "Tap to add details..." : noteContent)
                   .font(.system(size: 15))
                   .foregroundColor(noteContent.isEmpty ? .secondary : .primary)
                   .fixedSize(horizontal: false, vertical: true)
                   .lineLimit(4)

               // Footer status
               HStack(spacing: 4) {
                   Spacer()
                   if isSaved {
                       Image(systemName: "checkmark.circle.fill")
                           .foregroundColor(Color(hex: "#00c8b3"))
                           .font(.system(size: 12))
                       Text("Saved to EchoCast")
                           .font(.system(size: 11))
                           .foregroundColor(.secondary)
                   } else {
                       Text("Saving to EchoCast...")
                           .font(.system(size: 11))
                           .foregroundColor(.secondary)
                   }
               }
           }
           .padding(14)
           .frame(maxWidth: .infinity, alignment: .leading)
       }
   }

   // Hex color helper (only if not already defined globally in the project)
   // If Color(hex:) is already available via EchoCastDesignTokens, delete this extension
   private extension Color {
       init(hex: String) {
           let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
           var int: UInt64 = 0
           Scanner(string: hex).scanHexInt64(&int)
           let r = Double((int >> 16) & 0xFF) / 255
           let g = Double((int >> 8) & 0xFF) / 255
           let b = Double(int & 0xFF) / 255
           self.init(red: r, green: g, blue: b)
       }
   }
   ```
   **Important:** If `Color(hex:)` is already defined elsewhere in the project (check `EchoCastDesignTokens.swift`), delete the private extension above to avoid a duplicate symbol error.

2. Update `AddNoteAtCurrentTimeIntent.swift` — change the `perform()` return type and return value to include the snippet:
   ```swift
   // Change return type from:
   func perform() async throws -> some IntentResult & ProvidesDialog
   // To:
   func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView
   ```

   Update the final return statement:
   ```swift
   return .result(
       dialog: "Saved: \"\(noteContent)\" at \(formattedTime).",
       view: NoteSnippetView(
           noteContent: noteContent,
           timestamp: formattedTime,
           episodeTitle: episodeTitle,
           podcastTitle: podcastTitle,
           isSaved: true
       )
   )
   ```

3. Build. Fix any compile errors.

**Commit message:** `feat: add NoteSnippetView for visual Siri confirmation card`

---

### ✅ CHECKPOINT 5 — STOP AND WAIT FOR USER

Output this message and stop:

```
CHECKPOINT 5 COMPLETE

Please test on your real device:

1. Start playing a podcast episode.
2. Say: "Hey Siri, add a note in EchoCast"
3. Dictate a note when prompted.
4. After confirmation, Siri should show a visual card with:
   - Podcast name and waveform icon
   - Episode title
   - Mint-colored timestamp badge
   - Your dictated note text
   - "Saved to EchoCast" with a checkmark

The card renders inside Siri's overlay — it will appear above Siri's button row.

Reply "checkpoint 5 passed" when the visual card appears correctly.
Reply "checkpoint 5 failed" with a description or screenshot of what you see.

DO NOT proceed to Chunk 6 until this checkpoint passes.
```

---

## Chunk 6: Confirmation + Auto-Countdown (Messages-Style)

**Goal:** Add `requestConfirmation()` so Siri shows a preview of the note *before* saving, with an auto-countdown button that mirrors the Messages app UX. User can cancel within the window or let it auto-confirm.

**Files to modify:** `AddNoteAtCurrentTimeIntent.swift` only.

**Instructions:**

1. In `perform()`, split the flow into two stages — confirmation then save. Replace the entire `perform()` body with:

   ```swift
   func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
       let sharedDefaults = UserDefaults(suiteName: "group.com.echonotes.app202601302226.echocast")
       let timestamp = sharedDefaults?.double(forKey: "siri_currentTime") ?? 0
       let episodeTitle = sharedDefaults?.string(forKey: "siri_episodeTitle") ?? ""
       let podcastTitle = sharedDefaults?.string(forKey: "siri_podcastTitle") ?? ""
       let isPlaying = sharedDefaults?.bool(forKey: "siri_isPlaying") ?? false

       guard isPlaying || timestamp > 0 else {
           return .result(dialog: "No podcast is currently playing in EchoCast.")
       }

       let formattedTime = formatTime(timestamp)

       // Stage 1: Show confirmation preview with countdown
       // Siri auto-confirms after ~3 seconds (system controlled)
       try await requestConfirmation(
           result: .result(
               dialog: "Ready to save this note at \(formattedTime)?",
               view: NoteSnippetView(
                   noteContent: noteContent,
                   timestamp: formattedTime,
                   episodeTitle: episodeTitle,
                   podcastTitle: podcastTitle,
                   isSaved: false   // "Saving..." state
               )
           )
       )

       // Stage 2: User confirmed (or countdown elapsed) — save the note
       let context = PersistenceController.shared.container.viewContext
       await context.perform {
           let note = NoteEntity(context: context)
           note.id = UUID()
           note.episodeTitle = episodeTitle
           note.showTitle = podcastTitle
           note.timestamp = formattedTime
           note.noteText = self.noteContent
           note.isPriority = false
           note.tags = ""
           note.createdAt = Date()
           note.sourceApp = "Siri"

           do {
               try context.save()
           } catch {
               print("❌ [Siri Intent] Failed to save note: \(error)")
           }
       }

       // Stage 3: Show saved confirmation
       return .result(
           dialog: "Note saved.",
           view: NoteSnippetView(
               noteContent: noteContent,
               timestamp: formattedTime,
               episodeTitle: episodeTitle,
               podcastTitle: podcastTitle,
               isSaved: true   // "Saved ✓" state
           )
       )
   }
   ```

2. Build. Fix any compile errors.

**Commit message:** `feat: add requestConfirmation for Messages-style Siri countdown UX`

---

### ✅ CHECKPOINT 6 (FINAL) — STOP AND WAIT FOR USER

Output this message and stop:

```
CHECKPOINT 6 COMPLETE — Full Siri flow implemented! 🎉

Please test the complete end-to-end flow on your real device:

1. Start playing a podcast episode.
2. Say: "Hey Siri, add a note in EchoCast"
3. Siri asks: "What's your note?"
4. Dictate: "This is a great point about [topic]"
5. Siri shows a PREVIEW card (isSaved: false) with countdown button:
   - The note content, timestamp badge, episode context
   - "Saving to EchoCast..." footer
   - Siri's native auto-confirm countdown button below
6. After countdown (or tap to confirm):
   - Card transitions to saved state (isSaved: true, checkmark appears)
   - Siri says "Note saved."
7. Open EchoCast → verify the note has correct text, timestamp, and episode info.

If everything passes, you're ready to merge:

git checkout main
git merge feature/siri-add-note
git push

Reply "all checkpoints passed" when the full flow works end-to-end.
Reply "checkpoint 6 failed" with what went wrong.
```

---

## Known Constraints & Gotchas

**Siri doesn't work in Simulator** — test all Siri-facing chunks (2+) on a real device.

**App Group suite name must match exactly** — a typo here silently breaks shared state reads. The suite name in `GlobalPlayerManager.swift` and in `AddNoteAtCurrentTimeIntent.swift` must be identical character-for-character.

**`Color(hex:)` duplicate** — `NoteSnippetView.swift` includes a private Color(hex:) extension. If your codebase already defines this (likely in `EchoCastDesignTokens.swift`), delete the one in NoteSnippetView or you'll get a build error.

**Shortcut phrase registration lag** — after first install with shortcuts, Siri may take 30–60 seconds to learn the phrases. If Siri says "I don't know how to help with that," wait and try again.

**Intent runs in a separate process** — `GlobalPlayerManager.shared` is not accessible from within the intent. This is why we use App Group UserDefaults as the bridge. Never try to reference the singleton directly from `perform()`.

**`requestConfirmation()` countdown duration** — this is system-controlled (approximately 3 seconds), matching Messages. You cannot change the duration.

**Core Data context threading** — always use `await context.perform { }` when saving from an async intent context. Never call Core Data on an arbitrary thread.
