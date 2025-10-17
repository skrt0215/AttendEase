//
//  ContentView.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 11/25/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isLoading {
                ProgressView()
            } else if authViewModel.isAuthenticated, let user = authViewModel.currentUser {
                if user.isStudent {
                    StudentHomeView()
                        .environmentObject(authViewModel)
                } else if user.isProfessor {
                    ProfessorHomeView()
                        .environmentObject(authViewModel)
                }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
