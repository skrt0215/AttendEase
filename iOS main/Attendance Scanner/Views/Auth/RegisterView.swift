//
//  RegisterView.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var studentID = ""
    @State private var selectedRole = UserRole.student
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    TextField("Full Name", text: $name)
                        .textContentType(.name)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Picker("Role", selection: $selectedRole) {
                        Text("Student").tag(UserRole.student)
                        Text("Professor").tag(UserRole.professor)
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedRole == UserRole.student {
                        TextField("Student ID", text: $studentID)
                            .textContentType(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        Text("Student ID must be \(ValidationRules.studentIDLength) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if !password.isEmpty && password != confirmPassword {
                        Text("Passwords do not match")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button {
                        Task {
                            await authViewModel.signUp(
                                email: email,
                                password: password,
                                name: name,
                                role: selectedRole,
                                studentID: selectedRole == UserRole.student ? studentID : nil
                            )
                        }
                    } label: {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .foregroundStyle(.white)
                        }
                    }
                    .background(isFormValid ? Color.blue : Color.gray)
                    .cornerRadius(10)
                    .disabled(!isFormValid || authViewModel.isLoading)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Already have an account? Sign In")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= ValidationRules.minPasswordLength &&
        (selectedRole == UserRole.professor || studentID.count == ValidationRules.studentIDLength)
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
}
