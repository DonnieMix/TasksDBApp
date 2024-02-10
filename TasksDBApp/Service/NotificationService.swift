//
//  NotificationService.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 21.10.2023.
//

import Foundation
import UserNotifications
import PushKit

class NotificationService {
    // MARK: - Singleton
    static let shared = NotificationService()
    
    private init() { registerCategories() }
    
    // MARK: - Fields
    let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Notification handling
    func createLocalNotification(for task: GenericTodoTask) {
        guard !hasNotification(task) else { return }
        
        let title = "\"\(getName(of: task))\" task deadline"
        let body = "Now is due time of \"\(getName(of: task))\""
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: getDueDate(of: task))
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error creating notification: \(error.localizedDescription)")
            }
        }
    }
    
    func createIncomingNotification(name: String, dueDate dueDateString: String, category: String) {
        if let dueDate = TaskDateFormatter.formatter.date(from: dueDateString) {
            let title = "Incoming Task: \(name)"
            let body = "Due Date: \(TaskDateFormatter.formatter.string(from: dueDate))"
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default
            
            content.categoryIdentifier = category
            content.userInfo = ["name" : name, "dueDate" : dueDateString]
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Error creating notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func cancelLocalNotification(for task: GenericTodoTask) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    func recreateLocalNotification(for task: GenericTodoTask) {
        cancelLocalNotification(for: task)
        createLocalNotification(for: task)
    }
    
    // MARK: - Private additional functions
    private func getName(of task: GenericTodoTask) -> String {
        if let task = task as? CoreDataTodoTask,
           let name = task.name {
            name
        }
        else if let task = task as? RealmTodoTask {
            task.name
        } else {
            "N/A"
        }
    }
    private func getDueDate(of task: GenericTodoTask) -> Date {
        if let task = task as? CoreDataTodoTask,
           let dueDate = task.dueDate {
            dueDate
        }
        else if let task = task as? RealmTodoTask {
            task.dueDate
        } else {
            Date()
        }
    }
    
    private func hasNotification(_ task: GenericTodoTask) -> Bool {
        var hasNotification = false
        notificationCenter.getPendingNotificationRequests { notificationRequests in
            for request in notificationRequests {
                if request.identifier == task.id.uuidString {
                    hasNotification = true
                    return
                }
            }
        }
        return hasNotification
    }
    
    private func registerCategories() {
        let acceptAction = UNNotificationAction(
            identifier: "AcceptAction",
            title: "Accept",
            options: UNNotificationActionOptions.foreground
        )
        
        let deleteAction = UNNotificationAction(
            identifier: "DeleteAction",
            title: "Delete",
            options: UNNotificationActionOptions.destructive
        )
        
        let incomingTaskCategory = UNNotificationCategory(
            identifier: "IncomingTaskCategory",
            actions: [acceptAction, deleteAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: .customDismissAction
        )
        notificationCenter.setNotificationCategories([incomingTaskCategory])
    }
}
