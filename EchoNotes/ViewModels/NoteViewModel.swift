//
//  NoteViewModel.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import Foundation
import CoreData
import Combine

class NoteViewModel: ObservableObject {
    @Published var notes: [NoteEntity] = []
    @Published var searchText: String = ""
    @Published var filterPriority: Bool = false
    @Published var sortOrder: SortOrder = .dateDescending

    private let persistenceController: PersistenceController
    private var cancellables = Set<AnyCancellable>()

    enum SortOrder {
        case dateAscending
        case dateDescending
        case showTitle
        case timestamp
    }

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        fetchNotes()
        setupSearchSubscription()
    }

    // MARK: - Fetching

    func fetchNotes() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()

        // Apply filters
        var predicates: [NSPredicate] = []

        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(
                format: "noteText CONTAINS[cd] %@ OR showTitle CONTAINS[cd] %@ OR episodeTitle CONTAINS[cd] %@",
                searchText, searchText, searchText
            )
            predicates.append(searchPredicate)
        }

        if filterPriority {
            let priorityPredicate = NSPredicate(format: "isPriority == YES")
            predicates.append(priorityPredicate)
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        // Apply sort
        let sortDescriptor: NSSortDescriptor
        switch sortOrder {
        case .dateAscending:
            sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        case .dateDescending:
            sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        case .showTitle:
            sortDescriptor = NSSortDescriptor(key: "showTitle", ascending: true)
        case .timestamp:
            sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
        }
        request.sortDescriptors = [sortDescriptor]

        do {
            notes = try context.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
            notes = []
        }
    }

    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchNotes()
            }
            .store(in: &cancellables)

        $filterPriority
            .sink { [weak self] _ in
                self?.fetchNotes()
            }
            .store(in: &cancellables)

        $sortOrder
            .sink { [weak self] _ in
                self?.fetchNotes()
            }
            .store(in: &cancellables)
    }

    // MARK: - CRUD Operations

    func createNote(
        showTitle: String?,
        episodeTitle: String?,
        timestamp: String?,
        noteText: String?,
        isPriority: Bool = false,
        tags: [String] = [],
        sourceApp: String? = nil
    ) {
        persistenceController.createNote(
            showTitle: showTitle,
            episodeTitle: episodeTitle,
            timestamp: timestamp,
            noteText: noteText,
            isPriority: isPriority,
            tags: tags,
            sourceApp: sourceApp
        )
        fetchNotes()
    }

    func updateNote(_ note: NoteEntity) {
        persistenceController.updateNote(note)
        fetchNotes()
    }

    func deleteNote(_ note: NoteEntity) {
        persistenceController.deleteNote(note)
        fetchNotes()
    }

    func togglePriority(_ note: NoteEntity) {
        note.isPriority.toggle()
        updateNote(note)
    }

    // MARK: - Grouping

    func groupedNotes() -> [(key: String, notes: [NoteEntity])] {
        let grouped = Dictionary(grouping: notes) { note -> String in
            note.showTitle ?? "Unknown Show"
        }
        return grouped.sorted { $0.key < $1.key }.map { (key: $0.key, notes: $0.value) }
    }
}
