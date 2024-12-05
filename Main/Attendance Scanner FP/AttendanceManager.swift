//
//  AttendanceManager.swift
//  Attendance Scanner FP
//
//  Created by Steven Kurt on 12/4/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class AttendanceManager: ObservableObject {
    static let shared = AttendanceManager()
    private let db = Firestore.firestore()
    
    struct AttendanceRecord: Identifiable {
        let id: UUID
        let studentId: String      // Changed to match database
        let studentEmail: String   // Added to match database
        let timestamp: String
        let courseId: String       // Changed to match database
    }
    
    @Published var attendanceHistory: [String: [AttendanceRecord]] = [:]
    
    func markAttendance(course: String, studentID: String, studentEmail: String, timestamp: String, user: User?) {
        // First get courseId based on course name
        let courseId = getCourseId(for: course) // We'll add this helper function
        
        let record = AttendanceRecord(
            id: UUID(),
            studentId: studentID,
            studentEmail: studentEmail,
            timestamp: timestamp,
            courseId: courseId
        )
        
        // Update local storage
        if var history = attendanceHistory[course] {
            history.append(record)
            attendanceHistory[course] = history
        } else {
            attendanceHistory[course] = [record]
        }
        
        // Add to Firebase
        let attendanceData: [String: Any] = [
            "courseId": courseId,
            "studentId": studentID,
            "studentEmail": studentEmail,
            "timestamp": timestamp
        ]
        
        db.collection("Attendance").addDocument(data: attendanceData) { error in
            if let error = error {
                print("Error adding attendance record: \(error)")
            } else {
                print("Successfully added attendance record to Firebase")
            }
        }
    }
    
    func getAttendance(for course: String, user: User) -> [AttendanceRecord] {
        let courseId = getCourseId(for: course)
        
        if let cachedRecords = attendanceHistory[course] {
            return cachedRecords
        }
        
        db.collection("Attendance")
            .whereField("courseId", isEqualTo: courseId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                let records = documents.map { doc -> AttendanceRecord in
                    let data = doc.data()
                    return AttendanceRecord(
                        id: UUID(),
                        studentId: data["studentId"] as? String ?? "",
                        studentEmail: data["studentEmail"] as? String ?? "",
                        timestamp: data["timestamp"] as? String ?? "",
                        courseId: data["courseId"] as? String ?? ""
                    )
                }
                
                DispatchQueue.main.async {
                    self?.attendanceHistory[course] = records
                }
            }
        
        return []
    }
    
    // Helper function to convert course name to courseId
    private func getCourseId(for courseName: String) -> String {
        switch courseName {
        case "CSCI 380: Intro to Software Engineering":
            return "380"
        case "CSCI 300: Database Management":
            return "300"
        case "CSCI 235: Elements of Discrete Structures":
            return "235"
        case "MAT 210: Linear Algebra":
            return "210"
        default:
            return ""
        }
    }
}

