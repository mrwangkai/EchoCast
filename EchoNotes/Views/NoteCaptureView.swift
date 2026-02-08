//
//  NoteCaptureView.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI
import Speech
import AVFoundation

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

    @State private var isRecording: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var permissionMessage: String = ""

    private let speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

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
                            Text("Tap the microphone to record or type your note...")
                                .foregroundColor(.echoTextSecondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $noteText)
                            .frame(minHeight: 100)
                    }

                    // Voice recording button
                    HStack {
                        Spacer()
                        Button(action: toggleRecording) {
                            VStack {
                                Image(systemName: isRecording ? "mic.fill" : "mic")
                                    .font(.system(size: 32))
                                    .foregroundColor(isRecording ? .red : .blue)
                                Text(isRecording ? "Recording..." : "Tap to Record")
                                    .font(.caption)
                            }
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.searchFieldBackground)
                                    .frame(width: 80, height: 80)
                            )
                        }
                        Spacer()
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
            .alert("Permission Required", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) {}
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(permissionMessage)
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

    // MARK: - Speech Recognition

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        // Request speech recognition permission
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus != .authorized {
                    permissionMessage = "Speech recognition permission is required to record voice notes."
                    showPermissionAlert = true
                    return
                }

                // Request microphone permission
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async {
                        if !granted {
                            permissionMessage = "Microphone access is required to record voice notes."
                            showPermissionAlert = true
                            return
                        }

                        beginRecording()
                    }
                }
            }
        }
    }

    private func beginRecording() {
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    noteText = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                stopRecording()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isRecording = false
    }
}

#Preview {
    NoteCaptureView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
