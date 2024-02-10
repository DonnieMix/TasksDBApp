//
//  AppKeychain.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import Foundation
import KeychainAccess

class AppKeychain {
    static let shared = Keychain(service: "ua.edu.ukma.derkach.TasksDBApp")
    
    private init() {}
    
    static func clear() {
        do {
            try AppKeychain.shared.removeAll()
        }
        catch { print("Unable to clear keychain: \(error.localizedDescription)") }
    }
    
    static func hasUserRecord() -> Bool {
        let keychain = AppKeychain.shared
        if let _ = try? keychain.getString("email"),
           let _ = try? keychain.getString("password") {
            return true
        } else {
            return false
        }
    }
    
    
    static func isRelevant() -> Bool {
        let keychain = AppKeychain.shared
        if let email = try? keychain.getString("email"),
           let password = try? keychain.getString("password") {
            let semaphore = DispatchSemaphore(value: 0)
            var result = false
            NetworkService.login(email: email, password: password) { success in
                result = success
                semaphore.signal()
            }
            semaphore.wait()
            return result
        } else {
            return false
        }
    }
}
