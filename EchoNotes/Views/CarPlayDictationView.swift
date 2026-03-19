//
//  CarPlayDictationView.swift
//  EchoNotes
//
//  Siri-style dictation sheet for CarPlay Add Note
//

import SwiftUI
import Speech
import AVFoundation

struct CarPlayDictationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var transcribedText = ""
    @State private var isListening = false
    @State private var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()

                // Podcast info header
                VStack(spacing: 8) {
                    if let podcast = GlobalPlayerManager.shared.currentPodcast,
                       let episode = GlobalPlayerManager.shared.currentEpisode {
                        Text(podcast.title ?? "Unknown Podcast")
                            .font(.bodyEcho())
                            .foregroundColor(.echoTextSecondary)
                        Text(episode.title)
                            .font(.title2Echo())
                            .foregroundColor(.echoTextPrimary)

                        // Timestamp badge
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                            Text(formatTimestamp(GlobalPlayerManager.shared.currentTime))
                                .font(.bodyEcho())
                        }
                        .foregroundColor(.echoBackground)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.mintAccent)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, EchoSpacing.screenPadding)

                Spacer()

                // Listening UI
                VStack(spacing: 24) {
                    // Animated waveform/mic icon
                    ZStack {
                        Circle()
                            .fill(Color.mintAccent.opacity(0.15))
                            .frame(width: 120, height: 120)

                        Image(systemName: isListening ? "waveform" : "mic.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.mintAccent)
                            .symbolEffect(.pulse, options: .repeating, isActive: isListening)
                    }

                    // Status text
                    if isListening {
                        Text("Listening...")
                            .font(.bodyEcho())
                            .foregroundColor(.mintAccent)
                    } else if authorizationStatus == .denied {
                        Text("Microphone access denied")
                            .font(.bodyEcho())
                            .foregroundColor(.red)
                    } else if authorizationStatus == .restricted {
                        Text("Speech recognition restricted")
                            .font(.bodyEcho())
                            .foregroundColor(.red)
                    } else {
                        Text("Tap to speak")
                            .font(.bodyEcho())
                            .foregroundColor(.echoTextSecondary)
                    }
                }

                // Transcribed text
                if !transcribedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your note:")
                            .font(.caption)
                            .foregroundColor(.echoTextSecondary)
                            .padding(.horizontal, EchoSpacing.screenPadding)

                        Text(transcribedText)
                            .font(.bodyEcho())
                            .foregroundColor(.echoTextPrimary)
                            .padding(.horizontal, EchoSpacing.screenPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 16)
                }

                Spacer()

                // Save button
                Button(action: saveNote) {
                    Text("Save Note")
                        .font(.bodyRoundedMedium())
                        .foregroundColor(.mintButtonText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(transcribedText.isEmpty ? Color.mintAccent.opacity(0.3) : Color.mintButtonBackground)
                        .cornerRadius(12)
                }
                .disabled(transcribedText.isEmpty)
                .padding(.horizontal, EchoSpacing.screenPadding)

                // Cancel button
                Button("Cancel", action: cancel)
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextSecondary)
                    .padding(.bottom, 16)
            }
            .background(Color.echoBackground)
            .onAppear {
                requestAuthorizationAndStartListening()
            }
            .onDisappear {
                stopListening()
            }
        }
        .navigationTitle("Add Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.echoBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Actions

    private func saveNote() {
        guard !transcribedText.isEmpty else { return }

        let player = GlobalPlayerManager.shared
        let timestamp = formatTimestamp(player.currentTime)

        PersistenceController.shared.createNote(
            showTitle: player.currentPodcast?.title,
            episodeTitle: player.currentEpisode?.title,
            timestamp: timestamp,
            noteText: transcribedText,
            isPriority: false,
            tags: [],
            sourceApp: "CarPlay"
        )

        // Post notification for CarPlay confirmation
        NotificationCenter.default.post(
            name: Notification.Name("EchoCast.carPlayNoteSaved"),
            object: timestamp
        )

        dismiss()
    }

    private func cancel() {
        dismiss()
    }

    private func formatTimestamp(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Speech Recognition

    private func requestAuthorizationAndStartListening() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            Task { @MainActor in
                startListening()
            }
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { status in
                Task { @MainActor in
                    self.authorizationStatus = status
                    if status == .authorized {
                        self.startListening()
                    }
                }
            }
        case .denied, .restricted:
            authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        @unknown default:
            authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        }
    }

    @MainActor
    private func startListening() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("⚠️ [CarPlayDictation] Speech recognizer not available")
            return
        }

        // Setup audio session for recording
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetoothA2DP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("⚠️ [CarPlayDictation] Failed to setup audio session: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("⚠️ [CarPlayDictation] Unable to create recognition request")
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            Task { @MainActor in
                if let result = result {
                    transcribedText = result.bestTranscription.formattedString
                }

                if let error = error {
                    print("⚠️ [CarPlayDictation] Recognition error: \(error)")
                    isListening = false
                    stopListening()
                }

                if result?.isFinal == true {
                    isListening = false
                    stopListening()
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        try? audioEngine.start()
        isListening = true

        print("✅ [CarPlayDictation] Started listening")
    }

    @MainActor
    private func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        // Deactivate audio session but don't stop podcast playback
        try? AVAudioSession.sharedInstance().setActive(false)

        isListening = false
        print("⏹️ [CarPlayDictation] Stopped listening")
    }
}

#Preview {
    CarPlayDictationView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
