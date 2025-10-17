//
//  Constants.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation

struct FirestoreCollections {
    static let users = "users"
    static let courses = "courses"
    static let enrollments = "enrollments"
    static let attendance = "attendance"
}

struct UserRole {
    static let student = "student"
    static let professor = "professor"
}

struct AttendanceStatus {
    static let early = "early"
    static let onTime = "onTime"
    static let late = "late"
}

struct AttendanceWindow {
    static let earlyMinutes = 15
    static let lateMinutes = 10
}

struct ValidationRules {
    static let minPasswordLength = 6
    static let studentIDLength = 8
}

enum AppError: LocalizedError {
    case invalidCredentials
    case networkError
    case nfcNotSupported
    case nfcReadFailed
    case invalidNFCTag
    case notEnrolledInCourse
    case outsideClassTime
    case alreadyMarkedPresent
    case firestoreError(String)
    case authError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection failed"
        case .nfcNotSupported:
            return "NFC is not supported on this device"
        case .nfcReadFailed:
            return "Failed to read NFC tag"
        case .invalidNFCTag:
            return "Invalid or unrecognized NFC tag"
        case .notEnrolledInCourse:
            return "You are not enrolled in this course"
        case .outsideClassTime:
            return "Attendance can only be marked during class time"
        case .alreadyMarkedPresent:
            return "Attendance already marked for this session"
        case .firestoreError(let message):
            return "Database error: \(message)"
        case .authError(let message):
            return "Authentication error: \(message)"
        }
    }
}
