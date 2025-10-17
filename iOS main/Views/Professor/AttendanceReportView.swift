//
//  AttendanceReportView.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import SwiftUI

struct AttendanceReportView: View {
    @EnvironmentObject var professorViewModel: ProfessorViewModel
    let course: Course
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(course.courseCode)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("\(course.semester) \(course.academicYear)")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                if professorViewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    VStack(spacing: 16) {
                        AttendanceStatsCard(
                            stats: professorViewModel.getAttendanceStats(for: course.id ?? "")
                        )
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Attendance")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if professorViewModel.attendanceReport.isEmpty {
                                Text("No attendance records yet")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ForEach(professorViewModel.attendanceReport) { record in
                                    AttendanceReportRow(record: record)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Attendance Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let courseID = course.id {
                await professorViewModel.loadAttendanceReport(courseID: courseID)
            }
        }
    }
}

struct AttendanceStatsCard: View {
    let stats: (total: Int, early: Int, onTime: Int, late: Int)
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Overall Statistics")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatItem(
                    title: "Total",
                    value: "\(stats.total)",
                    color: .blue
                )
                
                StatItem(
                    title: "Early",
                    value: "\(stats.early)",
                    color: .blue
                )
                
                StatItem(
                    title: "On Time",
                    value: "\(stats.onTime)",
                    color: .green
                )
                
                StatItem(
                    title: "Late",
                    value: "\(stats.late)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AttendanceReportRow: View {
    let record: AttendanceRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Student: \(record.studentID)")
                    .font(.headline)
                
                Text(formatDateTime(record.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: record.status)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        AttendanceReportView(
            course: Course(
                name: "iOS Development",
                courseCode: "CS 4720",
                professorID: "prof123",
                nfcTagID: "tag123",
                semester: "Fall",
                academicYear: "2024",
                schedule: []
            )
        )
        .environmentObject(ProfessorViewModel())
    }
}
