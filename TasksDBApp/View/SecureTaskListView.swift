//
//  SecureTaskListView.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import SwiftUI
import LocalAuthentication

struct SecureTaskListView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var isUnlocked = false
    
    @ObservedObject var secureTasks: SecureTasksListObservable = SecureTasksListObservable.shared
    
    @State private var isAddingTask = false
    @State private var name: String = ""
    @State private var dueDate: Date = Date()
    
    var body: some View {
        if isUnlocked {
            List {
                ForEach(secureTasks.tasks) { task in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(task.name)
                                .font(.title)
                            Text("Due: \(TaskDateFormatter.formatter.string(from: task.dueDate))")
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
                            toggleTask(task)
                        }
                    }
                }
                .onDelete(perform: deleteTasks)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        dueDate = Date()
                        isAddingTask = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                VStack {
                    TextField("Name", text: $name)
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    Button("Add", action: addTask)
                }
                .padding(.all, 50)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                secureTasks.unloadTasks()
                isUnlocked = false
            }
        } else {
            Button("Unlock using FaceID") {
                authenticateWithBiometrics()
            }
        }
    }
    
    private func addTask() {
        withAnimation {
            DispatchQueue.main.async {
                let name = self.name
                let dueDate = self.dueDate
                secureTasks.write {
                    let secureTask = SecureTask(name: name, dueDate: dueDate)
                    secureTasks.addTask(secureTask)
                }
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
                secureTasks.write {
                    offsets.map { secureTasks.tasks[$0] }.forEach(secureTasks.deleteTask)
                }
                update()
            }
        }
    }
    
    private func toggleTask(_ task: SecureTask) {
        DispatchQueue.main.async {
            secureTasks.write {
                secureTasks.toggleTask(task)
            }
            update()
        }
    }
    
    private func update() {
        DispatchQueue.main.async {
            secureTasks.tasks = KeychainService.shared.fetchSecureTasks()
        }
    }
    
    private func authenticateWithBiometrics() {
        let biometricsService = BiometricsService.shared
        
        DispatchQueue.main.async {
            if biometricsService.isBiometricAuthenticationAvailable() {
                biometricsService.authenticateWithBiometrics { success in
                    if success {
                        DispatchQueue.main.async {
                            isUnlocked = true
                            secureTasks.loadTasks()
                        }
                    }
                }
            } 
            else {
                print("Couldn't authenticate with biometrics")
            }
        }
    }
}
