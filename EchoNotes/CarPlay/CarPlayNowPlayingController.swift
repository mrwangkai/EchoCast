import CarPlay
import Combine
import AppIntents

class CarPlayNowPlayingController {

    static let shared = CarPlayNowPlayingController()
    private init() {}

    private weak var interfaceController: CPInterfaceController?
    private var cancellables = Set<AnyCancellable>()

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
            image: UIImage(systemName: "square.and.pencil")!
        ) { [weak self] _ in
            self?.handleAddNoteTap()
        }
        DispatchQueue.main.async {
            CPNowPlayingTemplate.shared.updateNowPlayingButtons([noteButton])
        }
    }

    private func handleAddNoteTap() {
        Task { @MainActor in
            do {
                _ = try await AddNoteIntent().perform()
            } catch {
                showCarPlayAlert("Couldn't start note capture. Try Siri instead.")
            }
        }
    }

    // MARK: - Confirmation Alert

    private func showCarPlayAlert(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let controller = self?.interfaceController else { return }
            let action = CPAlertAction(
                title: "OK",
                style: .default,
                handler: { _ in controller.dismissTemplate(animated: true, completion: nil) }
            )
            let alert = CPAlertTemplate(titleVariants: [message], actions: [action])
            controller.presentTemplate(alert, animated: true, completion: nil)

            // Auto-dismiss after 1.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                controller.dismissTemplate(animated: true, completion: nil)
            }
        }
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
