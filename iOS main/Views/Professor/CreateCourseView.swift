//
//  CreateCourseView.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import SwiftUI

struct CreateCourseView: View {
    @EnvironmentObject var professorViewModel: ProfessorViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var courseName = ""
    @State private var courseCode = ""
    @State private var nfcTagID = ""
    @State private var semester = "Fall"
    @State private var academicYear = "2024"
    @State private var schedules: [CourseSchedule] = []
    @State private var showingAddSchedule = false
    
    let semesters = ["Fall", "Spring", "Summer"]
    let years = ["2024", "2025", "2026"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Course Information") {
                    TextField("Course Name", text: $courseName)
                    TextField("Course Code", text: $courseCode)
                    TextField("NFC Tag ID", text: $nfcTagID)
                }
                
                Section("Term") {
                    Picker("Semester", selection: $semester) {
                        ForEach(semesters, id: \.self) { semester in
                            Text(semester).tag(semester)
                        }
                    }
                    
                    Picker("Academic Year", selection: $academicYear) {
                        ForEach(years, id: \.self) { year in
                            Text(year).tag(year)
                        }
                    }
                }
                
                Section("Class Schedule") {
                    ForEach(schedules.indices, id: \.self) { index in
                        ScheduleRow(schedule: schedules[index])
                    }
                    .onDelete { indexSet in
                        schedules.remove(atOffsets: indexSet)
                    }
                    
                    Button {
                        showingAddSchedule = true
                    } label: {
                        Label("Add Schedule", systemImage: "plus.circle")
                    }
                }
                
                Section {
                    Button {
                        createCourse()
                    } label: {
                        Text("Create Course")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(!isFormValid || professorViewModel.isLoading)
                }
            }
            .navigationTitle("New Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddSchedule) {
                AddScheduleView { schedule in
                    schedules.append(schedule)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !courseName.isEmpty &&
        !courseCode.isEmpty &&
        !nfcTagID.isEmpty &&
        !schedules.isEmpty
    }
    
    private func createCourse() {
        guard let professorID = authViewModel.currentUser?.id else { return }
        
        let course = Course(
            name: courseName,
            courseCode: courseCode,
            professorID: professorID,
            nfcTagID: nfcTagID,
            semester: semester,
            academicYear: academicYear,
            schedule: schedules
        )
        
        Task {
            await professorViewModel.createCourse(course)
            if professorViewModel.successMessage != nil {
                await professorViewModel.loadCourses(professorID: professorID)
                dismiss()
            }
        }
    }
}

struct ScheduleRow: View {
    let schedule: CourseSchedule
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dayName(schedule.dayOfWeek))
                .font(.headline)
            Text("\(schedule.startTime) - \(schedule.endTime)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(schedule.location)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func dayName(_ day: Int) -> String {
        let days = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[safe: day] ?? "Unknown"
    }
}

struct AddScheduleView: View {
    @Environment(\.dismiss) var dismiss
    var onAdd: (CourseSchedule) -> Void
    
    @State private var selectedDay = 2
    @State private var startTime = "09:00"
    @State private var endTime = "10:30"
    @State private var location = ""
    
    let days = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Day of Week", selection: $selectedDay) {
                    ForEach(days, id: \.0) { day in
                        Text(day.1).tag(day.0)
                    }
                }
                
                TextField("Start Time (HH:MM)", text: $startTime)
                    .keyboardType(.numbersAndPunctuation)
                
                TextField("End Time (HH:MM)", text: $endTime)
                    .keyboardType(.numbersAndPunctuation)
                
                TextField("Location", text: $location)
            }
            .navigationTitle("Add Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let schedule = CourseSchedule(
                            dayOfWeek: selectedDay,
                            startTime: startTime,
                            endTime: endTime,
                            location: location
                        )
                        onAdd(schedule)
                        dismiss()
                    }
                    .disabled(location.isEmpty)
                }
            }
        }
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    CreateCourseView()
        .environmentObject(ProfessorViewModel())
        .environmentObject(AuthViewModel())
}
