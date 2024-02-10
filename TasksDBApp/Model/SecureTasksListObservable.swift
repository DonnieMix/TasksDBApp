//
//  SecureTasksListObservable.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import Foundation

class SecureTasksListObservable: ObservableObject {
    static let shared = SecureTasksListObservable()
    private init() {}
    
    @Published var tasks: [SecureTask] = []
    
    func loadTasks() {
        tasks = KeychainService.shared.fetchSecureTasks()
    }
    
    func unloadTasks() {
        tasks = []
    }
    
    func write(_ internalAction: () -> Void) {
        internalAction()
        KeychainService.shared.saveSecureTasks(tasks)
    }
    
    func addTask(_ secureTask: SecureTask) {
        tasks.append(secureTask)
        objectWillChange.send()
    }
    
    func deleteTask(_ secureTask: SecureTask) {
        for i in 0..<tasks.count {
            if tasks[i].id == secureTask.id {
                tasks.remove(at: i)
                return
            }
        }
    }
    
    func toggleTask(_ secureTask: SecureTask) {
        for i in 0..<tasks.count {
            if tasks[i].id == secureTask.id {
                tasks[i].isDone.toggle()
            }
        }
    }
}
