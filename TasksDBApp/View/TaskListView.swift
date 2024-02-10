//
//  ContentView.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 13.10.2023.
//

import SwiftUI
import CoreData

struct TaskListView: View {
    var databaseService: GenericDBService

    //@State var tasks: [GenericTodoTask]
    @ObservedObject var tasks: TasksListObservable
    
    @State private var isAddingTask = false
    @State private var name: String = ""
    @State private var dueDate: Date = Date()
    @State private var isShowingInbox = false
    @State private var isShowingSecureTasks = false

    var body: some View {
        NavigationView {
            List {
                ForEach(tasks.tasks, id: \.id) { task in
                    NavigationLink(destination: TaskDetailedView(databaseService: databaseService, task: task, isDone: task.isDone, isNotificationEnabled: getIsNotificationEnabled(in: task)).onDisappear {
                        update()
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(describeTask(task: task)[0])
                                    .font(.title)
                                Text("Due: \(describeTask(task: task)[1])")
                            }
                            Spacer()
                            ZStack {
                                Circle()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(task.isDone ? .blue : .white)
                                    .overlay(
                                        Circle()
                                            .stroke(.placeholder, lineWidth: 1)
                                    )
                                if task.isDone {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                }
                            }
                            .onTapGesture {
                                toggleTaskStatus(task)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteTasks)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { self.isShowingInbox = true }) {
                        Label("Inbox", systemImage: "tray.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { self.isShowingSecureTasks = true }) {
                        Label("Secure", systemImage: "lock.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: { 
                        dueDate = Date()
                        isAddingTask = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .background {
                if isShowingInbox {
                    NavigationLink(destination: InboxView(), isActive: $isShowingInbox) {
                        EmptyView()
                    }
                } else if isShowingSecureTasks {
                    NavigationLink(destination: SecureTaskListView(), isActive: $isShowingSecureTasks) {
                        EmptyView()
                    }
                } else {
                    EmptyView()
                }
            }
            Text("Select an item")
        }
        .sheet(isPresented: $isAddingTask) {
            VStack {
                TextField("Name", text: $name)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                Button("Add", action: addTask)
            }
            .padding(.all, 50)
        }
    }
    
    private func describeTask(task: any GenericTodoTask) -> [String] {
        if let task = task as? CoreDataTodoTask,
              let name = task.name,
              let date = task.dueDate {
            return [name, TaskDateFormatter.formatter.string(from: date)]
        } else if let task = task as? RealmTodoTask {
            return [task.name, TaskDateFormatter.formatter.string(from: task.dueDate)]
        }
        return []
    }

    private func addTask() {
        withAnimation {
            DispatchQueue.main.async {
                let name = self.name
                let dueDate = self.dueDate
                databaseService.createTodoTask(name: name, dueDate: dueDate)
                self.name = ""
                self.dueDate = Date()
                self.isAddingTask = false
                update()
            }
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            DispatchQueue.main.async {
                offsets.map { tasks.tasks[$0] }.forEach(databaseService.deleteTodoTask)
                update()
            }
        }
    }
    
    private func update() {
        DispatchQueue.main.async {
            if let updatedTasks = databaseService.fetchTodoTasks() {
                tasks.tasks = updatedTasks
            }
        }
    }
    
    private func toggleTaskStatus(_ task: GenericTodoTask) {
        DispatchQueue.main.async {
            databaseService.toggleTaskStatus(todoTask: task)
            update()
        }
    }
    
    private func getIsNotificationEnabled(in task: GenericTodoTask) -> Bool {
        if let task = task as? CoreDataTodoTask {
            task.isNotificationEnabled
        }
        else if let task = task as? RealmTodoTask {
            task.isNotificationEnabled
        } else {
            false
        }
    }
}

#Preview {
    TaskListView(databaseService: CoreDataDBService.preview, tasks: TasksListObservable.shared.setDatabaseService(databaseService: CoreDataDBService.preview).refresh())
}
