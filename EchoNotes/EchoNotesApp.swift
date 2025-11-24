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
    // TODO: Uncomment when DeepLinkManager.swift is added to Xcode project
    // @StateObject private var deepLinkManager = DeepLinkManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // TODO: Uncomment when DeepLinkManager.swift is added to Xcode project
                // .environmentObject(deepLinkManager)
                // .onOpenURL { url in
                //     _ = deepLinkManager.handleURL(url)
                // }
        }
    }
}
