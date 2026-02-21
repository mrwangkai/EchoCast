We are replacing the note preview sheet approach with an in-player 
overlay card. No new sheets. The preview appears as a floating card 
INSIDE EpisodePlayerView using a ZStack overlay.

Checkpoint: b614e6e — revert here if anything breaks.

---

## STEP 1: Read only, no changes

Read EchoNotes/Views/Player/EpisodePlayerView.swift and report:

1. The outermost view structure of body — is it a VStack, ZStack, 
   or something else? Show the opening 20 lines of body.

2. The current .sheet(item: $activeSheet) block — we will be 
   removing the .notePreview case from it (keeping .noteCapture).

3. The PlayerSheet enum — show current cases.

4. Where activeSheet = .notePreview(note) is called (both the 
   marker tap and the onNoteTap callback).

Report before touching anything.

---

## STEP 2: Add overlay state to EpisodePlayerView

Add these two @State vars:

@State private var previewNote: NoteEntity? = nil
@State private var showingNotePreview: Bool = false

---

## STEP 3: Create the overlay card view

Add this as a private struct at the bottom of EpisodePlayerView.swift:

private struct NoteOverlayCard: View {
    let note: NoteEntity
    let allNotesAtTimestamp: [NoteEntity]
    let onJump: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dismiss handle area — tap anywhere outside card dismisses
            // (handled by the parent ZStack tap)

            VStack(alignment: .leading, spacing: 12) {

                // Header row: timestamp badge + close button
                HStack {
                    if let timestamp = note.timestamp {
                        Text(timestamp)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.102, green: 0.235, blue: 0.204))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mintAccent)
                            .clipShape(Capsule())
                    }

                    if allNotesAtTimestamp.count > 1 {
                        Text("\(allNotesAtTimestamp.count) notes here")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }

                // Note text
                if let text = note.noteText, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Tags
                let tags = note.tagsArray
                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Jump button
                Button(action: onJump) {
                    HStack {
                        Image(systemName: "arrow.forward.circle.fill")
                        Text("Jump to time")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.mintAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.mintAccent.opacity(0.15))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.14, green: 0.14, blue: 0.16))
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -4)
            )
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

---

## STEP 4: Wrap EpisodePlayerView body in a ZStack

The current outermost view in body needs to become the bottom 
layer of a ZStack, with the overlay card as the top layer.

Wrap the existing body content like this:

var body: some View {
    ZStack(alignment: .bottom) {
        
        // ── existing body content unchanged ──
        // (the VStack with segmented control, tab content, player controls)
        // Keep ALL existing modifiers (.background, .presentationDetents etc)
        
        // ── overlay card ──
        if showingNotePreview, let note = previewNote {
            // Dimming background tap to dismiss
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showingNotePreview = false
                        previewNote = nil
                    }
                }
            
            NoteOverlayCard(
                note: note,
                allNotesAtTimestamp: notesAtTimestamp(note.timestamp ?? ""),
                onJump: {
                    if let timestamp = note.timestamp,
                       let timeInSeconds = parseTimestamp(timestamp) {
                        player.seek(to: timeInSeconds)
                        withAnimation(.spring(response: 0.3)) {
                            showingNotePreview = false
                            previewNote = nil
                            selectedSegment = 0
                        }
                    }
                },
                onDismiss: {
                    withAnimation(.spring(response: 0.3)) {
                        showingNotePreview = false
                        previewNote = nil
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}

---

## STEP 5: Replace activeSheet = .notePreview(note) with overlay trigger

Anywhere that currently calls activeSheet = .notePreview(note) 
— both the marker tap and the onNoteTap callback — replace with:

withAnimation(.spring(response: 0.3)) {
    previewNote = note
    showingNotePreview = true
}

---

## STEP 6: Clean up PlayerSheet enum and activeSheet

Remove the .notePreview case from the PlayerSheet enum entirely.
Keep only .noteCapture.

Remove the .notePreview case from the .sheet(item: $activeSheet) 
switch block.

The enum becomes:
private enum PlayerSheet: Identifiable {
    case noteCapture
    
    var id: String { "noteCapture" }
}

---

## STEP 7: Build

Build only. Report pass or fail with exact errors.
Do not fix errors without reporting first.

---

## STEP 8: If build passes

git add -A
git commit -m "Note preview: overlay card inside player (no nested sheets)"

Report commit hash.
