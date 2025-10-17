//
//  LoginView.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegister = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "person.badge.clock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(.blue)
                
                Text("AttendEase")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("NFC Attendance System")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button {
                        Task {
                            await authViewModel.signIn(email: email, password: password)
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.white)
                        }
                    }
                    .background(email.isEmpty || password.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    
                    Button {
                        showingRegister = true
                    } label: {
                        Text("Don't have an account? Sign Up")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationDestination(isPresented: $showingRegister) {
                RegisterView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
