Branch: create and checkout t27-player-spacing-adjustments before making any changes.
File: EpisodePlayerView.swift
Task: Four surgical spacing updates to the Listening tab player controls section. Make only these four changes — do not modify anything else.

Change 1 — Album artwork size
In albumArtworkView, find the .frame that sets the artwork square size. Change the width and height from 280 to 240.
Change 2 — Note/bookmark marker bottom padding
In timeProgressWithMarkers (or wherever note and bookmark markers are rendered above the scrubber track), find the .padding(.bottom) applied to the marker view. Change it to 8. This controls the gap between the bottom of the marker circles and the top of the scrubber track.
Change 3 — Scrubber → playback controls spacing
In the footer VStack that contains timeProgressWithMarkers and playbackControlButtons, find the spacing between those two elements. This may be a VStack(spacing:) value or a .padding(.top) on playbackControlButtons. Change the effective gap to 24pt.
Change 4 — Footer bottom padding
In the footer VStack, find .padding(.bottom, 48). Change it to .padding(.bottom, 32).

After all four changes, build the project and confirm there are no errors. Then commit with message: t27: artwork 240pt, marker gap 8pt, scrubber→controls 24pt, footer bottom 32pt