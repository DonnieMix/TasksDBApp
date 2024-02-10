//
//  InboxView.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 24.10.2023.
//

import SwiftUI

struct InboxView: View {
    @ObservedObject var incomingTasks = IncomingTasksObservable.shared
    
    var body: some View {
        List {
            ForEach(incomingTasks.incomingTasks) { task in
                HStack {
                    VStack {
                        Text(task.name)
                            .font(.title)
                        Text(TaskDateFormatter.formatter.string(from: task.dueDate))
                            .font(.subheadline)
                    }
                    Spacer()
                }
                .background {
                    task.isAccepted ? Color(.green).opacity(0.5) : Color(.red).opacity(0.5)
                }
            }
        }
    }
}
