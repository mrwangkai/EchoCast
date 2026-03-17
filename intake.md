git add .
git commit -m "fix(T92,T93): CarPlay album art missing + flashing

T92: Prefer episode.imageURL over podcast.artworkURL in CarPlaySceneDelegate
for both My Podcasts (line 263) and Continue Listening (line 92) paths.
Add debug log in fetchAndSetArtwork for missing URL diagnosis.

T93: Only clear artwork cache in loadEpisode() when new episode has a
different artwork URL — prevents flash to placeholder on same-podcast episodes."