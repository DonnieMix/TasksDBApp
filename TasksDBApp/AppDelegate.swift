//
//  AppDelegate.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 21.10.2023.
//

import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    let databaseService: GenericDBService = CoreDataDBService.shared
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.badge, .sound, .alert]) { granted, error in
            if let error = error {
                print("Notifications authorization error: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        UNUserNotificationCenter.current().delegate = self
        
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
            if let aps = userInfo["aps"] as? [AnyHashable : Any],
               let name = aps["name"] as? String,
               let dueDate = aps["dueDate"] as? String,
               let category = aps["category"] as? String {
                NotificationService.shared.createIncomingNotification(name: name, dueDate: dueDate, category: category)
            }
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken
            .reduce("", { $0 + String(format: "%02x", $1)})
        //print(token)
    }
}
