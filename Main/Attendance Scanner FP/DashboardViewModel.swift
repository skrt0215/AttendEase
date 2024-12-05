//
//  DashboardViewModel.swift
//  Attendance Scanner FP
//
//  Created by Steven Kurt on 12/4/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class DashboardViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private let db = Firestore.firestore()
    
    func fetchCourses(for user: User) {
        guard let userEmail = user.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            errorMessage = "User email is invalid or missing."
            print("Error: User email is invalid or missing.")
            return
        }
        
        print("Fetching courses for email: \(userEmail)")
        
        db.collection("UserCourses")
            .whereField("studentEmail", isEqualTo: userEmail)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("Error fetching course associations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    self.errorMessage = "No courses found. Please contact administrator."
                    self.isLoading = false
                    print("No valid courses found for email: \(userEmail)")
                    return
                }
                
                let fetchedCourses = documents.compactMap { document -> Course? in
                    guard let courseId = document.data()["courseId"] as? String,
                          let courseName = document.data()["courseName"] as? String else {
                        return nil
                    }
                    
                    return Course(id: courseId, name: courseName, status: "On time")
                }
                
                DispatchQueue.main.async {
                    self.courses = fetchedCourses
                    self.isLoading = false
                    
                    if self.courses.isEmpty {
                        self.errorMessage = "No courses found. Please contact administrator."
                        print("No valid courses parsed for email: \(userEmail)")
                    } else {
                        print("Courses successfully loaded: \(self.courses)")
                        for course in self.courses {
                            print("Course -> ID: \(course.id), Name: \(course.name)")
                        }
                    }
                }
            }
    }
    
    func listenToAuthState() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }

            if let user = user {
                self.fetchCourses(for: user)
            } else {
                self.courses = []
                print("User is logged out")
            }
        }
    }
}

struct Course: Identifiable, Equatable {
    let id: String
    let name: String
    let status: String
}

extension Course {
    var statusColor: Color {
        switch status {
        case "On time":
            return .green
        case "Late":
            return .yellow
        case "Absent":
            return .red
        case "Early":
            return .blue
        default:
            return .gray
        }
    }
}
