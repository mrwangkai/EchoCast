//
//  PodcastDiscoveryView.swift
//  EchoNotes
//
//  Redesigned browse view with genre carousels
//

import SwiftUI
import CoreData

struct PodcastDiscoveryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = PodcastBrowseViewModel()
    @State private var selectedGenre: PodcastGenre? = nil
    @State private var showingViewAll = false
    @State private var viewAllGenre: PodcastGenre?
    @State private var searchText = ""
    @State private var showAddRSSSheet = false
    @State private var rssURL: String = ""
    @State private var isLoadingRSS = false
    @State private var rssError: String?

    // Note: removed selectedPodcast/showingPodcastDetail - using different approach

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, EchoSpacing.screenPadding)
                        .padding(.vertical, 12)

                    // Genre chips carousel
                    genreChipsScrollView

                    // Podcasts by category OR search results
                    if searchText.isEmpty {
                        categoryCarouselsView
                    } else {
                        searchResultsView
                    }
                }
            }
            .background(Color.echoBackground)
            .navigationTitle("Browse")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add URL") {
                        showAddRSSSheet = true
                    }
                }
            }
            .task {
                print("📡 [Browse] Loading all genres...")
                await viewModel.loadAllGenres()
                print("✅ [Browse] All genres loaded")
            }
            .sheet(isPresented: $showingViewAll) {
                if let genre = viewAllGenre {
                    GenreViewAllView(
                        genre: genre,
                        podcasts: viewModel.genreResults[genre] ?? [],
                        onPodcastTap: { podcast in
                            addAndOpenPodcast(podcast)
                        }
                    )
                }
            }
            .sheet(isPresented: $showAddRSSSheet) {
                AddRSSFeedView(
                    rssURL: $rssURL,
                    isLoading: $isLoadingRSS,
                    error: $rssError,
                    onAdd: loadRSSFeed
                )
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.echoTextTertiary)
                .font(.system(size: 17))

            TextField("Search podcasts", text: $searchText)
                .textFieldStyle(.plain)
                .font(.bodyEcho())
                .foregroundColor(.echoTextPrimary)
                .onChange(of: searchText) { oldValue, newValue in
                    if !newValue.isEmpty {
                        Task {
                            await viewModel.search(query: newValue)
                        }
                    }
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.echoTextTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.searchFieldBackground)
        .cornerRadius(8)
    }

    // MARK: - Genre Chips Carousel

    private var genreChipsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PodcastGenre.mainGenres) { genre in
                    GenreChip(
                        genre: genre,
                        isSelected: selectedGenre == genre,
                        action: {
                            print("🎯 [Browse] Genre tapped: \(genre.displayName)")
                            selectedGenre = genre
                            // Scroll to that section (future enhancement)
                        }
                    )
                }
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
            .padding(.vertical, 12)
        }
        .background(Color.echoBackground)
    }

    // MARK: - Category Carousels View

    private var categoryCarouselsView: some View {
        VStack(spacing: 24) {
            ForEach(PodcastGenre.mainGenres.filter { $0 != .all }) { genre in
                CategoryCarouselSection(
                    genre: genre,
                    podcasts: Array((viewModel.genreResults[genre] ?? []).prefix(10)),
                    isLoading: viewModel.isLoadingGenre(genre),
                    onViewAll: {
                        print("🔍 [Browse] View all tapped for: \(genre.displayName)")
                        viewAllGenre = genre
                        showingViewAll = true
                    },
                    onPodcastTap: { podcast in
                        print("🎧 [Browse] Podcast tapped: \(podcast.displayName)")
                        addAndOpenPodcast(podcast)
                    }
                )
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Search Results View

    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Search Results")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
                .padding(.horizontal, EchoSpacing.screenPadding)

            // Grid of search results
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.searchResults) { podcast in
                    PodcastArtworkCard(podcast: podcast)
                        .onTapGesture {
                            print("🎧 [Browse] Search result tapped: \(podcast.displayName)")
                            addAndOpenPodcast(podcast)
                        }
                }
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
        }
        .padding(.top, 8)
    }

    // MARK: - RSS Feed Loading

    private func loadRSSFeed() {
        guard !rssURL.isEmpty else { return }

        isLoadingRSS = true
        rssError = nil

        Task {
            do {
                let podcast = try await PodcastRSSService.shared.fetchPodcast(from: rssURL)
                await MainActor.run {
                    saveRSSPodcast(podcast)
                    isLoadingRSS = false
                    showAddRSSSheet = false
                    rssURL = ""
                }
            } catch {
                await MainActor.run {
                    rssError = error.localizedDescription
                    isLoadingRSS = false
                }
            }
        }
    }

    private func saveRSSPodcast(_ rssPodcast: RSSPodcast) {
        let newPodcast = PodcastEntity(context: viewContext)
        newPodcast.id = rssPodcast.id.uuidString
        newPodcast.title = rssPodcast.title
        newPodcast.author = rssPodcast.author
        newPodcast.podcastDescription = rssPodcast.description
        newPodcast.artworkURL = rssPodcast.imageURL
        newPodcast.feedURL = rssPodcast.feedURL

        do {
            try viewContext.save()
            print("✅ [Browse] RSS podcast saved")
        } catch {
            print("❌ [Browse] Error saving RSS podcast: \(error)")
        }
    }

    private func addAndOpenPodcast(_ podcast: iTunesSearchService.iTunesPodcast) {
        print("💾 [Browse] Adding podcast to Core Data: \(podcast.displayName)")

        // Check if podcast already exists in Core Data
        let fetchRequest: NSFetchRequest<PodcastEntity> = PodcastEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", podcast.id)

        do {
            let existing = try viewContext.fetch(fetchRequest)

            if existing.isEmpty {
                // Create new podcast entity
                let entity = PodcastEntity(context: viewContext)
                entity.id = podcast.id
                entity.title = podcast.displayName
                entity.author = podcast.artistName
                entity.artworkURL = podcast.artworkUrl600
                entity.feedURL = podcast.feedUrl
                entity.podcastDescription = nil
                entity.isFollowing = false

                try viewContext.save()
                print("✅ [Browse] Saved new podcast to Core Data")
                print("📚 [Browse] Podcast saved - find it in Library")
            } else {
                print("ℹ️ [Browse] Podcast already exists in Core Data")
                print("📚 [Browse] Podcast already in Library")
            }
        } catch {
            print("❌ [Browse] Failed to check/save podcast: \(error)")
        }
    }
}

// MARK: - Category Carousel Section

struct CategoryCarouselSection: View {
    let genre: PodcastGenre
    let podcasts: [iTunesSearchService.iTunesPodcast]
    let isLoading: Bool
    let onViewAll: () -> Void
    let onPodcastTap: (iTunesSearchService.iTunesPodcast) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(genre.displayName)
                    .font(.title2Echo())
                    .foregroundColor(.echoTextPrimary)

                Spacer()

                if !podcasts.isEmpty {
                    Button(action: onViewAll) {
                        Text("View all")
                            .font(.bodyRoundedMedium())
                            .foregroundColor(.mintAccent)
                    }
                }
            }
            .padding(.horizontal, EchoSpacing.screenPadding)

            // Horizontal carousel (10 podcasts, artwork only, no corner radius)
            if isLoading {
                HStack(spacing: 12) {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(Color.noteCardBackground.opacity(0.3))
                            .frame(width: 120, height: 120)
                    }
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
            } else if podcasts.isEmpty {
                Text("No podcasts available")
                    .font(.captionRounded())
                    .foregroundColor(.echoTextTertiary)
                    .padding(.horizontal, EchoSpacing.screenPadding)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(podcasts) { podcast in
                            PodcastArtworkCard(podcast: podcast)
                                .onTapGesture {
                                    onPodcastTap(podcast)
                                }
                        }
                    }
                    .padding(.horizontal, EchoSpacing.screenPadding)
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.noteCardBackground.opacity(0.3))
                )
                .padding(.bottom, 16)  // 16-24px bottom spacing
            }
        }
    }
}

// MARK: - Podcast Artwork Card (No Corner Radius, Artwork Only)

struct PodcastArtworkCard: View {
    let podcast: iTunesSearchService.iTunesPodcast

    var body: some View {
        AsyncImage(url: URL(string: podcast.artworkUrl600 ?? "")) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.noteCardBackground)
                    .frame(width: 120, height: 120)
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipped()
            case .failure:
                Rectangle()
                    .fill(Color.noteCardBackground)
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundColor(.echoTextTertiary)
                    }
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 120, height: 120)
        // NO corner radius as per Figma spec
    }
}

// MARK: - Genre View All

struct GenreViewAllView: View {
    let genre: PodcastGenre
    let podcasts: [iTunesSearchService.iTunesPodcast]
    let onPodcastTap: (iTunesSearchService.iTunesPodcast) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(podcasts) { podcast in
                        VStack(spacing: 8) {
                            PodcastArtworkCard(podcast: podcast)

                            Text(podcast.displayName)
                                .font(.captionRounded())
                                .foregroundColor(.echoTextPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 120)
                        }
                        .onTapGesture {
                            print("🎧 [Browse] Podcast tapped in view all: \(podcast.displayName)")
                            onPodcastTap(podcast)
                            dismiss()
                        }
                    }
                }
                .padding(EchoSpacing.screenPadding)
            }
            .background(Color.echoBackground)
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
    }
}

// MARK: - Add RSS Feed View (existing, kept for compatibility)

struct AddRSSFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var rssURL: String
    @Binding var isLoading: Bool
    @Binding var error: String?
    let onAdd: () -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("RSS Feed URL")) {
                    TextField("https://example.com/feed.xml", text: $rssURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    Button("Use Test Feed (Multiverse Radio)") {
                        rssURL = "http://multiverseradio.ca/feed/feed.xml"
                    }
                    .font(.caption)
                }

                Section(header: Text("About RSS Feeds")) {
                    Text("Add podcasts by pasting their RSS feed URL. This allows EchoNotes to track episodes and create timestamped notes while you listen.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if let error = error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Podcast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(rssURL.isEmpty || isLoading)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading podcast feed...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(Color(.systemGray4))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
}

// MARK: - Genre Chip Component (existing)

struct GenreChip: View {
    let genre: PodcastGenre
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: genre.iconName)
                    .font(.system(size: 14))

                Text(genre.displayName)
                    .font(.subheadlineRounded())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.mintAccent : Color.noteCardBackground)
            .foregroundColor(isSelected ? Color.mintButtonText : Color.echoTextPrimary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PodcastDiscoveryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
