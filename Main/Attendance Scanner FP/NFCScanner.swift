//
//  NFCScanner.swift
//  Attendance Scanner FP
//
//  Created by Steven Kurt on 12/4/24.
//

import SwiftUI
import CoreNFC
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

struct NFCCardData: Equatable, Codable {
    let courseId: String
    let professorId: String
    let professorName: String
    let timestamp: String
}

class NFCScanner: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    private var session: NFCNDEFReaderSession?
    private var selectedCourse: String?
    private var currentUser: User?
    @Published var lastScannedCardData: NFCCardData?
    @Published var scanError: String?
    private let db = Firestore.firestore()
    
    func beginScanning(for course: String, user: User) {
        guard NFCNDEFReaderSession.readingAvailable else {
            scanError = "NFC is not supported on this device"
            return
        }
        
        selectedCourse = course
        currentUser = user
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near the professor's course card"
        session?.begin()
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("NFC session became active")
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        print("Detected NDEF messages: \(messages)")
        
        guard let firstMessage = messages.first,
              let firstRecord = firstMessage.records.first else {
            handleScanError("No valid records found on card")
            return
        }
        
        let payloadData = firstRecord.payload
        print("Raw payload data: \(payloadData)")
        
        if let payloadString = String(data: payloadData.dropFirst(), encoding: .utf8) {
            print("Payload string: \(payloadString)")
            processNTAG215Data(payloadString)
        } else {
            handleScanError("Unable to decode card data")
        }
    }
    
    private func processNTAG215Data(_ payload: String) {
        let components = payload.components(separatedBy: "|")
        print("Processing components: \(components)")
        
        // Expecting card data format: courseId|professorId
        guard components.count >= 2 else {
            handleScanError("Invalid card format")
            return
        }
        
        let courseId = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let professorId = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Verify this course matches the selected course
        guard courseId == getCourseId(for: selectedCourse ?? "") else {
            handleScanError("This card is not for the selected course")
            return
        }
        
        validateProfessorCard(courseId: courseId, professorId: professorId)
    }
    
    private func validateProfessorCard(courseId: String, professorId: String) {
        db.collection("Professor")
            .whereField("courseId", isEqualTo: courseId)
            .whereField("professorId", isEqualTo: professorId)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.handleScanError("Database error: \(error.localizedDescription)")
                    return
                }
                
                guard let document = snapshot?.documents.first else {
                    self.handleScanError("Invalid professor card for this course")
                    return
                }
                
                // After validating professor, fetch student info from Students collection
                self.db.collection("Students")
                    .whereField("studentEmail", isEqualTo: self.currentUser?.email ?? "")
                    .getDocuments { studentSnapshot, studentError in
                        if let studentError = studentError {
                            self.handleScanError("Error fetching student data: \(studentError.localizedDescription)")
                            return
                        }
                        
                        guard let studentDoc = studentSnapshot?.documents.first else {
                            self.handleScanError("Student information not found")
                            return
                        }
                        
                        let studentData = studentDoc.data()
                        let studentId = studentData["studentId"] as? String ?? ""
                        let studentName = studentData["studentName"] as? String ?? ""
                        
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateStyle = .short
                        dateFormatter.timeStyle = .short
                        let timestamp = dateFormatter.string(from: Date())
                        
                        // Store in Firestore database with student information
                        let attendanceData: [String: Any] = [
                            "courseId": courseId,
                            "studentEmail": self.currentUser?.email ?? "",
                            "studentId": studentId,
                            "studentName": studentName,
                            "timestamp": timestamp
                        ]
                        
                        self.db.collection("Attendance").addDocument(data: attendanceData) { error in
                            if let error = error {
                                print("Error saving to database: \(error.localizedDescription)")
                            } else {
                                print("Successfully saved attendance record to database")
                            }
                        }
                        
                        // Update UI
                        DispatchQueue.main.async {
                            self.lastScannedCardData = NFCCardData(
                                courseId: courseId,
                                professorId: professorId,
                                professorName: studentName, // Using student name for display
                                timestamp: timestamp
                            )
                            print("Attendance recorded for student: \(studentName)")
                            print("Course ID: \(courseId)")
                            print("Timestamp: \(timestamp)")
                        }
                    }
            }
    }
    
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
    
    private func handleScanError(_ message: String) {
        print("Error: \(message)")
        DispatchQueue.main.async {
            self.scanError = message
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("Session invalidated with error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            if let readerError = error as? NFCReaderError {
                switch readerError.code {
                case .readerSessionInvalidationErrorFirstNDEFTagRead:
                    print("Successfully completed reading.")
                case .readerSessionInvalidationErrorUserCanceled:
                    self.scanError = "Scanning was canceled"
                default:
                    self.scanError = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
