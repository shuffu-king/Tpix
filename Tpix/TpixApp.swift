//
//  TpixApp.swift
//  Tpix
//
//  Created by Ayo Shafau on 11/28/24.
//

import SwiftUI

@main
struct TpixApp: App {
    
    @StateObject var clipboardManager = ClipboardManager()
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager) // Ensure the preview has the ClipboardManager environment object
                .environment(\.managedObjectContext, persistenceController.context)
        }
    }
}
