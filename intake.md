git add .
git commit -m "feat(T97): Edit Note sheet mirrors Add Note design

- Add EditNoteSheetWrapper in EpisodePlayerView.swift mirroring
  NoteCaptureSheetWrapper layout exactly
- Pre-populates noteText and tags from existingNote on appear
- Timestamp read-only (clock icon + formatted time, no editing)
- Context display matches Add Note (podcast title, episode title)
- Update Note button matches Save Note styling (mint text, dark bg)
- Wire EditNoteSheetWrapper in ContentView NoteDetailSheet
- Remove recording button, Speech/AVFoundation imports, and all
  speech recognition code from NoteCaptureView.swift"