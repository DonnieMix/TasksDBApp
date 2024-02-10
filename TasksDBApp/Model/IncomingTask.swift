//
//  IncomingTask.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 24.10.2023.
//

import Foundation

struct IncomingTask: Identifiable {
    var id = UUID()
    
    var name: String
    var dueDate: Date
    var isAccepted: Bool
}
