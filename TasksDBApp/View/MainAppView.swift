//
//  MainAppView.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    
    @State private var isLoggedIn = false
    
    var body: some View {
        if isLoggedIn || AppKeychain.hasUserRecord() && AppKeychain.isRelevant() {
            TaskListView(
                databaseService: appDelegate.databaseService,
                tasks: TasksListObservable.shared
                    .setDatabaseService(databaseService: appDelegate.databaseService)
                    .refresh()
            )
        } else {
            LoginView(isLoggedIn: $isLoggedIn)
        }
    }
}

#Preview {
    MainAppView()
}
