//
//  PodcastDiscoveryView.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI
import CoreData

struct PodcastDiscoveryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default)
    private var savedPodcasts: FetchedResults<PodcastEntity>

    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var showAddRSSSheet: Bool = false
    @State private var rssURL: String = ""
    @State private var isLoadingRSS: Bool = false
    @State private var rssError: String?
    @State private var loadedRSSPodcast: RSSPodcast?
    @State private var selectedPodcast: PodcastEntity?
    @State private var showPodcastDetail = false

    // Mock search results (in production, this would call Listen Notes API)
    private let mockPodcasts = Podcast.samples

    var filteredPodcasts: [Podcast] {
        if searchText.isEmpty {
            return mockPodcasts
        } else {
            return mockPodcasts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search podcasts...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performSearch()
                        }
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

                if isSearching {
                    ProgressView()
                        .padding()
                } else if savedPodcasts.isEmpty && searchText.isEmpty {
                    // Empty state for first-time users
                    EmptyPodcastsView(onAddRSSFeed: {
                        showAddRSSSheet = true
                    })
                } else {
                    List {
                        // Saved podcasts section
                        if !savedPodcasts.isEmpty {
                            Section(header: Text("My Podcasts")) {
                                ForEach(savedPodcasts) { podcast in
                                    SavedPodcastRowView(podcast: podcast)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedPodcast = podcast
                                            showPodcastDetail = true
                                        }
                                }
                                .onDelete(perform: deletePodcast)
                            }
                        }

                        // Search results
                        if !searchText.isEmpty {
                            Section(header: Text("Search Results")) {
                                ForEach(filteredPodcasts) { podcast in
                                    PodcastSearchRowView(podcast: podcast, onAdd: {
                                        addPodcast(podcast)
                                    })
                                }
                            }
                        } else {
                            Section(header: Text("Popular Podcasts")) {
                                ForEach(mockPodcasts) { podcast in
                                    PodcastSearchRowView(podcast: podcast, onAdd: {
                                        addPodcast(podcast)
                                    })
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Podcasts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add URL") {
                        showAddRSSSheet = true
                    }
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
            .sheet(isPresented: $showPodcastDetail) {
                if let podcast = selectedPodcast {
                    PodcastDetailView(podcast: podcast)
                }
            }
        }
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
                    loadedRSSPodcast = podcast
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
        } catch {
            print("Error saving RSS podcast: \(error)")
        }
    }

    // MARK: - Actions

    private func performSearch() {
        isSearching = true
        // In production, call Listen Notes API here
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSearching = false
        }
    }

    private func addPodcast(_ podcast: Podcast) {
        let newPodcast = PodcastEntity(context: viewContext)
        newPodcast.id = podcast.id.uuidString
        newPodcast.title = podcast.title
        newPodcast.author = podcast.author
        newPodcast.podcastDescription = podcast.podcastDescription
        newPodcast.artworkURL = podcast.artworkURL

        do {
            try viewContext.save()
        } catch {
            print("Error saving podcast: \(error)")
        }
    }

    private func deletePodcast(at offsets: IndexSet) {
        offsets.forEach { index in
            let podcast = savedPodcasts[index]
            viewContext.delete(podcast)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error deleting podcast: \(error)")
        }
    }
}

// MARK: - Saved Podcast Row

struct SavedPodcastRowView: View {
    let podcast: PodcastEntity

    var body: some View {
        HStack(spacing: 12) {
            // Artwork placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                if let title = podcast.title {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                }
                if let author = podcast.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Podcast Search Row

struct PodcastSearchRowView: View {
    let podcast: Podcast
    let onAdd: () -> Void
    @FetchRequest(sortDescriptors: []) private var savedPodcasts: FetchedResults<PodcastEntity>

    private var isAdded: Bool {
        savedPodcasts.contains { $0.id == podcast.id.uuidString }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Artwork placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(podcast.title)
                    .font(.headline)
                    .lineLimit(2)
                if let author = podcast.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                if let description = podcast.podcastDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundColor(isAdded ? .green : .blue)
                    .font(.title2)
            }
            .disabled(isAdded)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Podcasts View

struct EmptyPodcastsView: View {
    let onAddRSSFeed: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                Text("Welcome to EchoNotes")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Capture timestamped notes while listening to podcasts")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                Button(action: onAddRSSFeed) {
                    HStack {
                        Image(systemName: "link.badge.plus")
                        Text("Add Your First Podcast")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)

                Text("Paste an RSS feed URL to get started")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Add RSS Feed View

struct AddRSSFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var rssURL: String
    @Binding var isLoading: Bool
    @Binding var error: String?
    let onAdd: () -> Void

    // Pre-fill with test URL
    @State private var showTestURL: Bool = false

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

#Preview {
    PodcastDiscoveryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
