//
//  Persistence.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 13.10.2023.
//

import CoreData

class CoreDataDBService: GenericDBService {
    private static let instance = CoreDataDBService()
    static var shared: GenericDBService { get { self.instance } }
    
    // MARK: - Service different entities contexts
    private var serviceObjectContexts: [CoreDataDBServiceObjectContextProtocol] = []
    
    private func loadServiceObjectContext<O: NSManagedObject>(for type: O.Type) -> CoreDataDBServiceObjectContextProtocol {
        let context = CoreDataDBServiceObjectContext<O>(self.context)
        serviceObjectContexts.append(context)
        return context
    }
    
    func getServiceObjectContext<O: NSManagedObject>(for type: O.Type) -> CoreDataDBServiceObjectContextProtocol {
        for objectContext in serviceObjectContexts {
            if objectContext.self is CoreDataDBServiceObjectContext<O> {
                return objectContext
            }
        }
        return loadServiceObjectContext(for: type)
    }
    
    
    private let inMemory: Bool
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TasksDBApp")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        //persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext { self.persistentContainer.viewContext }
    
    private init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }
    
    static var preview: CoreDataDBService = {
        let result = CoreDataDBService(inMemory: true)
        let viewContext = result.persistentContainer.viewContext
        for i in 0..<10 {
            let newTask = CoreDataTodoTask(context: viewContext)
            newTask.name = "TodoTask \(i)"
            newTask.dueDate = Date().advanced(by: TimeInterval(i * 100_000_000))
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    func fetchTodoTasks() -> [GenericTodoTask]? {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoTask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoTask> else { return nil }
        var tasks: [CoreDataTodoTask]?
        serviceContext.write { context in
            do {
                tasks = try context.fetch(.init(entityName: "CoreDataTodoTask"))
            } catch { print("Error: \(error.localizedDescription)") }
        }
        return tasks?.sorted(by: { $0.dueDate ?? Date() < $1.dueDate  ?? Date()} )
    }
    
    func fetchTask(by id: UUID) -> GenericTodoTask? {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoTask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoTask> else { return nil }
        var tasks: [CoreDataTodoTask]?
        serviceContext.write { context in
            do {
                tasks = try context.fetch(.init(entityName: "CoreDataTodoTask"))
            } catch { print("Error: \(error.localizedDescription)") }
        }
        guard let tasks else { return nil }
        return tasks.filter { $0.storedID == id }.first
    }
    
    func createTodoTask(name: String, dueDate: Date, isNotificationEnabled: Bool = false) -> GenericTodoTask? {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoTask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoTask> else { return nil }
        var newTodoTask: CoreDataTodoTask?
        serviceContext.write { context in
            newTodoTask = CoreDataTodoTask(context: context)
            if let newTodoTask {
                newTodoTask.storedID = UUID()
                newTodoTask.name = name
                newTodoTask.dueDate = dueDate
                newTodoTask.isDone = false
                newTodoTask.isNotificationEnabled = isNotificationEnabled
                
                if newTodoTask.isNotificationEnabled {
                    NotificationService.shared.createLocalNotification(for: newTodoTask)
                }
            }
        }
        return newTodoTask
    }
    
    func renameTodoTask(todoTask: GenericTodoTask, newName: String) {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoTask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoTask>,
              let todoTask = todoTask as? CoreDataTodoTask else { return }
        serviceContext.write { context in
            todoTask.name = newName
            
            if todoTask.isNotificationEnabled {
                NotificationService.shared.recreateLocalNotification(for: todoTask)
            }
        }
    }
    
    func deleteTodoTask(todoTask: GenericTodoTask) {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoTask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoTask>,
              let todoTask = todoTask as? CoreDataTodoTask else { return }
        serviceContext.write { context in
            if todoTask.isNotificationEnabled {
                NotificationService.shared.cancelLocalNotification(for: todoTask)
            }
            
            serviceContext.delete(todoTask)
        }
    }
    
    func toggleTaskStatus(todoTask: GenericTodoTask) {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoTask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoTask>,
              let todoTask = todoTask as? CoreDataTodoTask else { return }
        serviceContext.write { context in
            todoTask.isDone.toggle()
            if let subtasks = todoTask.subtasks,
               subtasks.count > 0 {
                for subtask in subtasks {
                    if var subtask = subtask as? GenericTodoTask {
                        subtask.isDone = todoTask.isDone
                    }
                }
            }
            
            if todoTask.isDone && todoTask.isNotificationEnabled {
                NotificationService.shared.cancelLocalNotification(for: todoTask)
            } else if !todoTask.isDone && todoTask.isNotificationEnabled {
                NotificationService.shared.createLocalNotification(for: todoTask)
            }
        }
    }
    
    func fetchTodoSubtasks(for todoTask: GenericTodoTask) -> [GenericTodoTask]? {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoSubtask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoSubtask> else { return nil }
        var subtasks: [CoreDataTodoSubtask]?
        serviceContext.write { context in
            do {
                subtasks = try context.fetch(.init(entityName: "CoreDataTodoSubtask")).filter {
                    if let parentTask = $0.parentTask {
                        return parentTask.isEqual(todoTask)
                    }
                    return false
                }
            } catch { print("Error: \(error.localizedDescription)") }
        }
        return subtasks
    }
    
    func createTodoSubtask(for todoTask: GenericTodoTask, name: String) -> GenericTodoTask? {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoSubtask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoSubtask>,
              let todoTask = todoTask as? CoreDataTodoTask else { return nil }
        var newTodoSubtask: CoreDataTodoSubtask?
        serviceContext.write { context in
            newTodoSubtask = CoreDataTodoSubtask(context: context)
            if let newTodoSubtask {
                newTodoSubtask.storedID = UUID()
                newTodoSubtask.parentTask = todoTask
                newTodoSubtask.name = name
                newTodoSubtask.isDone = false
                if let parentTask = newTodoSubtask.parentTask {
                    parentTask.isDone = false
                    
                    if parentTask.isNotificationEnabled {
                        NotificationService.shared.cancelLocalNotification(for: parentTask)
                    }
                }
            }
        }
        return newTodoSubtask
    }
    
    func deleteTodoSubtask(todoSubtask: GenericTodoTask) {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoSubtask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoSubtask>,
              let todoSubtask = todoSubtask as? CoreDataTodoSubtask else { return }
        serviceContext.write { context in
            serviceContext.delete(todoSubtask)
            if let parentTask = todoSubtask.parentTask,
               let allSubtasks = parentTask.subtasks {
                let completedSubtasks = allSubtasks.filter { ($0 as? CoreDataTodoSubtask)?.isDone == true }
                parentTask.isDone = completedSubtasks.count == allSubtasks.count
                
                if parentTask.isDone && parentTask.isNotificationEnabled {
                    NotificationService.shared.cancelLocalNotification(for: parentTask)
                } else if !parentTask.isDone && parentTask.isNotificationEnabled {
                    NotificationService.shared.createLocalNotification(for: parentTask)
                }
            }
        }
    }
    
    func toggleSubtaskStatus(todoSubtask: GenericTodoTask) {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoSubtask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoSubtask>,
              let todoSubtask = todoSubtask as? CoreDataTodoSubtask else { return }
        serviceContext.write { context in
            todoSubtask.isDone.toggle()
            if let parentTask = todoSubtask.parentTask,
               let allSubtasks = parentTask.subtasks {
                let completedSubtasks = allSubtasks.filter { ($0 as? CoreDataTodoSubtask)?.isDone == true }
                parentTask.isDone = completedSubtasks.count == allSubtasks.count
                
                if parentTask.isDone && parentTask.isNotificationEnabled {
                    NotificationService.shared.cancelLocalNotification(for: parentTask)
                } else if !parentTask.isDone && parentTask.isNotificationEnabled {
                    NotificationService.shared.createLocalNotification(for: parentTask)
                }
            }
        }
    }
    
    func toggleIsNotificationEnabled(todoTask: GenericTodoTask) {
        guard let serviceContext = getServiceObjectContext(for: CoreDataTodoTask.self) as? CoreDataDBServiceObjectContext<CoreDataTodoTask>,
              let todoTask = todoTask as? CoreDataTodoTask else { return }
        serviceContext.write { context in
            todoTask.isNotificationEnabled.toggle()
            
            if todoTask.isNotificationEnabled {
                NotificationService.shared.createLocalNotification(for: todoTask)
            } else {
                NotificationService.shared.cancelLocalNotification(for: todoTask)
            }
        }
    }
}
