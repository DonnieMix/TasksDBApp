//
//  AppDelegateExtension.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 21.10.2023.
//

import Foundation
import UserNotifications
import UIKit
import SwiftUI

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "AcceptAction" {
            if let aps = response.notification.request.content.userInfo["aps"] as? [String: Any],
               let name = aps["name"] as? String,
               let dueDateString = aps["dueDate"] as? String,
               let dueDate = TaskDateFormatter.formatter.date(from: dueDateString) {
                databaseService.createTodoTask(name: name, dueDate: dueDate, isNotificationEnabled: true)
                IncomingTasksObservable.shared.addTask(IncomingTask(name: name, dueDate: dueDate, isAccepted: true))
            }
        } else if response.actionIdentifier == "DeleteAction" {
            print("Task was rejected")
            if let aps = response.notification.request.content.userInfo["aps"] as? [String: Any],
               let name = aps["name"] as? String,
               let dueDateString = aps["dueDate"] as? String,
               let dueDate = TaskDateFormatter.formatter.date(from: dueDateString) {
                IncomingTasksObservable.shared.addTask(IncomingTask(name: name, dueDate: dueDate, isAccepted: false))
            }
        }

        completionHandler()
    }
}
