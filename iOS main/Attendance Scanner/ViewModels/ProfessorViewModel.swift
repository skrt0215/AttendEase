//
//  ProfessorViewModel.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import SwiftUI

@MainActor
class ProfessorViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var selectedCourse: Course?
    @Published var attendanceReport: [AttendanceRecord] = []
    @Published var enrolledStudents: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    private let firestoreService = FirestoreService.shared
    
    func loadCourses(professorID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            courses = try await firestoreService.fetchCoursesByProfessor(professorID: professorID)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createCourse(_ course: Course) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            try await firestoreService.createCourse(course)
            successMessage = "Course created successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadAttendanceReport(courseID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            attendanceReport = try await firestoreService.fetchAttendanceReport(forCourse: courseID)
            enrolledStudents = try await firestoreService.fetchEnrolledStudents(forCourse: courseID)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func getAttendanceStats(for courseID: String) -> (total: Int, early: Int, onTime: Int, late: Int) {
        let records = attendanceReport.filter { $0.courseID == courseID }
        
        let early = records.filter { $0.status == AttendanceStatus.early }.count
        let onTime = records.filter { $0.status == AttendanceStatus.onTime }.count
        let late = records.filter { $0.status == AttendanceStatus.late }.count
        
        return (records.count, early, onTime, late)
    }
    
    func getAttendancePercentage(for studentID: String, in courseID: String) -> Double {
        let studentRecords = attendanceReport.filter {
            $0.studentID == studentID && $0.courseID == courseID
        }
        
        guard let course = courses.first(where: { $0.id == courseID }) else {
            return 0.0
        }
        
        let totalSessions = calculateTotalSessions(for: course)
        guard totalSessions > 0 else { return 0.0 }
        
        return Double(studentRecords.count) / Double(totalSessions) * 100
    }
    
    private func calculateTotalSessions(for course: Course) -> Int {
        return 15
    }
}
