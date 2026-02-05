//
//  LibraryView.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel = NoteViewModel()
    @State private var showingSortOptions = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search notes...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
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

                // Filter buttons
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.filterPriority.toggle()
                    }) {
                        HStack {
                            Image(systemName: viewModel.filterPriority ? "star.fill" : "star")
                            Text("Priority")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.filterPriority ? Color.yellow.opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .foregroundColor(viewModel.filterPriority ? .yellow : .primary)

                    Button(action: {
                        showingSortOptions = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .foregroundColor(.primary)

                    Spacer()

                    Text("\(viewModel.notes.count) notes")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Notes list
                if viewModel.notes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("No notes yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Tap the + button to create your first note")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.groupedNotes(), id: \.key) { show, notes in
                            Section(header: Text(show)) {
                                ForEach(notes) { note in
                                    NoteRowView(note: note, onTogglePriority: {
                                        viewModel.togglePriority(note)
                                    })
                                }
                                .onDelete { indexSet in
                                    indexSet.forEach { index in
                                        viewModel.deleteNote(notes[index])
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            // Focus search bar
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.body)
                                .foregroundColor(.primary)
                        }

                        Button(action: {
                            // TODO: Navigate to Settings
                        }) {
                            Image(systemName: "gearshape")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
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
    }
}

// MARK: - Note Row View

struct NoteRowView: View {
    let note: NoteEntity
    let onTogglePriority: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let episodeTitle = note.episodeTitle {
                    Text(episodeTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                Spacer()
                if note.isPriority {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }

            if let noteText = note.noteText, !noteText.isEmpty {
                Text(noteText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }

            HStack {
                if let timestamp = note.timestamp {
                    Label(timestamp, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                if let createdAt = note.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .swipeActions(edge: .leading) {
            Button(action: onTogglePriority) {
                Label("Priority", systemImage: note.isPriority ? "star.slash" : "star.fill")
            }
            .tint(.yellow)
        }
    }
}

#Preview {
    LibraryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
