//
//  IncomingTasksObservable.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 24.10.2023.
//

import Foundation

class IncomingTasksObservable: ObservableObject {
    static let shared = IncomingTasksObservable()
    private init() {}
    
    @Published var incomingTasks: [IncomingTask] = []
    
    func addTask(_ incomingTask: IncomingTask) {
        incomingTasks.append(incomingTask)
        objectWillChange.send()
        TasksListObservable.shared.refresh()
    }
}
