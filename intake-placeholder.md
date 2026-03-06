SMALL FIX: In the player's notes tab, increase the bottom spacing between 
the notes list and the podcast metadata footer.

Find the Spacer(minLength: 0) at the bottom of the VStack inside 
NotesSegmentView (or notesTabContent). Change it to:

Spacer(minLength: 24)

Do not touch anything else.
Commit: "t37: increase bottom spacing in notes tab above footer"