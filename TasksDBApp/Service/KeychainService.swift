//
//  KeychainService.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import Foundation

class KeychainService {
    static let shared: KeychainService = KeychainService()
    
    private init() {}
    
    private let keychain = AppKeychain.shared
    private let secureTasksKey = "SecureTasks"
    
    func saveSecureTasks(_ tasks: [SecureTask]) {
        if let encodedData = try? JSONEncoder().encode(tasks) {
            keychain[data: secureTasksKey] = encodedData
        }
    }

    func fetchSecureTasks() -> [SecureTask] {
        guard let encodedData = keychain[data: secureTasksKey],
              let tasks = try? JSONDecoder().decode([SecureTask].self, from: encodedData) 
        else { return [] }
        
        return tasks
    }
}
