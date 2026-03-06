SMALL FIX: NoteRowView rows in the episode player Notes tab have no 
horizontal padding — the timestamp is flush against the screen edge.

Find the ForEach container (or its enclosing VStack/ScrollView content block) 
that renders NoteRowView inside the player's notesTabContent.

Add .padding(.horizontal, EchoSpacing.screenPadding) to that container.
This matches the horizontal padding used by other elements in the player view.

Do not touch NoteRowView itself or any other view.
Commit: "t37: fix horizontal padding on player notes list"