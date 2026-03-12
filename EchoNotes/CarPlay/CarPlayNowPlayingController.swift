import CarPlay
import Combine
import AppIntents
import AVFoundation

class CarPlayNowPlayingController {

    static let shared = CarPlayNowPlayingController()
    private init() {}

    private weak var interfaceController: CPInterfaceController?
    private var cancellables = Set<AnyCancellable>()
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var isShowingAlert = false
    private var isHandlingNoteTap = false

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
        guard !isHandlingNoteTap else { return }
        isHandlingNoteTap = true
        Task { @MainActor in
            do {
                _ = try await AddNoteIntent().perform()

                // T64: Audio confirmation
                let currentTime = GlobalPlayerManager.shared.currentTime
                let formattedTime = formatTimestamp(currentTime)
                let utterance = AVSpeechUtterance(string: "Note saved at \(formattedTime)")
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                speechSynthesizer.speak(utterance)

                // T64: Visual confirmation
                showNoteSavedConfirmation(at: formattedTime)

            } catch {
                print("T63 DEBUG: AddNoteIntent failed — \(error)")
                showCarPlayAlert("Couldn't start note capture. Try Siri instead.")
            }
            isHandlingNoteTap = false
        }
    }

    // MARK: - Confirmation Alert

    private func showCarPlayAlert(_ message: String) {
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
            let alert = CPAlertTemplate(titleVariants: [message], actions: [action])
            controller.presentTemplate(alert, animated: true, completion: nil)

            // Auto-dismiss after 1.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                controller.dismissTemplate(animated: true, completion: nil)
                self.isShowingAlert = false
            }
        }
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
