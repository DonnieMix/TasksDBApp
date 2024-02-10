//
//  DateFormatter.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 24.10.2023.
//

import Foundation

class TaskDateFormatter {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}
