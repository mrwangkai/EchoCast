//
//  EchoNotesApp.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI

@main
struct EchoNotesApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
