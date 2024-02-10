//
//  TaskDetailedView.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 16.10.2023.
//

import SwiftUI

struct TaskDetailedView: View {
    var databaseService: GenericDBService
    var notificationService = NotificationService.shared
    
    @State var task: GenericTodoTask
    @State var isDone: Bool
    @State var isNotificationEnabled: Bool
    
    @State private var subtaskName: String = ""
    @State private var subtasks: [GenericTodoTask] = []

    var body: some View {
        VStack {
            HStack {
                TextField("Name", text: Binding(
                    get: {
                        if let coreDataTask = task as? CoreDataTodoTask {
                            return coreDataTask.name ?? ""
                        }
                        else if let realmTask = task as? RealmTodoTask {
                            return realmTask.name
                        }
                        return ""
                    },
                    set: { newValue in
                        if let coreDataTask = task as? CoreDataTodoTask {
                            databaseService.renameTodoTask(todoTask: coreDataTask, newName: newValue)
                        }
                        else if let realmTask = task as? RealmTodoTask {
                            databaseService.renameTodoTask(todoTask: realmTask, newName: newValue)
                        }
                    }
                ))
                .font(.title)
                .padding(.leading)
                Spacer()
                Text("Done:")
                    .font(.title2)
                ZStack {
                    Circle()
                        .frame(width: 30, height: 30)
                        .foregroundColor(isDone ? .blue : .white)
                        .overlay(
                            Circle()
                                .stroke(.placeholder, lineWidth: 1)
                        )
                    if isDone {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    }
                }
                .onTapGesture {
                    toggleTaskStatus()
                }
                .padding(.trailing)
            }
            
            HStack {
                if let coreDataTask = task as? CoreDataTodoTask {
                    Text("Due Date: \(TaskDateFormatter.formatter.string(from: coreDataTask.dueDate ?? Date()))")
                        .padding(.leading)
                }
                else if let realmTask = task as? RealmTodoTask {
                    Text("Due Date: \(TaskDateFormatter.formatter.string(from: realmTask.dueDate))")
                        .padding(.leading)
                }
                Spacer()
            }
            
            Toggle("Notifications", isOn: $isNotificationEnabled)
                .onChange(of: isNotificationEnabled) {
                    handleNotificationToggle(todoTask: task)
                }
                .font(.headline)
                .padding(.all)
                
            Text("Subtasks:")
                .font(.title)
                .padding(.top)

            List {
                ForEach(subtasks, id: \.id) { subtask in
                    HStack {
                            if let coreDataSubtask = subtask as? CoreDataTodoSubtask {
                                Text(coreDataSubtask.name ?? "")
                            } else if let realmSubtask = subtask as? RealmTodoTask {
                                Text(realmSubtask.name)
                            }
                        Spacer()
                        ZStack {
                            Circle()
                                .frame(width: 30, height: 30)
                                .foregroundColor(subtask.isDone ? .blue : .white)
                                .overlay(
                                    Circle()
                                        .stroke(.placeholder, lineWidth: 1)
                                )
                            if subtask.isDone {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .onTapGesture {
                            toggleSubtaskStatus(subtask)
                        }
                    }
                }
                .onDelete(perform: deleteSubtask)
            }

            HStack {
                TextField("Add Subtask", text: $subtaskName)
                Button(action: addSubtask) {
                    Text("Add")
                }
            }
            .padding()
        }
        .onAppear {
            updateSubtasks()
        }
    }
    
    private func toggleTaskStatus() {
        DispatchQueue.main.async {
            databaseService.toggleTaskStatus(todoTask: task)
            updateSubtasks()
        }
    }
    
    private func toggleSubtaskStatus(_ todoSubtask: GenericTodoTask) {
        DispatchQueue.main.async {
            databaseService.toggleSubtaskStatus(todoSubtask: todoSubtask)
            updateSubtasks()
        }
    }

    private func addSubtask() {
        DispatchQueue.main.async {
            if !subtaskName.isEmpty {
                databaseService.createTodoSubtask(for: task, name: subtaskName)
                subtaskName = ""
                updateSubtasks()
            }
        }
    }

    private func updateSubtasks() {
        DispatchQueue.main.async {
            guard let fetchedSubtasks = databaseService.fetchTodoSubtasks(for: task) else { return }
            subtasks = fetchedSubtasks
            isDone = task.isDone
        }
    }

    private func deleteSubtask(offsets: IndexSet) {
        DispatchQueue.main.async {
            offsets.map { subtasks[$0] }.forEach(databaseService.deleteTodoSubtask)
            updateSubtasks()
        }
    }
    
    private func handleNotificationToggle(todoTask: GenericTodoTask) {
        DispatchQueue.main.async {
            databaseService.toggleIsNotificationEnabled(todoTask: task)
        }
    }
}
