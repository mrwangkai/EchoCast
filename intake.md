


T58 Fix — Phase 2
Read echocast_todo.md to understand T58. Then read EchoNotes/Services/GlobalPlayerManager.swift lines 56–111 (audio session setup + remote command center setup) and EchoNotes/CarPlay/CarPlayNowPlayingController.swift in full.
Make the following targeted fixes:

In GlobalPlayerManager.swift, find setupRemoteCommandCenter(). Confirm playCommand, pauseCommand, and togglePlayPauseCommand handlers are all registered. If any are missing, add them. Each handler should call self.play(), self.pause(), or self.togglePlayPause() respectively and return .success.
In GlobalPlayerManager.swift, find the .failed case in the statusObserver (around line 312). Add a print("T58 DEBUG: AVPlayerItem failed — \(error?.localizedDescription ?? "unknown")") log so we can confirm if the item itself is failing to load.
In CarPlayNowPlayingController.swift, after CPNowPlayingTemplate.shared is configured and before it's set as the root template, call AVAudioSession.sharedInstance().setActive(true, options: []) wrapped in a try? — this ensures the session is active at the moment CarPlay takes over audio focus.
Do not modify EpisodePlayerView, ContentView, or any non-CarPlay/non-GlobalPlayerManager files.

Build must succeed. Commit to branch t58-carplay-playback-stops with message t58: wire remote commands and ensure audio session active for CarPlay playback. Update echocast_todo.md with commit hash.