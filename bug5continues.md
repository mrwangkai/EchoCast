Log when trying to click on an episode in the downloaded list:   

✅ Audio session configured successfully
✅ Remote command center configured
🎵 Tapped downloaded episode: 20. Persia - An Empire in Ashes
   Found podcast by feed URL: Fall of Civilizations Podcast
📁 File path for episode:
   Original ID: https://traffic.megaphone.fm/APO9318872854.mp3...
   Safe filename: traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
   Full path: /var/mobile/Containers/Data/Application/464E8DD6-7873-41E1-89E4-28FE35DC3C4E/Documents/Downloads/traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
✅ Playing from local file: /var/mobile/Containers/Data/Application/464E8DD6-7873-41E1-89E4-28FE35DC3C4E/Documents/Downloads/traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
❌ Local file does not exist at path: /var/mobile/Containers/Data/Application/464E8DD6-7873-41E1-89E4-28FE35DC3C4E/Documents/Downloads/traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3

Log when trying to click on tan episode in the "continue playing" list on Home Screen
📱 handleRecentEpisodeTap called for: 20. Persia - An Empire in Ashes
   Looking for podcast:
   - ID from history: 328ED85B-92F0-435E-9C32-E6FC048F29BD
   - Title from history: Fall of Civilizations Podcast
   ✅ Found podcast: Fall of Civilizations Podcast
   ✅ Podcast ID: 328ED85B-92F0-435E-9C32-E6FC048F29BD
   ✅ Setting state variables...
   Episode ID: https://traffic.megaphone.fm/APO9318872854.mp3
   ✅ Sheet state updated - episode and podcast set
   ✅ showRecentEpisodePlayer = true
⚠️⚠️ Episode sheet opened but data is nil
   Episode object: EXISTS
   Episode title: 20. Persia - An Empire in Ashes
   Podcast object: EXISTS
   Podcast title: Fall of Civilizations Podcast

Closed the sheet, went over to Podcast tab, click on the series, and then click on the episode which should have been downloaded. And encounter a blank "Loading episode" sheet with the following log:
⚠️ Episode sheet opened but selectedEpisode is nil

Pulled down and closed the sheet; then tap on the same episode. A sheet opens with loading and Buffering scrum, and the following log 
🎵 AudioPlayerView init - Episode: 20. Persia - An Empire in Ashes
   Podcast: Fall of Civilizations Podcast
   Audio URL: https://traffic.megaphone.fm/APO9318872854.mp3
   AutoPlay: true
👀 AudioPlayerView appeared
   Episode: 20. Persia - An Empire in Ashes
   Audio URL: https://traffic.megaphone.fm/APO9318872854.mp3
   Is same episode as current: false
   Loading episode into player...
📁 File path for episode:
   Original ID: https://traffic.megaphone.fm/APO9318872854.mp3...
   Safe filename: traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
   Full path: /var/mobile/Containers/Data/Application/464E8DD6-7873-41E1-89E4-28FE35DC3C4E/Documents/Downloads/traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
✅ Playing from local file: traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
<<<< FigApplicationStateMonitor >>>> signalled err=-19431 at <>:474
<<<< FigApplicationStateMonitor >>>> signalled err=-19431 at <>:474
🎵 AudioPlayerView init - Episode: 20. Persia - An Empire in Ashes
   Podcast: Fall of Civilizations Podcast
   Audio URL: https://traffic.megaphone.fm/APO9318872854.mp3
   AutoPlay: true
⚠️ Error loading duration: Error Domain=AVFoundationErrorDomain Code=-11800 "The operation could not be completed" UserInfo={NSUnderlyingError=0x11f93a4f0 {Error Domain=NSOSStatusErrorDomain Code=-17913 "(null)"}, NSLocalizedFailureReason=An unknown error occurred (-17913), AVErrorFailedDependenciesKey=(
    Duration
), NSURL=file:///var/mobile/Containers/Data/Application/464E8DD6-7873-41E1-89E4-28FE35DC3C4E/Documents/Downloads/traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3, NSLocalizedDescription=The operation could not be completed}
   Error domain: AVFoundationErrorDomain
   Error code: -11800
   ⚠️ File appears corrupted. Checking if this is a local file...
⏳ Player status unknown
   ⚠️ Local file is corrupted. Attempting to re-download and stream...
📁 File path for episode:
   Original ID: https://traffic.megaphone.fm/APO9318872854.mp3...
   Safe filename: traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
   Full path: /var/mobile/Containers/Data/Application/464E8DD6-7873-41E1-89E4-28FE35DC3C4E/Documents/Downloads/traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
   ✅ Removed corrupted file
   ✅ Attempting to stream from remote URL...
📥 Download requested for: 20. Persia - An Empire in Ashes
   Episode ID: https://traffic.megaphone.fm/APO9318872854.mp3
   Already downloaded: false
   Currently downloading: false

📥 Download finished!
Started downloading episode: 20. Persia - An Empire in Ashes
   Temp location: /.nofollow/private/var/mobile/Containers/Data/Application/464E8DD6-7873-41E1-89E4-28FE35DC3C4E/Library/Caches/com.apple.nsurlsessiond/Downloads/com.echonotes.app/CFNetworkDownload_d8md6s.tmp
   Episode ID: https://traffic.megaphone.fm/APO9318872854.mp3...
📁 File path for episode:
   Original ID: https://traffic.megaphone.fm/APO9318872854.mp3...
   Safe filename: traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
   Full path: /var/mobile/Containers/Data/Application/464E8DD6-7873-41E1-89E4-28FE35DC3C4E/Documents/Downloads/traffic.megaphone.fm_APO9318872854.mp3_8145617742363761376.mp3
   Moving file from temp to permanent location...
🎵 AudioPlayerView init - Episode: 20. Persia - An Empire in Ashes
   Podcast: Fall of Civilizations Podcast
   Audio URL: https://traffic.megaphone.fm/APO9318872854.mp3
   AutoPlay: true
   ✅ File moved successfully!
   ✅ File verified! Size: 316925950 bytes
   ✅ Audio file validated! Duration: 19807s
🎵 AudioPlayerView init - Episode: 20. Persia - An Empire in Ashes
   Podcast: Fall of Civilizations Podcast
   Audio URL: https://traffic.megaphone.fm/APO9318872854.mp3
   AutoPlay: true
   ✅ Metadata saved
✅ Download completed for episode: https://traffic.megaphone.fm/APO9318872854.mp3...
   Downloaded episodes count: 5
   Is downloaded: true
🎵 AudioPlayerView init - Episode: 20. Persia - An Empire in Ashes
   Podcast: Fall of Civilizations Podcast
   Audio URL: https://traffic.megaphone.fm/APO9318872854.mp3
   AutoPlay: true
🎵 AudioPlayerView init - Episode: 20. Persia - An Empire in Ashes
   Podcast: Fall of Civilizations Podcast
   Audio URL: https://traffic.megaphone.fm/APO9318872854.mp3
   AutoPlay: true
🎵 AudioPlayerView init - Episode: 20. Persia - An Empire in Ashes
   Podcast: Fall of Civilizations Podcast
   Audio URL: https://traffic.megaphone.fm/APO9318872854.mp3
   AutoPlay: true
   
(then the same AudioPlayerView init continues as the episode plays -- while again, the loading and buffering continues)

when i collapse it to a miniplayer then expand it, it is persistent, but the loading and buffering continues.
another visual issue is also happening: the elapsed and played timer is inaccurate; its showing the elapsed time, and 0:00 on the timer remaining.
