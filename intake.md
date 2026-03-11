You are working on EchoCast (codebase: EchoNotes). Reference docs/echocast_todo.md throughout.

## Task: T46 follow-up — Remove source badge from NoteCardView only

The source badge added in commit 93b6ca1 should only appear in NoteRowDetailView (the notes sheet list row), not on NoteCardView (used on home screen and library).

**Change:**
In ContentView.swift, find the source badge code added to NoteCardView in the last commit (~lines 3191-3225) and remove it entirely. Leave NoteRowDetailView and NoteDetailSheet untouched.

**Rules:**
- ContentView.swift only
- Remove only the source badge block from NoteCardView — nothing else
- Do NOT touch NoteRowDetailView, NoteDetailSheet, or any other view
- Do NOT touch player files, Core Data models, or design tokens
- Build must succeed

Commit message: "T46 follow-up: remove source badge from NoteCardView, keep on NoteRowDetailView only"