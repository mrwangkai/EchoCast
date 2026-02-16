//
//  LibraryView.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI
import CoreData

struct LibraryView: View {
    @Binding var selectedTab: Int
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = NoteViewModel()

    @State private var showingSortOptions = false
    @State private var selectedNote: NoteEntity?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Search and Filter Section
                    searchAndFilterSection
                        .padding(.horizontal, EchoSpacing.screenPadding)
                        .padding(.top, 12)

                    // Notes Section
                    if viewModel.notes.isEmpty {
                        emptyStateView
                    } else {
                        notesSection
                            .padding(.horizontal, EchoSpacing.screenPadding)
                    }
                }
            }
            .background(Color.echoBackground)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.echoBackground, for: .navigationBar)
            .preferredColorScheme(.dark)
            .confirmationDialog("Sort By", isPresented: $showingSortOptions) {
                Button("Date (Newest First)") {
                    viewModel.sortOrder = .dateDescending
                }
                Button("Date (Oldest First)") {
                    viewModel.sortOrder = .dateAscending
                }
                Button("Show Title") {
                    viewModel.sortOrder = .showTitle
                }
                Button("Timestamp") {
                    viewModel.sortOrder = .timestamp
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note)
        }
    }

    // MARK: - Search and Filter Section

    private var searchAndFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.echoTextTertiary)
                    .font(.system(size: 17))
                TextField("Search notes...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextPrimary)
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.echoTextTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.searchFieldBackground)
            .cornerRadius(8)

            // Filter and Sort buttons
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.filterPriority.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.filterPriority ? "star.fill" : "star")
                            .font(.system(size: 12))
                        Text("Priority")
                            .font(.caption2Medium())
                    }
                    .foregroundColor(viewModel.filterPriority ? Color.mintAccent : .echoTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(viewModel.filterPriority ? Color.mintAccent.opacity(0.2) : Color.searchFieldBackground)
                    .cornerRadius(8)
                }

                Button(action: {
                    showingSortOptions = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12))
                        Text("Sort")
                            .font(.caption2Medium())
                    }
                    .foregroundColor(.echoTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.searchFieldBackground)
                    .cornerRadius(8)
                }

                Spacer()

                Text("\(viewModel.notes.count) notes")
                    .font(.caption2Medium())
                    .foregroundColor(.echoTextTertiary)
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Notes")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
            
            ForEach(viewModel.groupedNotes(), id: \.key) { show, notes in
                VStack(alignment: .leading, spacing: 12) {
                    // Section header with show title
                    Text(show)
                        .font(.subheadlineRounded())
                        .foregroundColor(.echoTextSecondary)
                        .padding(.top, 8)
                    
                    // Notes in this show
                    ForEach(notes) { note in
                        NoteCardView(note: note)
                            .onTapGesture {
                                selectedNote = note
                            }
                            .contextMenu {
                                Button(action: {
                                    viewModel.togglePriority(note)
                                }) {
                                    Label(
                                        note.isPriority ? "Remove Priority" : "Mark as Priority",
                                        systemImage: note.isPriority ? "star.slash" : "star.fill"
                                    )
                                }
                                
                                Button(role: .destructive, action: {
                                    viewModel.deleteNote(note)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 100)

            Image(systemName: "note.text")
                .font(.system(size: 72))
                .foregroundColor(.mintAccent)

            VStack(spacing: 8) {
                Text("No notes yet")
                    .font(.title2Echo())
                    .foregroundColor(.echoTextPrimary)

                Text("Start listening to podcasts and take notes as you go")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Find a podcast CTA
            Button(action: {
                selectedTab = 1  // Switch to Browse tab
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                    Text("Find a podcast")
                        .font(.bodyRoundedMedium())
                }
                .foregroundColor(.mintButtonText)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, EchoSpacing.screenPadding)
                .padding(.vertical, 16)
                .background(Color.mintButtonBackground)
                .cornerRadius(12)
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
            .buttonStyle(.plain)

            Spacer()
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LibraryView(selectedTab: .constant(0))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
