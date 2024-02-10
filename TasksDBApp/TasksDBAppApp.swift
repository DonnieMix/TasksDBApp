//
//  TasksDBAppApp.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 13.10.2023.
//

import SwiftUI
import CoreData

@main
struct TasksDBAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainAppView()
        }
    }

}
