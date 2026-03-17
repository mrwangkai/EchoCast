git add .
git commit -m "fix(T95,T96): CarPlay Add Note crash + first launch Core Data crash

T95: Replace AddNoteIntent().perform() in CarPlayNowPlayingController
with NotificationCenter post. ContentView receives via .onReceive and
presents note sheet via showMiniPlayerNoteSheet.

T96: Replace fatalError in PersistenceController.loadPersistentStores
with store deletion recovery path to prevent crash on corrupt/failed store."

Once that's done, mark T95 and T96 complete in echocast_todo.md with the commit hash.