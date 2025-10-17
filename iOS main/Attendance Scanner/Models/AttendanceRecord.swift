//
//  AttendanceRecord.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import FirebaseFirestore

struct AttendanceRecord: Codable, Identifiable {
    @DocumentID var id: String?
    var studentID: String
    var courseID: String
    var timestamp: Date
    var status: String
    var sessionDate: String
    
    init(id: String? = nil, studentID: String, courseID: String, timestamp: Date = Date(), status: String) {
        self.id = id
        self.studentID = studentID
        self.courseID = courseID
        self.timestamp = timestamp
        self.status = status
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.sessionDate = formatter.string(from: timestamp)
    }
}
