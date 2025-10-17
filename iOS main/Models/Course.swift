//
//  Course.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import FirebaseFirestore

struct CourseSchedule: Codable {
    var dayOfWeek: Int
    var startTime: String
    var endTime: String
    var location: String
}

struct Course: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var courseCode: String
    var professorID: String
    var nfcTagID: String
    var semester: String
    var academicYear: String
    var schedule: [CourseSchedule]
    
    func isClassInSession(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let currentTime = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let currentHour = currentTime.hour,
              let currentMinute = currentTime.minute else {
            return false
        }
        
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        for session in schedule where session.dayOfWeek == weekday {
            if let startComponents = parseTime(session.startTime),
               let endComponents = parseTime(session.endTime) {
                let startMinutes = startComponents.hour * 60 + startComponents.minute
                let endMinutes = endComponents.hour * 60 + endComponents.minute
                
                let windowStart = startMinutes - AttendanceWindow.earlyMinutes
                let windowEnd = endMinutes
                
                if currentTimeInMinutes >= windowStart && currentTimeInMinutes <= windowEnd {
                    return true
                }
            }
        }
        
        return false
    }
    
    func attendanceStatus(for date: Date = Date()) -> String? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let currentTime = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let currentHour = currentTime.hour,
              let currentMinute = currentTime.minute else {
            return nil
        }
        
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        for session in schedule where session.dayOfWeek == weekday {
            if let startComponents = parseTime(session.startTime) {
                let startMinutes = startComponents.hour * 60 + startComponents.minute
                let earlyThreshold = startMinutes - AttendanceWindow.earlyMinutes
                let lateThreshold = startMinutes + AttendanceWindow.lateMinutes
                
                if currentTimeInMinutes < startMinutes {
                    if currentTimeInMinutes >= earlyThreshold {
                        return AttendanceStatus.early
                    }
                } else if currentTimeInMinutes <= lateThreshold {
                    return AttendanceStatus.onTime
                } else {
                    return AttendanceStatus.late
                }
            }
        }
        
        return nil
    }
    
    private func parseTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return nil
        }
        return (hour, minute)
    }
}
