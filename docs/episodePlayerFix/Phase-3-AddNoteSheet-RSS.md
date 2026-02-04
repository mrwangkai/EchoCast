# Phase 3: Create RSS-based AddNoteSheet

## Problem
Current `AddNoteSheet` expects:
- iTunes models: `PodcastEpisode`, `iTunesPodcast`
- Local state: `@Bindable var playerState: PlayerState`

But `EpisodePlayerView` uses:
- RSS models: `RSSEpisode`, `PodcastEntity`
- Shared state: `GlobalPlayerManager.shared`

## Solution
Create a new `AddNoteSheetRSS.swift` that works with RSS models and GlobalPlayerManager.

---

## Step 1: Create AddNoteSheetRSS.swift

**Create new file:** `/Views/AddNoteSheetRSS.swift`

```swift
//
//  AddNoteSheetRSS.swift
//  EchoNotes
//
//  Note capture sheet for RSS/Core Data models with GlobalPlayerManager
//

import SwiftUI
import CoreData

// MARK: - Add Note Sheet (RSS Models)

struct AddNoteSheetRSS: View {
    // Episode and podcast info (RSS models)
    let episode: RSSEpisode
    let podcast: PodcastEntity
    
    // Optional: Pre-filled timestamp (for "Add note at current time" button)
    let timestamp: TimeInterval?
    
    // Player state from GlobalPlayerManager
    @ObservedObject private var player = GlobalPlayerManager.shared
    
    // UI state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var noteContent = ""
    @State private var tagsInput = ""
    @State private var isPriority = false
    
    // Computed timestamp
    private var currentTimestamp: TimeInterval {
        timestamp ?? player.currentTime
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with episode info
                    episodeHeaderSection
                    
                    // Timestamp display
                    timestampSection
                    
                    // Note content input
                    noteContentSection
                    
                    // Tags input
                    tagsSection
                    
                    // Priority toggle
                    prioritySection
                    
                    // Save button
                    saveButton
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
                .padding(.top, 24)
            }
            .background(Color.echoBackground)
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.echoTextSecondary)
                }
            }
        }
    }
    
    // MARK: - Episode Header Section
    
    private var episodeHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(episode.title)
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(2)
            
            Text(podcast.title ?? "Unknown Podcast")
                .font(.bodyEcho())
                .foregroundColor(.echoTextSecondary)
        }
    }
    
    // MARK: - Timestamp Section
    
    private var timestampSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timestamp")
                .font(.subheadlineRounded())
                .foregroundColor(.echoTextSecondary)
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.mintAccent)
                
                Text(formatTimestamp(currentTimestamp))
                    .font(.bodyRoundedMedium())
                    .foregroundColor(.mintAccent)
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Note Content Section
    
    private var noteContentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note")
                .font(.subheadlineRounded())
                .foregroundColor(.echoTextSecondary)
            
            TextEditor(text: $noteContent)
                .font(.bodyEcho())
                .foregroundColor(.echoTextPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.05))
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags (comma-separated)")
                .font(.subheadlineRounded())
                .foregroundColor(.echoTextSecondary)
            
            TextField("work, ideas, important", text: $tagsInput)
                .font(.bodyEcho())
                .foregroundColor(.echoTextPrimary)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Priority Section
    
    private var prioritySection: some View {
        Toggle(isOn: $isPriority) {
            HStack(spacing: 8) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(isPriority ? .mintAccent : .echoTextTertiary)
                
                Text("Priority")
                    .font(.bodyRoundedMedium())
                    .foregroundColor(.echoTextPrimary)
            }
        }
        .tint(.mintAccent)
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            saveNote()
        } label: {
            Text("Save note")
                .font(.bodyRoundedMedium())
                .foregroundColor(.mintButtonText)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    Color.mintButtonBackground.opacity(0.5) :
                    Color.mintButtonBackground
                )
                .cornerRadius(12)
        }
        .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    // MARK: - Save Note Action
    
    private func saveNote() {
        let trimmedContent = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        // Parse tags
        let tags = tagsInput
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Create note entity
        let note = NoteEntity(context: viewContext)
        note.id = UUID()
        note.showTitle = podcast.title
        note.episodeTitle = episode.title
        note.timestamp = formatTimestamp(currentTimestamp)
        note.noteText = trimmedContent
        note.isPriority = isPriority
        note.tags = tags.joined(separator: ",")
        note.createdAt = Date()
        note.sourceApp = "EchoNotes"
        
        // Save to Core Data
        do {
            try viewContext.save()
            print("✅ Note saved successfully")
            dismiss()
        } catch {
            print("❌ Failed to save note: \(error)")
            // TODO: Show error alert to user
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTimestamp(_ time: TimeInterval) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

#Preview("With Content") {
    let context = PersistenceController.preview.container.viewContext
    
    // Create sample podcast
    let podcast = PodcastEntity(context: context)
    podcast.id = "1"
    podcast.title = "Sample Podcast"
    podcast.author = "Test Author"
    
    // Create sample episode
    let episode = RSSEpisode(
        title: "Episode 42: The Answer",
        description: "A deep dive into the meaning of life",
        pubDate: Date(),
        duration: "45:30",
        audioURL: "https://example.com/audio.mp3",
        imageURL: nil
    )
    
    return AddNoteSheetRSS(
        episode: episode,
        podcast: podcast,
        timestamp: 1234.5
    )
    .environment(\.managedObjectContext, context)
}

#Preview("Empty") {
    let context = PersistenceController.preview.container.viewContext
    
    let podcast = PodcastEntity(context: context)
    podcast.id = "1"
    podcast.title = "Sample Podcast"
    
    let episode = RSSEpisode(
        title: "Test Episode",
        description: nil,
        pubDate: Date(),
        duration: "30:00",
        audioURL: "https://example.com/audio.mp3",
        imageURL: nil
    )
    
    return AddNoteSheetRSS(
        episode: episode,
        podcast: podcast,
        timestamp: nil
    )
    .environment(\.managedObjectContext, context)
}
```

---

## Step 2: Add File to Xcode Project

1. **Right-click on `/Views/` folder in Xcode**
2. **New File... → Swift File**
3. **Name: `AddNoteSheetRSS.swift`**
4. **Paste code above**
5. **Ensure Target: "EchoNotes" is checked**
6. **Save**

---

## Step 3: Update EpisodePlayerView to Use New Sheet

**Open `EpisodePlayerView.swift`**

**Find the addNoteButton (around line 92-96):**

```swift
// OLD CODE (has errors):
AddNoteSheet(
    episode: episode,          // Wrong type
    podcast: podcast,          // Wrong type
    playerState: player,       // Wrong type
    timestamp: player.currentTime
)

// NEW CODE:
AddNoteSheetRSS(
    episode: episode,          // RSSEpisode ✅
    podcast: podcast,          // PodcastEntity ✅
    timestamp: player.currentTime  // TimeInterval ✅
)
```

**Full context:**

```swift
private var addNoteButton: some View {
    Button {
        showingNoteCaptureSheet = true
    } label: {
        HStack(spacing: 8) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 17, weight: .medium))
            
            Text("Add note at current time")
                .font(.bodyRoundedMedium())
        }
        .foregroundColor(.mintButtonText)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(Color.mintButtonBackground)
        .cornerRadius(12)
    }
    .sheet(isPresented: $showingNoteCaptureSheet) {
        AddNoteSheetRSS(               // ← Updated
            episode: episode,
            podcast: podcast,
            timestamp: player.currentTime
        )
    }
}
```

---

## Verification

After Phase 3:

1. **Build project** (`Cmd + B`)
2. **EpisodePlayerView errors should be GONE:**
   - ✅ `cannot convert value of type 'RSSEpisode' to expected argument type 'PodcastEpisode'`
   - ✅ `missing argument for parameter 'playerState' in call`

3. **ContentView errors will REMAIN** (we fix in Phase 4):
   - ❌ `cannot find 'AudioPlayerView' in scope` (5 locations)

---

## What We Built

`AddNoteSheetRSS` is a new note capture sheet that:

1. ✅ Works with RSS models (`RSSEpisode`, `PodcastEntity`)
2. ✅ Uses `GlobalPlayerManager.shared` for playback state
3. ✅ Saves to Core Data (`NoteEntity`)
4. ✅ Follows EchoCast design tokens
5. ✅ Matches the UI/UX of original AddNoteSheet

Now `EpisodePlayerView` can successfully create notes!

---

## Next Step
Proceed to **Phase 4: Update ContentView Integration**
