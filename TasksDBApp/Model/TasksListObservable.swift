//
//  TasksListObservable.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 24.10.2023.
//

import Foundation

class TasksListObservable: ObservableObject {
    static let shared = TasksListObservable()
    private init() {}
    
    private var databaseService: GenericDBService?
    
    @Published var tasks: [GenericTodoTask] = []
    
    @discardableResult
    func setDatabaseService(databaseService: GenericDBService) -> TasksListObservable {
        self.databaseService = databaseService
        return self
    }
    
    @discardableResult
    func refresh() -> TasksListObservable {
        guard let databaseService else { return self }
        tasks = databaseService.fetchTodoTasks() ?? []
        objectWillChange.send()
        return self
    }
}
