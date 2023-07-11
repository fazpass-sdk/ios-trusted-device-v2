//
//  Dummy_AppApp.swift
//  Dummy App
//
//  Created by Andri nova riswanto on 26/06/23.
//

import SwiftUI

@main
struct Dummy_AppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
