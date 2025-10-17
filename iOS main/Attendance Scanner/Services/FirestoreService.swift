//
//  FirestoreService.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    private init() {}
    
    func createCourse(_ course: Course) async throws {
        let _ = try db.collection(FirestoreCollections.courses)
            .addDocument(from: course)
    }
    
    func fetchCoursesByProfessor(professorID: String) async throws -> [Course] {
        let snapshot = try await db.collection(FirestoreCollections.courses)
            .whereField("professorID", isEqualTo: professorID)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Course.self) }
    }
    
    func fetchCourse(byNFCTagID tagID: String) async throws -> Course? {
        let snapshot = try await db.collection(FirestoreCollections.courses)
            .whereField("nfcTagID", isEqualTo: tagID)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try document.data(as: Course.self)
    }
    
    func enrollStudent(studentID: String, courseID: String) async throws {
        let enrollment = Enrollment(
            studentID: studentID,
            courseID: courseID,
            enrolledAt: Date(),
            status: "active"
        )
        
        try db.collection(FirestoreCollections.enrollments)
            .addDocument(from: enrollment)
    }
    
    func fetchEnrollments(forStudent studentID: String) async throws -> [Enrollment] {
        let snapshot = try await db.collection(FirestoreCollections.enrollments)
            .whereField("studentID", isEqualTo: studentID)
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Enrollment.self) }
    }
    
    func isStudentEnrolled(studentID: String, courseID: String) async throws -> Bool {
        let snapshot = try await db.collection(FirestoreCollections.enrollments)
            .whereField("studentID", isEqualTo: studentID)
            .whereField("courseID", isEqualTo: courseID)
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    func checkExistingAttendance(studentID: String, courseID: String, sessionDate: String) async throws -> Bool {
        let snapshot = try await db.collection(FirestoreCollections.attendance)
            .whereField("studentID", isEqualTo: studentID)
            .whereField("courseID", isEqualTo: courseID)
            .whereField("sessionDate", isEqualTo: sessionDate)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    func markAttendance(_ record: AttendanceRecord) async throws {
        try db.collection(FirestoreCollections.attendance)
            .addDocument(from: record)
    }
    
    func fetchAttendanceHistory(forStudent studentID: String, courseID: String? = nil) async throws -> [AttendanceRecord] {
        var query: Query = db.collection(FirestoreCollections.attendance)
            .whereField("studentID", isEqualTo: studentID)
        
        if let courseID = courseID {
            query = query.whereField("courseID", isEqualTo: courseID)
        }
        
        let snapshot = try await query
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
    }
    
    func fetchAttendanceReport(forCourse courseID: String) async throws -> [AttendanceRecord] {
        let snapshot = try await db.collection(FirestoreCollections.attendance)
            .whereField("courseID", isEqualTo: courseID)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: AttendanceRecord.self) }
    }
    
    func fetchEnrolledStudents(forCourse courseID: String) async throws -> [String] {
        let snapshot = try await db.collection(FirestoreCollections.enrollments)
            .whereField("courseID", isEqualTo: courseID)
            .whereField("status", isEqualTo: "active")
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            guard let enrollment = try? document.data(as: Enrollment.self) else { return nil }
            return enrollment.studentID
        }
    }
    
    func fetchCourse(byID courseID: String) async throws -> Course? {
        let document = try await db.collection(FirestoreCollections.courses)
            .document(courseID)
            .getDocument()
        
        return try document.data(as: Course.self)
    }
}
