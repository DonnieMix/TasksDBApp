//
//  CoreDataDBServiceObjectContext.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 13.10.2023.
//

import Foundation
import CoreData

class CoreDataDBServiceObjectContext<O: NSManagedObject>: CoreDataDBServiceObjectContextProtocol {
    
    let context: NSManagedObjectContext
    
    init(_ context: NSManagedObjectContext) {
        self.context = context
    }
    
    private func saveContext () {
        guard self.context.hasChanges else { return }
        do {
            try self.context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    // MARK: - General CRUD
    func write(_ internalAction: (NSManagedObjectContext) -> Void = { _ in }) {
        internalAction(self.context)
        self.saveContext()
    }

    func delete(_ obj: NSManagedObject) {
        self.context.delete(obj)
    }

    func getAllObjects() -> [O] {
       (try? self.context.fetch(O.fetchRequest()) as? [O]) ?? []
    }

    func get(by predicate: NSPredicate) -> [O] {
        let fetchRequest = O.fetchRequest()
        return (try? self.context.fetch(fetchRequest) as? [O]) ?? []
    }
    
}
