//
//  SecureTask.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import Foundation

class SecureTask: Codable, Identifiable {
    let id: UUID
    let name: String
    let dueDate: Date
    var isDone: Bool
    
    init(name: String, dueDate: Date, isDone: Bool = false) {
        self.id = UUID()
        self.name = name
        self.dueDate = dueDate
        self.isDone = isDone
    }
}
