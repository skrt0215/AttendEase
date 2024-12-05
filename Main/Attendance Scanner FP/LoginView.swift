//
//  LoginView.swift
//  Attendance Scanner FP
//
//  Created by Steven Kurt on 12/4/24.
//

import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Binding var authState: AuthState
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false

    var body: some View {
        VStack {
            Text("Login")
                .font(.largeTitle)
                .bold()
                .padding()

            TextField("NYIT Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
                .frame(maxWidth: 300)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .frame(maxWidth: 300)

            Button(action: {
                handleLogin()
            }) {
                Text("Log In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }

            Button(action: {
                authState = .signedOut
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
            }
        }
    }

    func handleLogin() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                errorMessage = error.localizedDescription
                showAlert = true
                return
            }

            if let user = authResult?.user {
                print("User logged in successfully: \(user.uid)")
                authState = .signedIn(user)
            }
        }
    }
}

