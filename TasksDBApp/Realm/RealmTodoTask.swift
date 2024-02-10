//
//  TodoTask.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 16.10.2023.
//

import Foundation
import RealmSwift

class RealmTodoTask: Object, GenericTodoTask {
    
    @Persisted var id: UUID = UUID()
    @Persisted var name: String = ""
    @Persisted var dueDate: Date = Date()
    @Persisted var isDone: Bool = false
    @Persisted var parentTask: RealmTodoTask? = nil
    @Persisted var isNotificationEnabled: Bool = false
    
    let subtasks = LinkingObjects(fromType: RealmTodoTask.self, property: "parentTask")
}
