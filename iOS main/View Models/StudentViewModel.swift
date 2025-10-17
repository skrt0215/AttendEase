//
//  StudentViewModel.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthService.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        isLoading = true
        
        Task {
            do {
                if authService.isAuthenticated {
                    currentUser = try await authService.fetchCurrentUser()
                    isAuthenticated = currentUser != nil
                } else {
                    isAuthenticated = false
                    currentUser = nil
                }
            } catch {
                errorMessage = error.localizedDescription
                isAuthenticated = false
                currentUser = nil
            }
            
            isLoading = false
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            currentUser = try await authService.fetchCurrentUser()
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, name: String, role: String, studentID: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await authService.signUp(
                email: email,
                password: password,
                name: name,
                role: role,
                studentID: studentID
            )
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
