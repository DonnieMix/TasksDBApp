//
//  BiometricsService.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import Foundation
import LocalAuthentication

class BiometricsService {
    static let shared: BiometricsService = BiometricsService()
    
    private init() {}
    
    func isBiometricAuthenticationAvailable() -> Bool {
        let context = LAContext()
        var authError: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError)
    }

    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to access secure tasks") { success, error in
            if success {
                completion(success)
            } else {
                guard let error = error else { return }
                print("Bio authentication error: \(error.localizedDescription)")
            }
        }
    }
}
