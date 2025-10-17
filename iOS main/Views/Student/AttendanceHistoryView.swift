//
//  AttendanceHistoryView.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import SwiftUI

struct AttendanceHistoryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var studentViewModel: StudentViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if studentViewModel.isLoading {
                    ProgressView()
                } else if studentViewModel.attendanceHistory.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No attendance records yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        ForEach(groupedRecords, id: \.key) { date, records in
                            Section(header: Text(date)) {
                                ForEach(records) { record in
                                    AttendanceRecordRow(
                                        record: record,
                                        course: studentViewModel.enrolledCourses.first { $0.id == record.courseID }
                                    )
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Attendance History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                if let studentID = authViewModel.currentUser?.id {
                    await studentViewModel.loadAttendanceHistory(studentID: studentID)
                }
            }
        }
    }
    
    private var groupedRecords: [(key: String, value: [AttendanceRecord])] {
        let grouped = Dictionary(grouping: studentViewModel.attendanceHistory) { record in
            formatDate(record.timestamp)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AttendanceRecordRow: View {
    let record: AttendanceRecord
    let course: Course?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course?.name ?? "Unknown Course")
                    .font(.headline)
                
                Text(course?.courseCode ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatTime(record.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: record.status)
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundStyle(.white)
            .cornerRadius(8)
    }
    
    private var statusText: String {
        switch status {
        case AttendanceStatus.early:
            return "Early"
        case AttendanceStatus.onTime:
            return "On Time"
        case AttendanceStatus.late:
            return "Late"
        default:
            return status
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case AttendanceStatus.early:
            return .blue
        case AttendanceStatus.onTime:
            return .green
        case AttendanceStatus.late:
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    AttendanceHistoryView()
        .environmentObject(AuthViewModel())
        .environmentObject(StudentViewModel())
}
