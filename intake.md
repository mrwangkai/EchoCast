CARPLAY SANITY CHECK — READ ONLY, NO CHANGES
Read EchoNotes/CarPlay/CarPlaySceneDelegate.swift in full. Do not modify anything.
Report the following:

Tab structure — Does didConnect set a CPTabBarTemplate as root with exactly two tabs? Paste the assembly code.
Home tab sections — Does buildHomeTemplate() produce two sections ("Continue Listening" and "Latest Episodes")? Does it correctly skip the Continue Listening episode when building Latest Episodes to avoid duplication?
Tap handler — For episode rows in both Home and My Podcasts drill-down, does the handler both (a) call GlobalPlayerManager.shared.loadEpisode(...) and .play(), AND (b) push CPNowPlayingTemplate? Paste the handler body.
Completion handler — Is completion() called in every code path of every CPListItem handler, including any guard-fail or early-exit branches?
Artwork loading — Does loadAndCacheImage() correctly call the update on success and use the placeholder on failure (not inverted)? Paste the success and failure branches.
My Podcasts drill-down — Does tapping a podcast row push a new CPListTemplate? Does that template's episode items have their own tap handlers that trigger playback?
Cold start safety — Does buildHomeTemplate() handle an empty recentlyPlayed array gracefully (no force-unwraps, no crashes on empty state)?

Stop here. Report all findings. Do not make any changes.