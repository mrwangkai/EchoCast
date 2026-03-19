//
//  NoteCaptureView.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI

struct NoteCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    // Optional existing note for editing
    let existingNote: NoteEntity?

    @State private var showTitle: String = ""
    @State private var episodeTitle: String = ""
    @State private var timestamp: String = ""
    @State private var noteText: String = ""
    @State private var isPriority: Bool = false
    @State private var sourceApp: String = ""

    init(existingNote: NoteEntity? = nil) {
        self.existingNote = existingNote
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Podcast Info")) {
                    TextField("Show Title", text: $showTitle)
                    TextField("Episode Title", text: $episodeTitle)
                    HStack {
                        TextField("Timestamp (HH:MM:SS)", text: $timestamp)
                        Button(action: autoTimestamp) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    TextField("Source App (e.g., Overcast)", text: $sourceApp)
                }

                Section(header: Text("Note")) {
                    ZStack(alignment: .topLeading) {
                        if noteText.isEmpty {
                            Text("Type your note...")
                                .foregroundColor(.echoTextSecondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $noteText)
                            .frame(minHeight: 100)
                    }
                }

                Section {
                    Toggle(isOn: $isPriority) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Mark as Important")
                        }
                    }
                }

                Section {
                    Button(action: saveNote) {
                        HStack {
                            Spacer()
                            Text(existingNote == nil ? "Save Note" : "Update Note")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(noteText.isEmpty)
                }
            }
            .navigationTitle(existingNote == nil ? "Capture Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.echoBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(.mintAccent)
            .onAppear {
                // Pre-populate fields when editing
                if let note = existingNote {
                    showTitle = note.showTitle ?? ""
                    episodeTitle = note.episodeTitle ?? ""
                    timestamp = note.timestamp ?? ""
                    noteText = note.noteText ?? ""
                    isPriority = note.isPriority
                    sourceApp = note.sourceApp ?? ""
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func autoTimestamp() {
        // Auto-generate current timestamp (mock - in real app, get from podcast player)
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        timestamp = formatter.string(from: now)
    }

    private func saveNote() {
        if let note = existingNote {
            // Update existing note
            note.showTitle = showTitle.isEmpty ? nil : showTitle
            note.episodeTitle = episodeTitle.isEmpty ? nil : episodeTitle
            note.timestamp = timestamp.isEmpty ? nil : timestamp
            note.noteText = noteText.isEmpty ? nil : noteText
            note.isPriority = isPriority
            note.sourceApp = sourceApp.isEmpty ? nil : sourceApp

            do {
                try viewContext.save()
                print("✅ Note updated successfully")
            } catch {
                print("❌ Error updating note: \(error)")
            }
        } else {
            // Create new note
            let persistence = PersistenceController.shared
            persistence.createNote(
                showTitle: showTitle.isEmpty ? nil : showTitle,
                episodeTitle: episodeTitle.isEmpty ? nil : episodeTitle,
                timestamp: timestamp.isEmpty ? nil : timestamp,
                noteText: noteText,
                isPriority: isPriority,
                tags: [],
                sourceApp: sourceApp.isEmpty ? nil : sourceApp
            )
        }
        dismiss()
    }
}

#Preview {
    NoteCaptureView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
