//
//  GenericTodoTask.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 16.10.2023.
//

import Foundation

protocol GenericTodoTask {
    var id: UUID { get }
    var isDone: Bool { get set }
}
