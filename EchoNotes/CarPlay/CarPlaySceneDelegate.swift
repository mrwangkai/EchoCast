import CarPlay
import Combine

class CarPlaySceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {

    private var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        CarPlayNowPlayingController.shared.setup(interfaceController: interfaceController)

        let listTemplate = buildRecentlyPlayedTemplate()
        interfaceController.setRootTemplate(listTemplate, animated: false, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        CarPlayNowPlayingController.shared.teardown()
        self.interfaceController = nil
    }

    private func buildRecentlyPlayedTemplate() -> CPListTemplate {
        let history = PlaybackHistoryManager.shared.recentlyPlayed.prefix(10)

        let items: [CPListItem] = history.map { item in
            let listItem = CPListItem(
                text: item.episodeTitle,
                detailText: item.podcastTitle
            )
            listItem.handler = { [weak self] _, completion in
                self?.handleEpisodeTap(item: item)
                completion()
            }
            return listItem
        }

        let section: CPListSection
        if items.isEmpty {
            let emptyItem = CPListItem(text: "No recent episodes", detailText: nil)
            section = CPListSection(items: [emptyItem])
        } else {
            section = CPListSection(items: items)
        }

        let template = CPListTemplate(title: "EchoCast", sections: [section])
        return template
    }

    private func handleEpisodeTap(item: PlaybackHistoryItem) {
        // Load into GlobalPlayerManager and push Now Playing
        DispatchQueue.main.async {
            // GlobalPlayerManager needs audio URL and episode context to resume
            // For now, push CPNowPlayingTemplate — full resume is out of scope for T22
            CPNowPlayingTemplate.shared.isUpNextButtonEnabled = false
            CPNowPlayingTemplate.shared.isAlbumArtistButtonEnabled = false
            self.interfaceController?.pushTemplate(
                CPNowPlayingTemplate.shared,
                animated: true,
                completion: nil
            )
        }
    }
}
