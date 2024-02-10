//
//  CoreDataTodoTaskExtension.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 17.10.2023.
//

import Foundation

extension CoreDataTodoTask: GenericTodoTask {
    public var id: UUID { storedID ?? UUID() }
}

extension CoreDataTodoSubtask: GenericTodoTask {
    public var id: UUID { storedID ?? UUID() }
}
