//
//  LoginView.swift
//  TasksDBApp
//
//  Created by Kyrylo Derkach on 30.10.2023.
//

import SwiftUI
import KeychainAccess

struct LoginView: View {
    @State var email: String = ""
    @State var password: String = ""
    @Binding var isLoggedIn: Bool
    
    @State var isShowingAlert = false
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Log In") {
                let keychain = AppKeychain.shared
                if let savedEmail = try? keychain.getString("email"),
                   let savedPassword = try? keychain.getString("password"),
                   email == savedEmail && password == savedPassword {
                    isLoggedIn = true
                } else {
                    NetworkService.login(email: email, password: password) { isSuccessful in
                        if isSuccessful {
                            try? keychain.set(email, key: "email")
                            try? keychain.set(password, key: "password")
                            isLoggedIn = true
                        } else {
                            isShowingAlert = true
                        }
                    }
                }
            }
            .alert("Incorrect login or password", isPresented: $isShowingAlert) {
                Button("OK") {
                    isShowingAlert = false
                }
            }
            .padding()

            Spacer()
        }
        .padding()
    }
}
