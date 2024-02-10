//
//  RealmDBService.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 16.10.2023.
//

import Foundation
import RealmSwift

class RealmDBService: GenericDBService {
    private static let instance = RealmDBService()
    static var shared: GenericDBService { get { self.instance } }
    
    private var realm: Realm?
    
    private init() {
        do {
            self.realm = try Realm()
        }
        catch { print("Realm error: \(error.localizedDescription)") }
    }
    
    func fetchTodoTasks() -> [GenericTodoTask]? {
        guard let realm else { return nil }
        var tasks: Results<RealmTodoTask>?
        do {
            try realm.write {
                tasks = realm.objects(RealmTodoTask.self)
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
        guard let tasks else { return nil }
        return tasks.filter { $0.parentTask == nil }.sorted(by: { $0.dueDate < $1.dueDate })
    }
    
    func fetchTask(by id: UUID) -> GenericTodoTask? {
        guard let realm else { return nil }
        var tasks: Results<RealmTodoTask>?
        do {
            try realm.write {
                tasks = realm.objects(RealmTodoTask.self)
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
        guard let tasks else { return nil }
        return tasks.filter { $0.id == id }.first
    }
    
    func createTodoTask(name: String, dueDate: Date, isNotificationEnabled: Bool = false) -> GenericTodoTask? {
        guard let realm else { return nil }
        var newTodoTask: RealmTodoTask?
        do {
            try realm.write {
                newTodoTask = RealmTodoTask()
                if let newTodoTask {
                    newTodoTask.name = name
                    newTodoTask.dueDate = dueDate
                    newTodoTask.isDone = false
                    newTodoTask.isNotificationEnabled = isNotificationEnabled
        
                    realm.add(newTodoTask)
                    
                    if newTodoTask.isNotificationEnabled {
                        NotificationService.shared.createLocalNotification(for: newTodoTask)
                    }
                }
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
        return newTodoTask
    }
    
    func renameTodoTask(todoTask: GenericTodoTask, newName: String) {
        guard let realm, let todoTask = todoTask as? RealmTodoTask else { return }
        do {
            try realm.write {
                todoTask.name = newName
                
                if todoTask.isNotificationEnabled {
                    NotificationService.shared.recreateLocalNotification(for: todoTask)
                }
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
    }
    
    func deleteTodoTask(todoTask: GenericTodoTask) {
        guard let realm, 
              let todoTask = todoTask as? RealmTodoTask,
              let subtasks = fetchTodoSubtasks(for: todoTask) else { return }
        do {
            try realm.write {
                if todoTask.isNotificationEnabled {
                    NotificationService.shared.cancelLocalNotification(for: todoTask)
                }
                
                subtasks.forEach {
                    if let subtask = $0 as? RealmTodoTask {
                        realm.delete(subtask)
                    }
                }
                realm.delete(todoTask)
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
    }
    
    func toggleTaskStatus(todoTask: GenericTodoTask) {
        guard let realm, 
              let todoTask = todoTask as? RealmTodoTask,
              let subtasks = fetchTodoSubtasks(for: todoTask) else { return }
        do {
            try realm.write {
                todoTask.isDone.toggle()
                if subtasks.count > 0 {
                    for var subtask in subtasks {
                        subtask.isDone = todoTask.isDone
                    }
                }
                
                if todoTask.isDone && todoTask.isNotificationEnabled {
                    NotificationService.shared.cancelLocalNotification(for: todoTask)
                } else if !todoTask.isDone && todoTask.isNotificationEnabled {
                    NotificationService.shared.createLocalNotification(for: todoTask)
                }
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
    }
    
    func fetchTodoSubtasks(for todoTask: GenericTodoTask) -> [GenericTodoTask]? {
        guard let realm else { return nil }
        var subtasks: [RealmTodoTask]?
        do {
            try realm.write {
                subtasks = realm.objects(RealmTodoTask.self).filter {
                    guard let parentTask = $0.parentTask else { return false }
                    return parentTask.id == todoTask.id
                }
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
        return subtasks
    }
    
    func createTodoSubtask(for todoTask: GenericTodoTask, name: String) -> GenericTodoTask? {
        guard let realm, let todoTask = todoTask as? RealmTodoTask else { return nil }
        var newTodoSubtask: RealmTodoTask?
        do {
            try realm.write {
                newTodoSubtask = RealmTodoTask()
                if let newTodoSubtask {
                    newTodoSubtask.name = name
                    newTodoSubtask.isDone = false
                    newTodoSubtask.parentTask = todoTask
                    realm.add(newTodoSubtask)
                    todoTask.isDone = false
                    
                    if todoTask.isNotificationEnabled {
                        NotificationService.shared.cancelLocalNotification(for: todoTask)
                    }
                }
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
        return newTodoSubtask
    }
    
    func deleteTodoSubtask(todoSubtask: GenericTodoTask) {
        guard let realm, let todoSubtask = todoSubtask as? RealmTodoTask else { return }
        do {
            try realm.write {
                if let parentTask = todoSubtask.parentTask {
                    realm.delete(todoSubtask)
                    let completedSubtasks = parentTask.subtasks.filter { $0.isDone == true }
                    parentTask.isDone = completedSubtasks.count == parentTask.subtasks.count
                    
                    if parentTask.isDone && parentTask.isNotificationEnabled {
                        NotificationService.shared.cancelLocalNotification(for: parentTask)
                    } else if !parentTask.isDone && parentTask.isNotificationEnabled {
                        NotificationService.shared.createLocalNotification(for: parentTask)
                    }
                }
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
    }
    
    func toggleSubtaskStatus(todoSubtask: GenericTodoTask) {
        guard let realm, 
              let todoSubtask = todoSubtask as? RealmTodoTask,
              let parentTask = todoSubtask.parentTask,
              let subtasks = fetchTodoSubtasks(for: parentTask) else { return }
        do {
            try realm.write {
                todoSubtask.isDone.toggle()
                let completedSubtasks = subtasks.filter { $0.isDone == true }
                parentTask.isDone = completedSubtasks.count == subtasks.count
                
                if parentTask.isDone && parentTask.isNotificationEnabled {
                    NotificationService.shared.cancelLocalNotification(for: parentTask)
                } else if !parentTask.isDone && parentTask.isNotificationEnabled {
                    NotificationService.shared.createLocalNotification(for: parentTask)
                }
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
    }
    
    func toggleIsNotificationEnabled(todoTask: GenericTodoTask) {
        guard let realm,
              let todoTask = todoTask as? RealmTodoTask else { return }
        do {
            try realm.write {
                todoTask.isNotificationEnabled.toggle()
                
                if todoTask.isNotificationEnabled {
                    NotificationService.shared.createLocalNotification(for: todoTask)
                } else {
                    NotificationService.shared.cancelLocalNotification(for: todoTask)
                }
            }
        }
        catch { print("Realm error: \(error.localizedDescription)") }
    }
}
