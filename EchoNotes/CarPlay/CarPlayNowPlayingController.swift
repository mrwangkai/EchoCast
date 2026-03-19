import CarPlay
import Combine
import AppIntents
import AVFoundation
import Speech

class CarPlayNowPlayingController {

    static let shared = CarPlayNowPlayingController()
    private init() {}

    private weak var interfaceController: CPInterfaceController?
    private var cancellables = Set<AnyCancellable>()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var isShowingAlert = false
    private var isHandlingNoteTap = false

    // T104: In-process voice capture
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    private var isCapturingNote = false

    func setup(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        setupNowPlayingButtons()
        observePlayerState()
    }

    func teardown() {
        cancellables.removeAll()
        interfaceController = nil
    }

    // MARK: - Now Playing Button

    private func setupNowPlayingButtons() {
        let noteButton = CPNowPlayingImageButton(
            image: UIImage(systemName: "square.and.pencil") ?? UIImage()
        ) { [weak self] _ in
            self?.handleAddNoteTap()
        }
        DispatchQueue.main.async {
            CPNowPlayingTemplate.shared.updateNowPlayingButtons([noteButton])
        }

        // T58: Ensure audio session is active for CarPlay playback
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
    }

    private func handleAddNoteTap() {
        guard !isHandlingNoteTap, !isCapturingNote else { return }
        isHandlingNoteTap = true

        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard let self = self, status == .authorized else {
                self?.isHandlingNoteTap = false
                return
            }
            DispatchQueue.main.async {
                self.startVoiceCapture()
                self.isHandlingNoteTap = false
            }
        }
    }

    private func startVoiceCapture() {
        isCapturingNote = true

        // Prompt the user via speech
        let prompt = AVSpeechUtterance(string: "What's your note?")
        prompt.voice = AVSpeechSynthesisVoice(language: "en-US")
        prompt.postUtteranceDelay = 0.4

        speechSynthesizer.speak(prompt)

        // Wait for prompt to finish before starting mic capture
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            self?.beginRecognition()
        }
    }

    private func beginRecognition() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            isCapturingNote = false
            return
        }

        recognitionRequest.shouldReportPartialResults = false

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth])
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try? audioEngine.start()

        // Auto-stop after 10 seconds of listening
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.stopRecognition()
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result, result.isFinal {
                let noteText = result.bestTranscription.formattedString
                self.stopRecognition()
                self.saveNote(text: noteText)
            } else if error != nil {
                self.stopRecognition()
            }
        }
    }

    private func stopRecognition() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        isCapturingNote = false

        // Restore audio session for playback
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth])
        try? AVAudioSession.sharedInstance().setActive(true, options: [])
    }

    private func saveNote(text: String) {
        guard !text.isEmpty else {
            let utterance = AVSpeechUtterance(string: "No note captured.")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            speechSynthesizer.speak(utterance)
            return
        }

        let currentTime = GlobalPlayerManager.shared.currentTime
        let formattedTime = formatTimestamp(currentTime)
        let sharedDefaults = UserDefaults(suiteName: "group.com.echonotes.app202601302226.echocast")
        let episodeTitle = sharedDefaults?.string(forKey: "siri_episodeTitle") ?? ""
        let podcastTitle = sharedDefaults?.string(forKey: "siri_podcastTitle") ?? ""

        let context = PersistenceController.shared.container.viewContext
        context.perform {
            let note = NoteEntity(context: context)
            note.id = UUID()
            note.episodeTitle = episodeTitle
            note.showTitle = podcastTitle
            note.timestamp = formattedTime
            note.noteText = text
            note.isPriority = false
            note.tags = ""
            note.createdAt = Date()
            note.sourceApp = "CarPlay"
            try? context.save()
        }

        // Spoken confirmation
        let utterance = AVSpeechUtterance(string: "Note saved at \(formattedTime).")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)

        // Visual confirmation
        showNoteSavedConfirmation(at: formattedTime)
    }

    // MARK: - T64: Note Saved Confirmation

    private func showNoteSavedConfirmation(at time: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard !self.isShowingAlert else { return }
            guard let controller = self.interfaceController else { return }
            self.isShowingAlert = true
            let action = CPAlertAction(
                title: "OK",
                style: .default,
                handler: { _ in
                    controller.dismissTemplate(animated: true, completion: nil)
                    self.isShowingAlert = false
                }
            )
            let alert = CPAlertTemplate(titleVariants: ["Note Saved"], actions: [action])
            controller.presentTemplate(alert, animated: true, completion: nil)

            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                controller.dismissTemplate(animated: true, completion: nil)
                self.isShowingAlert = false
            }
        }
    }

    private func formatTimestamp(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Player State Observation

    private func observePlayerState() {
        GlobalPlayerManager.shared.$currentEpisode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] episode in
                guard episode != nil else { return }
                self?.pushNowPlayingIfNeeded()
            }
            .store(in: &cancellables)

        // Handle already-playing case: if episode is loaded before CarPlay connects
        if GlobalPlayerManager.shared.currentEpisode != nil {
            pushNowPlayingIfNeeded()
        }
    }

    private func pushNowPlayingIfNeeded() {
        guard let controller = interfaceController else { return }
        // Only push if not already showing Now Playing
        guard !(controller.topTemplate is CPNowPlayingTemplate) else { return }
        controller.pushTemplate(
            CPNowPlayingTemplate.shared,
            animated: true,
            completion: nil
        )
    }
}
