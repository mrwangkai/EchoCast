//
//  PersistenceController.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for previews
        for i in 0..<5 {
            let note = NoteEntity(context: viewContext)
            note.id = UUID()
            note.showTitle = "Sample Show \(i)"
            note.episodeTitle = "Episode \(i)"
            note.timestamp = "00:\(String(format: "%02d", i * 10)):00"
            note.noteText = "This is a sample note \(i)"
            note.isPriority = i % 2 == 0
            note.tags = "sample,test"
            note.createdAt = Date()
            note.sourceApp = "Preview"
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "EchoNotes")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        // Enable automatic lightweight migration
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Note Operations

    func createNote(
        showTitle: String?,
        episodeTitle: String?,
        timestamp: String?,
        noteText: String?,
        isPriority: Bool = false,
        tags: [String] = [],
        sourceApp: String? = nil
    ) {
        let context = container.viewContext
        let note = NoteEntity(context: context)
        note.id = UUID()
        note.showTitle = showTitle
        note.episodeTitle = episodeTitle
        note.timestamp = timestamp
        note.noteText = noteText
        note.isPriority = isPriority
        note.tags = tags.joined(separator: ",")
        note.createdAt = Date()
        note.sourceApp = sourceApp

        saveContext()
    }

    func updateNote(_ noteEntity: NoteEntity) {
        saveContext()
    }

    func deleteNote(_ noteEntity: NoteEntity) {
        let context = container.viewContext
        context.delete(noteEntity)
        saveContext()
    }

    // MARK: - Podcast Operations

    func createPodcast(
        title: String,
        author: String?,
        description: String?,
        artworkURL: String?
    ) {
        let context = container.viewContext
        let podcast = PodcastEntity(context: context)
        podcast.id = UUID().uuidString
        podcast.title = title
        podcast.author = author
        podcast.podcastDescription = description
        podcast.artworkURL = artworkURL

        saveContext()
    }

    // MARK: - Core Data Saving

    private func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: - NoteEntity Extensions
extension NoteEntity {
    var tagsArray: [String] {
        get {
            guard let tags = tags, !tags.isEmpty else { return [] }
            return tags.split(separator: ",").map(String.init)
        }
        set {
            tags = newValue.joined(separator: ",")
        }
    }

    var displayTitle: String {
        if let show = showTitle, let episode = episodeTitle {
            return "\(show) - \(episode)"
        } else if let show = showTitle {
            return show
        } else if let episode = episodeTitle {
            return episode
        } else {
            return "Untitled Note"
        }
    }
}
