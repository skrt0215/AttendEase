//
//  Enrollment.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import FirebaseFirestore

struct Enrollment: Codable, Identifiable {
    @DocumentID var id: String?
    var studentID: String
    var courseID: String
    var enrolledAt: Date
    var status: String
}
