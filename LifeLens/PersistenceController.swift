//
//  PersistenceController.swift
//  LifeLens
//
//  Created by Basorge on 15/08/2025.
//


// Persistence.swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews if needed
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            // In production, handle this more gracefully
            #if DEBUG
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            #else
            print("Core Data preview save error: \(nsError)")
            #endif
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LifeLens")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // In production, handle this more gracefully
                #if DEBUG
                fatalError("Unresolved error \(error), \(error.userInfo)")
                #else
                print("Core Data failed to load: \(error.localizedDescription)")
                #endif
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}