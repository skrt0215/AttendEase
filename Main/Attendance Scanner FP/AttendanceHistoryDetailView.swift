//
//  AttendanceHistoryDetailView.swift
//  Attendance Scanner FP
//
//  Created by Steven Kurt on 12/4/24.
//

import SwiftUI
import FirebaseAuth

struct AttendanceRecord: Identifiable {
    let id: UUID = UUID()       // Add a unique identifier
    let studentId: String
    let studentName: String
    let timestamp: String
}

struct AttendanceHistoryDetailView: View {
    let user: User
    let course: Course
    @State private var attendanceRecords: [AttendanceRecord] = []

    var body: some View {
        VStack {
            Text("\(course.name) Attendance History")
                .font(.largeTitle)
                .bold()
                .padding()

            if attendanceRecords.isEmpty {
                Text("No attendance records available.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(attendanceRecords) { record in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(record.studentName)
                            .font(.headline)
                        Text("ID: \(record.studentId)")
                            .font(.subheadline)
                        Text("Time: \(record.timestamp)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .onAppear {
            loadAttendanceRecords(for: user, course: course)
        }
    }

    func loadAttendanceRecords(for user: User, course: Course) {
        attendanceRecords = AttendanceManager.shared.getAttendance(for: course.id, user: user).map {
            AttendanceRecord(
                studentId: $0.studentId,
                studentName: $0.studentEmail,        // Map studentEmail as a placeholder for studentName
                timestamp: $0.timestamp
            )
        }
    }
}
