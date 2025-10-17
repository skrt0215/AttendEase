//
//  StudentViewModel.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import SwiftUI

@MainActor
class StudentViewModel: ObservableObject {
    @Published var enrolledCourses: [Course] = []
    @Published var attendanceHistory: [AttendanceRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isScanning = false
    
    private let firestoreService = FirestoreService.shared
    private let nfcService = NFCService.shared
    
    var isNFCAvailable: Bool {
        nfcService.isNFCAvailable
    }
    
    func loadEnrolledCourses(studentID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let enrollments = try await firestoreService.fetchEnrollments(forStudent: studentID)
            
            var courses: [Course] = []
            for enrollment in enrollments {
                if let course = try await firestoreService.fetchCourse(byID: enrollment.courseID) {
                    courses.append(course)
                }
            }
            
            enrolledCourses = courses
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadAttendanceHistory(studentID: String, courseID: String? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            attendanceHistory = try await firestoreService.fetchAttendanceHistory(
                forStudent: studentID,
                courseID: courseID
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func scanNFCTag(studentID: String) {
        guard !isScanning else { return }
        
        isScanning = true
        errorMessage = nil
        successMessage = nil
        
        nfcService.scanTag { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.isScanning = false
                
                switch result {
                case .success(let tagID):
                    await self.processNFCTag(tagID: tagID, studentID: studentID)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func processNFCTag(tagID: String, studentID: String) async {
        isLoading = true
        
        do {
            guard let course = try await firestoreService.fetchCourse(byNFCTagID: tagID) else {
                errorMessage = "Invalid NFC tag - course not found"
                isLoading = false
                return
            }
            
            guard let courseID = course.id else {
                errorMessage = "Course ID not found"
                isLoading = false
                return
            }
            
            let isEnrolled = try await firestoreService.isStudentEnrolled(
                studentID: studentID,
                courseID: courseID
            )
            
            guard isEnrolled else {
                errorMessage = "You are not enrolled in \(course.name)"
                isLoading = false
                return
            }
            
            guard course.isClassInSession() else {
                errorMessage = "Attendance can only be marked during class time"
                isLoading = false
                return
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let sessionDate = formatter.string(from: Date())
            
            let alreadyMarked = try await firestoreService.checkExistingAttendance(
                studentID: studentID,
                courseID: courseID,
                sessionDate: sessionDate
            )
            
            guard !alreadyMarked else {
                errorMessage = "Attendance already marked for today's class"
                isLoading = false
                return
            }
            
            guard let status = course.attendanceStatus() else {
                errorMessage = "Could not determine attendance status"
                isLoading = false
                return
            }
            
            let record = AttendanceRecord(
                studentID: studentID,
                courseID: courseID,
                status: status
            )
            
            try await firestoreService.markAttendance(record)
            
            let statusText = status == AttendanceStatus.early ? "Early" :
                           status == AttendanceStatus.onTime ? "On Time" : "Late"
            
            successMessage = "Attendance marked as \(statusText) for \(course.name)"
            
            await loadAttendanceHistory(studentID: studentID)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
