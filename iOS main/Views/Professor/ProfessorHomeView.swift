//
//  ProfessorHomeView.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import SwiftUI

struct ProfessorHomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var professorViewModel = ProfessorViewModel()
    @State private var showingCreateCourse = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = authViewModel.currentUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome, Prof. \(user.name)")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                    
                    Button {
                        showingCreateCourse = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Create New Course")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    if let successMessage = professorViewModel.successMessage {
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    if let errorMessage = professorViewModel.errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    if professorViewModel.isLoading {
                        ProgressView()
                            .padding()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("My Courses")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if professorViewModel.courses.isEmpty {
                            Text("No courses created yet")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            ForEach(professorViewModel.courses) { course in
                                NavigationLink(destination: AttendanceReportView(course: course)
                                    .environmentObject(professorViewModel)) {
                                    ProfessorCourseCard(course: course)
                                }
                                .buttonStyle(.plain)
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
            .sheet(isPresented: $showingCreateCourse) {
                CreateCourseView()
                    .environmentObject(professorViewModel)
                    .environmentObject(authViewModel)
            }
            .task {
                if let professorID = authViewModel.currentUser?.id {
                    await professorViewModel.loadCourses(professorID: professorID)
                }
            }
        }
    }
}

struct ProfessorCourseCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.name)
                        .font(.headline)
                    
                    Text(course.courseCode)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            
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
    ProfessorHomeView()
        .environmentObject(AuthViewModel())
}
