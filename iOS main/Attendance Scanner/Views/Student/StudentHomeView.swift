//
//  StudentHomeView.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import SwiftUI

struct StudentHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var studentViewModel = StudentViewModel()
    @State private var showingScanView = false
    @State private var showingHistoryView = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = authViewModel.currentUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome, \(user.name)")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let studentID = user.studentID {
                                Text("Student ID: \(studentID)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    
                    VStack(spacing: 16) {
                        Button {
                            if let studentID = authViewModel.currentUser?.id {
                                studentViewModel.scanNFCTag(studentID: studentID)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "wave.3.right")
                                    .font(.title2)
                                Text("Scan NFC Tag")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!studentViewModel.isNFCAvailable || studentViewModel.isScanning)
                        
                        if !studentViewModel.isNFCAvailable {
                            Text("NFC is not available on this device")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        
                        Button {
                            showingHistoryView = true
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title2)
                                Text("View Attendance History")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    if let successMessage = studentViewModel.successMessage {
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    if let errorMessage = studentViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    if studentViewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Courses")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if studentViewModel.enrolledCourses.isEmpty {
                            Text("No enrolled courses")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(studentViewModel.enrolledCourses) { course in
                                CourseCardView(course: course)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        authViewModel.signOut()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .sheet(isPresented: $showingHistoryView) {
                AttendanceHistoryView()
                    .environmentObject(studentViewModel)
                    .environmentObject(authViewModel)
            }
            .task {
                if let studentID = authViewModel.currentUser?.id {
                    await studentViewModel.loadEnrolledCourses(studentID: studentID)
                }
            }
        }
    }
}

struct CourseCardView: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name)
                .font(.headline)
            
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
    }
}

#Preview {
    StudentHomeView()
        .environmentObject(AuthViewModel())
}
