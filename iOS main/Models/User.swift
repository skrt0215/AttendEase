//
//  User.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var name: String
    var role: String
    var studentID: String?
    var createdAt: Date
    
    var isStudent: Bool {
        role == UserRole.student
    }
    
    var isProfessor: Bool {
        role == UserRole.professor
    }
}
