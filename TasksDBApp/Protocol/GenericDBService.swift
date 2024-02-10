//
//  GenericDBService.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 13.10.2023.
//

import Foundation

protocol GenericDBService {
    static var shared: GenericDBService { get }
    
    // MARK: - TodoTask
    func fetchTodoTasks() -> [GenericTodoTask]?
    
    func fetchTask(by id: UUID) -> GenericTodoTask?
    
    @discardableResult
    func createTodoTask(name: String, dueDate: Date, isNotificationEnabled: Bool) -> GenericTodoTask?
    
    func renameTodoTask(todoTask: GenericTodoTask, newName: String)
    
    func deleteTodoTask(todoTask: GenericTodoTask)
    
    func toggleTaskStatus(todoTask: GenericTodoTask)
    
    func toggleIsNotificationEnabled(todoTask: GenericTodoTask)
    
    // MARK: - TodoSubtask
    func fetchTodoSubtasks(for todoTask: GenericTodoTask) -> [GenericTodoTask]?
    
    @discardableResult
    func createTodoSubtask(for todoTask: GenericTodoTask, name: String) -> GenericTodoTask?
    
    func deleteTodoSubtask(todoSubtask: GenericTodoTask)
    
    func toggleSubtaskStatus(todoSubtask: GenericTodoTask)
}

// MARK: - Extension for default parameter
extension GenericDBService {
    @discardableResult
    func createTodoTask(name: String, dueDate: Date, isNotificationEnabled: Bool = false) -> GenericTodoTask? {
        createTodoTask(name: name, dueDate: dueDate, isNotificationEnabled: isNotificationEnabled)
    }
}
