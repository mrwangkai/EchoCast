TASK: Find Root Cause of "Works on 2nd Attempt" Bug

Problem: Episodes/podcasts require 2-3 taps before displaying
Pattern: 1st tap = blank/loading, 2nd tap = works (data cached)

This suggests: Data loads successfully but UI doesn't update

═══════════════════════════════════════════════════════════

INVESTIGATE THESE ROOT CAUSES:

1. MAIN THREAD UPDATES
   Check if loadEpisodes() updates UI on main thread:
   
   // BAD (causes UI not to update):
   func loadEpisodes() async {
       episodes = try await fetchEpisodes()  // ← Background thread
   }
   
   // GOOD:
   func loadEpisodes() async {
       let fetched = try await fetchEpisodes()
       await MainActor.run {
           episodes = fetched  // ← Main thread
       }
   }

2. PUBLISHED PROPERTIES
   Check if episodes array is @Published:
   
   // BAD:
   var episodes: [RSSEpisode] = []  // ← Won't trigger UI update
   
   // GOOD:
   @Published var episodes: [RSSEpisode] = []

3. STATE PROPERTY WRAPPERS
   Check if view is observing the model:
   
   // BAD:
   var viewModel = PodcastDetailViewModel()  // ← Won't observe
   
   // GOOD:
   @StateObject private var viewModel = PodcastDetailViewModel()
   @ObservedObject var viewModel: PodcastDetailViewModel

4. SHEET TIMING ISSUE
   Check if sheet opens before state is set:
   
   // Current behavior in logs:
   🔓 Opening sheet for: NPR News
   📊 [PodcastDetail] View appeared
   📡 [PodcastDetail] Loading episodes
   ✅ [PodcastDetail] Loaded 50 episodes
   
   // If episodes loads but selectedPodcast is nil:
   → Sheet shows but has no data to display

5. CORE DATA CONTEXT ISSUE
   Check if PodcastEntity is fetched on wrong context:
   
   // BAD:
   let podcast = fetchPodcast(background context)
   showSheet = true  // ← View can't access background object
   
   // GOOD:
   let podcast = fetchPodcast(viewContext)
   showSheet = true

═══════════════════════════════════════════════════════════

SPECIFIC FILES TO CHECK:

PodcastDetailView.swift:
- How is episodes array declared?
- Is loadEpisodes() using @MainActor?
- Is .task {} using await properly?
- Log when episodes count changes

PodcastDiscoveryView.swift:
- How is selectedPodcast set?
- Is it using viewContext or background context?
- Does sheet have access to podcast data?

GlobalPlayerManager.swift:
- Are all @Published properties on main thread?
- Is loadEpisode() using @MainActor for UI updates?

═══════════════════════════════════════════════════════════

ADD THESE DEBUG LOGS:

In loadEpisodes():
print("📡 [PodcastDetail] Thread: \(Thread.isMainThread ? "MAIN" : "BACKGROUND")")
print("📡 [PodcastDetail] Starting load, current episodes: \(episodes.count)")
// ... fetch episodes
print("📡 [PodcastDetail] Fetched \(fetchedEpisodes.count) episodes")
print("📡 [PodcastDetail] Thread before update: \(Thread.isMainThread ? "MAIN" : "BACKGROUND")")
episodes = fetchedEpisodes
print("✅ [PodcastDetail] Updated episodes array: \(episodes.count)")
print("✅ [PodcastDetail] Thread after update: \(Thread.isMainThread ? "MAIN" : "BACKGROUND")")

In PodcastDiscoveryView where podcast is tapped:
print("🔓 [Browse] Setting selectedPodcast")
print("🔓 [Browse] Podcast ID: \(podcast.id ?? "nil")")
print("🔓 [Browse] Podcast context: \(podcast.managedObjectContext)")
selectedPodcast = podcast
print("🔓 [Browse] Opening sheet")
showingPodcastDetail = true

In PodcastDetailView.onAppear:
print("📊 [PodcastDetail] View appeared")
print("📊 [PodcastDetail] Podcast: \(podcast?.title ?? "nil")")
print("📊 [PodcastDetail] Feed URL: \(podcast?.feedURL ?? "nil")")
print("📊 [PodcastDetail] Current episodes count: \(episodes.count)")

═══════════════════════════════════════════════════════════

TEST SEQUENCE:

1. Clean build (Cmd+Shift+K)
2. Run app
3. Tap podcast ONCE (first attempt)
4. Watch console logs carefully
5. Note: Which thread? Does episodes update? Does UI refresh?

Expected patterns:

PATTERN A (Main thread issue):
📡 Thread: BACKGROUND  ← PROBLEM
✅ Updated episodes array: 50
(But UI doesn't update because not on main thread)

PATTERN B (Property wrapper issue):
✅ Updated episodes array: 50
(But @Published missing, so SwiftUI doesn't know to refresh)

PATTERN C (Context issue):
🔓 Podcast context: <NSManagedObjectContext: background>  ← PROBLEM
📊 [PodcastDetail] Podcast: nil
(Background context object not accessible in view)

PATTERN D (Timing issue):
🔓 Opening sheet  ← Opens immediately
📊 View appeared
📡 Starting load  ← Loads after sheet opens
✅ Loaded 50 episodes
(Sheet opens before podcast/episodes are ready)

═══════════════════════════════════════════════════════════

OUTPUT: Add to docs/player-time-debug.md

Section: Root Cause Analysis - "Works on 2nd Attempt"
- Which pattern matches the logs?
- Specific line numbers where problem occurs
- Exact fix needed (not skeleton loading)
- Whether it's a threading, state, or timing issue

This is HIGH priority - fix root cause, not symptoms