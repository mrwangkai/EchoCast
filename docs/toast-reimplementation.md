Implement toast notifications. Follow these rules strictly:
- Do NOT add any ViewModifier that wraps the root view
- Do NOT add any new ZStack above or around the existing main ZStack
- Do NOT touch the sheet presentation, note markers, bookmark markers, 
  or any other existing functionality
- Toast must live INSIDE the existing main ZStack (lines 137-307)

---

PART A — Verify ToastView.swift exists and is correct

Check if Components/ToastView.swift exists. If it does, replace its 
contents entirely with:

import SwiftUI

struct ToastMessage: Equatable {
    let message: String
    let icon: String
}

struct ToastView: View {
    let toast: ToastMessage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.icon)
                .font(.system(size: 14, weight: .semibold))
            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

If it does not exist, create it at Components/ToastView.swift with the 
above content and add it to the Xcode project target.

---

PART B — Add state and helper to EpisodePlayerView.swift

1. Add this state variable near the other @State vars at the top:
@State private var toastMessage: ToastMessage? = nil

2. Add this helper function anywhere in the view (near other private funcs):
private func showToast(_ message: String, icon: String) {
    withAnimation(.spring(response: 0.3)) {
        toastMessage = ToastMessage(message: message, icon: icon)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        withAnimation(.spring(response: 0.3)) {
            toastMessage = nil
        }
    }
}

---

PART C — Add toast layer inside main ZStack

Inside the main ZStack, AFTER the bookmark preview overlay closing brace 
(line 306), and BEFORE the ZStack closing brace (line 307), insert:

// Toast overlay
if let toast = toastMessage {
    VStack {
        ToastView(toast: toast)
            .padding(.top, 60)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .allowsHitTesting(false)
    .zIndex(1000)
    .transition(
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        )
    )
}

---

PART D — Trigger toasts

1. In addBookmark(), after try? viewContext.save() (new bookmark created):
showToast("Bookmark at \(formatTime(currentTime)) added", icon: "bookmark.fill")

2. In addBookmark(), after recentBookmarkTime = nil (bookmark removed):
showToast("Bookmark at \(formatTime(lastTime)) removed", icon: "bookmark.slash.fill")

3. In the noteCapture onDisappear block (lines 326-331), add note toast 
   AFTER the existing resume logic. The note was just saved so we check 
   the current player time:
.onDisappear {
    // Resume playback if it was playing before
    if wasPlayingBeforeNote {
        player.play()
    }
    // Note toast — fires after sheet dismisses so it's always visible
    showToast("Note at \(formatTime(player.currentTime)) added", icon: "note.text")
}

---

Build and confirm it compiles with no errors.
Commit with message: "feat: toast notifications inline ZStack (no wrapper)"

🧪 TEST NOW in simulator:
1. Add a bookmark — toast appears at TOP of screen: "Bookmark at 1:23 added"
2. Tap bookmark button within 10s — toast: "Bookmark removed at 1:23 removed"
3. Add a note via the sheet — after sheet dismisses, toast appears: 
   "Note at 1:23 added"
4. All toasts auto-dismiss after 3 seconds
5. Toasts appear above overlays and sheets
6. Confirm note markers, bookmark markers, and overlay cards are unaffected
