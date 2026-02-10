# Fix: "View All" Sheet Second-Time Loading Issue

**Date:** February 10, 2026  
**Issue:** "View all" sheet shows only 10 cached podcasts on first tap, requires second tap to work  
**Root Cause:** Sheet receives static data snapshot instead of observable data source  
**Priority:** HIGH - Critical UX issue affecting browse experience  
**Estimated Time:** 15-20 minutes

---

## 🎯 Problem Summary

### Current Broken Behavior:
1. User taps "View all" on Comedy genre
2. Sheet opens showing only 10 podcasts (cached from carousel)
3. User closes sheet (frustrated)
4. User taps "View all" again
5. Now it works - shows 50 podcasts

### Root Cause:
```swift
// BROKEN CODE:
.sheet(isPresented: $showingViewAll) {
    if let genre = viewAllGenre {
        GenreViewAllView(
            genre: genre,
            podcasts: viewModel.genreResults[genre] ?? [],  // ← Only 10 cached!
            onPodcastTap: { ... }
        )
    }
}
```

**Why this fails:**
- `viewModel.genreResults[genre]` contains only 10 podcasts from the carousel
- This static array is passed to `GenreViewAllView`
- Even if you load more data in `.task`, the original array doesn't update
- Sheet has no connection to the live data source

---

## ✅ Solution: Pass Observable Data Source

**Key insight from episode player fix:** Sheet needs access to the **data source**, not a static snapshot.

### Three-Part Fix:

1. **Update GenreViewAllView** to accept and observe viewModel
2. **Update sheet call** to pass viewModel reference
3. **Add loadMoreForGenre** method to viewModel

---

## PART 1: Update GenreViewAllView

**File:** `PodcastDiscoveryView.swift` (or wherever GenreViewAllView is defined)

**Find the current GenreViewAllView struct** (search for `struct GenreViewAllView`):

**Replace entirely with:**

```swift
struct GenreViewAllView: View {
    let genre: PodcastGenre
    @ObservedObject var viewModel: PodcastBrowseViewModel  // ← NOW OBSERVABLE
    let onPodcastTap: (iTunesPodcast) -> Void
    
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    // Computed property - always reflects current viewModel state
    var podcasts: [iTunesPodcast] {
        viewModel.genreResults[genre] ?? []
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && podcasts.count <= 10 {
                    // Show loading state while fetching
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.mintAccent)
                        Text("Loading more podcasts...")
                            .font(.bodyEcho())
                            .foregroundColor(.echoTextSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.echoBackground)
                } else {
                    // Show grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(podcasts) { podcast in
                                VStack(spacing: 8) {
                                    // Podcast artwork
                                    AsyncImage(url: URL(string: podcast.artworkUrl600 ?? podcast.artworkUrl100 ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 120, height: 120)
                                    .cornerRadius(8)
                                    
                                    // Title
                                    Text(podcast.collectionName)
                                        .font(.captionRounded())
                                        .foregroundColor(.echoTextPrimary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 120)
                                }
                                .onTapGesture {
                                    print("🎧 [ViewAll] Podcast tapped: \(podcast.collectionName)")
                                    onPodcastTap(podcast)
                                    dismiss()
                                }
                            }
                        }
                        .padding(EchoSpacing.screenPadding)
                    }
                    .background(Color.echoBackground)
                }
            }
            .navigationTitle(genre.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.mintAccent)
                }
            }
        }
        .task {
            // Load more podcasts when sheet appears
            print("📊 [ViewAll] Sheet appeared for: \(genre.displayName)")
            print("📊 [ViewAll] Current podcast count: \(podcasts.count)")
            
            // Only load if we have carousel count or less
            if podcasts.count <= 10 {
                isLoading = true
                print("📡 [ViewAll] Need to load more (have \(podcasts.count), want 50)")
                
                await viewModel.loadMoreForGenre(genre, limit: 50)
                
                isLoading = false
                print("✅ [ViewAll] Loading complete - now have \(podcasts.count) podcasts")
            } else {
                print("✅ [ViewAll] Already have enough podcasts (\(podcasts.count))")
            }
        }
    }
}
```

**Key changes explained:**

1. **`@ObservedObject var viewModel`**: Now observes the viewModel, so UI updates when data changes
2. **Computed `podcasts` property**: Always reflects current viewModel state (not a static snapshot)
3. **Loading state**: Shows `ProgressView` while fetching, preventing blank screen
4. **`.task` modifier**: Loads data when view appears, only if needed (≤10 podcasts)
5. **Comprehensive logging**: Track exactly what's happening

---

## PART 2: Update Sheet Call Site

**File:** `PodcastDiscoveryView.swift`

**Find the sheet modifier** (search for `.sheet(isPresented: $showingViewAll)`):

**Replace with:**

```swift
.sheet(isPresented: $showingViewAll) {
    if let genre = viewAllGenre {
        GenreViewAllView(
            genre: genre,
            viewModel: viewModel,  // ← PASS VIEWMODEL REFERENCE
            onPodcastTap: { podcast in
                print("🎧 [Browse] Opening podcast from view all: \(podcast.collectionName)")
                selectedPodcast = podcast
                showingPodcastDetail = true
            }
        )
    }
}
```

**Key change:** Pass `viewModel: viewModel` instead of `podcasts: viewModel.genreResults[genre] ?? []`

---

## PART 3: Add loadMoreForGenre Method

**File:** `PodcastBrowseViewModel.swift` (or wherever PodcastBrowseViewModel is defined)

**Add this method to the PodcastBrowseViewModel class:**

```swift
/// Load more podcasts for a specific genre (used by "View all" sheet)
func loadMoreForGenre(_ genre: PodcastGenre, limit: Int) async {
    print("📡 [ViewModel] loadMoreForGenre called")
    print("📡 [ViewModel] Genre: \(genre.displayName)")
    print("📡 [ViewModel] Limit: \(limit)")
    
    do {
        print("📡 [ViewModel] Fetching from API...")
        let podcasts = try await PodcastAPIService.shared.getTopPodcasts(
            genreId: genre.rawValue,
            limit: limit
        )
        
        print("📡 [ViewModel] Fetched \(podcasts.count) podcasts from API")
        
        await MainActor.run {
            print("📡 [ViewModel] Updating genreResults on main thread...")
            genreResults[genre] = podcasts
            print("✅ [ViewModel] genreResults updated - now have \(podcasts.count) podcasts")
        }
    } catch {
        print("❌ [ViewModel] Failed to load more podcasts: \(error)")
        print("❌ [ViewModel] Error details: \(error.localizedDescription)")
    }
}
```

**What this does:**
- Fetches more podcasts from iTunes API (50 instead of 10)
- Updates `genreResults[genre]` on main thread
- Triggers SwiftUI to refresh any views observing this data
- Comprehensive logging for debugging

---

## 🧪 Testing Protocol

### Clean Build First:
```
Cmd+Shift+K (Clean Build Folder)
Cmd+B (Build)
Cmd+R (Run)
```

### Test Scenario 1: First Time "View All"

1. Launch app
2. Go to Browse tab
3. Wait for carousels to load
4. Tap "View all" on **Comedy** genre (first time)

**Expected console logs:**
```
📊 [ViewAll] Sheet appeared for: Comedy
📊 [ViewAll] Current podcast count: 10
📡 [ViewAll] Need to load more (have 10, want 50)
📡 [ViewModel] loadMoreForGenre called
📡 [ViewModel] Genre: Comedy
📡 [ViewModel] Limit: 50
📡 [ViewModel] Fetching from API...
📡 [ViewModel] Fetched 50 podcasts from API
📡 [ViewModel] Updating genreResults on main thread...
✅ [ViewModel] genreResults updated - now have 50 podcasts
✅ [ViewAll] Loading complete - now have 50 podcasts
```

**Expected UI:**
- Brief loading indicator (~1 second)
- Grid displays with 50 podcasts
- Smooth transition, no blank screen

### Test Scenario 2: Second Time "View All"

1. Close the sheet (Done button)
2. Tap "View all" on **Comedy** again

**Expected console logs:**
```
📊 [ViewAll] Sheet appeared for: Comedy
📊 [ViewAll] Current podcast count: 50
✅ [ViewAll] Already have enough podcasts (50)
```

**Expected UI:**
- No loading indicator (data already loaded)
- Grid appears immediately
- All 50 podcasts visible

### Test Scenario 3: Different Genre

1. Close the sheet
2. Tap "View all" on **News** genre (first time)

**Expected console logs:**
```
📊 [ViewAll] Sheet appeared for: News
📊 [ViewAll] Current podcast count: 10
📡 [ViewAll] Need to load more (have 10, want 50)
📡 [ViewModel] loadMoreForGenre called
📡 [ViewModel] Genre: News
...
✅ [ViewAll] Loading complete - now have 50 podcasts
```

**Expected UI:**
- Loading indicator appears
- Loads 50 News podcasts
- No interference with Comedy data

### Test Scenario 4: Podcast Tap in "View All"

1. In any "View all" sheet
2. Tap a podcast

**Expected console logs:**
```
🎧 [ViewAll] Podcast tapped: [Podcast Name]
🎧 [Browse] Opening podcast from view all: [Podcast Name]
```

**Expected UI:**
- "View all" sheet closes
- Podcast detail sheet opens
- Correct podcast displayed

---

## 🐛 Troubleshooting

### Issue: Still shows 10 podcasts

**Check:**
1. Did you pass `viewModel: viewModel` (not `podcasts: array`)?
2. Is `genreResults` marked as `@Published` in viewModel?
3. Check console logs - does API call succeed?

**Debug:**
```swift
// Add to loadMoreForGenre:
print("Current genreResults keys: \(genreResults.keys.map { $0.displayName })")
```

### Issue: Loading indicator never disappears

**Check:**
1. Does API call complete (check logs)?
2. Is error thrown and caught?
3. Is `isLoading = false` line reached?

**Debug:**
```swift
// Add after MainActor.run:
print("About to set isLoading = false")
```

### Issue: Podcasts don't update

**Check:**
1. Is viewModel passed as `@ObservedObject`?
2. Is `podcasts` a computed property (not stored)?
3. Is `genreResults` dictionary actually updating?

**Debug:**
```swift
// Add to genreResults didSet in viewModel:
didSet {
    print("genreResults changed - keys: \(genreResults.keys.map { $0.displayName })")
}
```

---

## 📊 What This Achieves

✅ **First tap works** - No more "try again" UX  
✅ **Proper loading state** - User knows something is happening  
✅ **Live data connection** - View reflects viewModel changes  
✅ **Smart caching** - Only loads when needed (≤10 podcasts)  
✅ **Observable pattern** - SwiftUI reactive updates work correctly  
✅ **Comprehensive logging** - Easy to diagnose issues  

---

## 🎓 Key Lessons

### The Pattern That Works:
```swift
// ✅ GOOD: Observable source
struct ChildView: View {
    @ObservedObject var viewModel: ViewModel
    
    var data: [Item] {
        viewModel.items  // Computed - always fresh
    }
}

.sheet {
    ChildView(viewModel: viewModel)  // Pass source
}
```

### The Anti-Pattern That Fails:
```swift
// ❌ BAD: Static snapshot
struct ChildView: View {
    let data: [Item]  // Frozen at creation
}

.sheet {
    ChildView(data: viewModel.items)  // Snapshot
}
```

---

## 🚀 Next Steps After Fix

Once this works:

1. **Apply same pattern to other sheets** that load data
2. **Consider pre-loading** popular genres (Comedy, News, True Crime)
3. **Add pull-to-refresh** in "View all" for explicit user refresh
4. **Add error handling UI** if API fails (not just console logs)

---

## Commit Message

```
Fix: "View all" sheet now loads 50 podcasts on first tap

- Pass viewModel reference instead of static array to GenreViewAllView
- Add @ObservedObject to enable reactive updates
- Add loadMoreForGenre() method to viewModel
- Show loading indicator during fetch
- Add comprehensive logging for debugging

Resolves "works on 2nd attempt" bug in browse carousels.
```

---

**Time estimate:** 15-20 minutes with Claude Code  
**Risk level:** Low - isolated change, well-tested pattern  
**Dependencies:** None - self-contained fix
