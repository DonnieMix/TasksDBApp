//
//  CommunicationService.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import Foundation

class NetworkService {
    
    static func login(email: String, password: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://127.0.0.1:8080/auth") else { completion(false); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let dataObject = [
            "email": email,
            "password": password
        ]
        
        do {
            let dataJson = try JSONSerialization.data(withJSONObject: dataObject)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = dataJson
        } catch {
            print("JSON parsing error: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                print("Server responsed with error: \(error.localizedDescription)")
                completion(false)
                return
            } else if let data,
                      let textResponse = String(data: data, encoding: .utf8),
                      let intResponse = Int(textResponse) {
                if intResponse == 200 { completion(true); return }
                else { completion(false); return }
            } else {
                completion(false)
                return
            }
        }.resume()
    }
    
}
