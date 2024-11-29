//
//  PersistenceController.swift
//  Tpix
//
//  Created by Ayo Shafau on 11/28/24.
//

import CoreData

struct PersistenceController {
    
    static let shared = PersistenceController()
        let container: NSPersistentContainer

        init(inMemory: Bool = false) {
            container = NSPersistentContainer(name: "ClipStorage") // Replace with your Core Data model name

            // App Group URL
            if let appGroupURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: "group.com.TpixApp.shared")?
                .appendingPathComponent("ClipStorage.sqlite") {
                let storeDescription = NSPersistentStoreDescription(url: appGroupURL)
                container.persistentStoreDescriptions = [storeDescription]
            }

            if inMemory {
                container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            }

            container.loadPersistentStores { _, error in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        }

        var context: NSManagedObjectContext {
            container.viewContext
        }
}
