Update echocast_todo.md. Find T83, T84, T85 in the Done section and 
update their descriptions to reflect what was actually fixed:

T83: "Reduced ContinueListeningSheetRow vertical padding to 8pt. 
Note: initial fix incorrectly increased padding from 10pt to 12pt; 
corrected in follow-up."

T84: "Fixed double-tap-to-remove — PlaybackHistoryManager already had 
@MainActor at class level. Fixed by ensuring removeFromHistory is called 
inside await MainActor.run in the Task block in removeEpisode, preventing 
race condition between animation delay and @Published array mutation."

T85: "Reduced delete animation to 150ms (withAnimation easeOut 0.15s, 
Task.sleep 175ms). Follow-up tweak from initial 600ms → 300ms reduction."

Also update any "(Commit: TBD)" entries for T82-T85 to today's date 
placeholder "(Commit: see Build 11 git log)" if no hash is available.

Do not touch any other tasks.