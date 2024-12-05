//
//  ContentView.swift
//  Attendance Scanner FP
//
//  Created by Steven Kurt on 11/26/24.
//


import SwiftUI
import CoreNFC
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

enum AuthState {
    case signedOut
    case signedIn(User)
    case signingIn
}

struct ContentView: View {
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @State private var authState: AuthState = .signedOut

    var body: some View {
        NavigationView {
            ZStack {
                Image("nyit")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                switch authState {
                case .signedIn(let user):
                    DashboardView(authState: $authState, user: user)
                case .signingIn:
                    LoginView(authState: $authState)
                case .signedOut:
                    welcomeView
                }
            }
        }
        .onAppear {
            forceSignOut()
        }
    }

    private var welcomeView: some View {
        VStack {
            Text("Welcome!")
                .font(.largeTitle)
                .bold()
                .padding()

            Button(action: {
                print("Tapped login button")
                authState = .signingIn
            }) {
                Text("Tap here to log in")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
        }
    }

    func forceSignOut() {
        print("Forcing sign out...")
        do {
            try Auth.auth().signOut()
            print("Forced sign out successful")
        } catch {
            print("Error forcing sign out: \(error.localizedDescription)")
        }
        checkAuthenticationState()
    }

    func checkAuthenticationState() {
        print("Checking authentication state...")
        if let currentUser = Auth.auth().currentUser {
            print("User is signed in: \(currentUser.uid)")
            print("Email: \(currentUser.email ?? "No email")")
            print("Display Name: \(currentUser.displayName ?? "No display name")")
            authState = .signedIn(currentUser)
        } else {
            print("No user is signed in")
            authState = .signedOut
        }
    }
}

struct DashboardView: View {
    @Binding var authState: AuthState
    let user: User
    @StateObject private var dashboardViewModel = DashboardViewModel()

    var body: some View {
        ZStack {
            // NYIT background
            Image("nyit")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer() // Push content to middle

                Text("Dashboard")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                if dashboardViewModel.isLoading {
                    ProgressView("Loading courses...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else if !dashboardViewModel.courses.isEmpty {
                    // Button to Scan for Attendance
                    NavigationLink(destination: CourseSelectionView(user: user, courses: dashboardViewModel.courses)) {
                        Text("Scan for Attendance")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 10)

                    // Button to View Attendance
                    NavigationLink(destination: CourseListView(user: user, dashboardViewModel: dashboardViewModel)) {
                        Text("View Attendance")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                } else {
                    Text("No courses found. Please contact your administrator.")
                        .foregroundColor(.gray)
                }

                Spacer() // Push content to middle

                // Log Out Button
                Button(action: {
                    do {
                        try Auth.auth().signOut()
                        print("User signed out successfully")
                        authState = .signedOut
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }) {
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                }
            }
        }
        .onAppear {
            dashboardViewModel.fetchCourses(for: user)
        }
    }
}

struct CourseSelectionView: View {
    let user: User
    let courses: [Course]
    @State private var selectedCourse: Course?
    @StateObject private var nfcScanner = NFCScanner()
    @State private var showError: Bool = false
    @State private var showSuccess: Bool = false

    var body: some View {
        VStack {
            courseSelectionList
            selectedCourseDetails
            lastScanDetails
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Scanning Error"),
                message: Text(nfcScanner.scanError ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: nfcScanner.scanError) { _, error in
            showError = error != nil
        }
        .onChange(of: nfcScanner.lastScannedCardData) { _, newValue in
            showSuccess = newValue != nil
        }
    }

    private var courseSelectionList: some View {
        VStack {
            Text("Select a Course")
                .font(.largeTitle)
                .bold()
                .padding()
            List(courses, id: \.id) { course in
                courseSelectionButton(for: course)
            }
        }
    }

    private func courseSelectionButton(for course: Course) -> some View {
        Button(action: {
            selectedCourse = course
            nfcScanner.beginScanning(for: course.id, user: user)
        }) {
            Text(course.name)
                .font(.headline)
                .padding(.vertical, 5)
        }
    }

    private var selectedCourseDetails: some View {
        if let selectedCourse = selectedCourse {
            return AnyView(
                Text("Selected Course: \(selectedCourse.name)")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    private var lastScanDetails: some View {
        if let cardData = nfcScanner.lastScannedCardData {
            return AnyView(
                VStack(alignment: .leading, spacing: 10) {
                    Text("Last Scanned Card Data:")
                        .font(.headline)
                    Text("Course ID: \(cardData.courseId)")
                    Text("Professor ID: \(cardData.professorId)")
                    Text("Professor Name: \(cardData.professorName)")
                    Text("Time: \(cardData.timestamp)")
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
                .padding()
            )
        } else {
            return AnyView(EmptyView())
        }
    }
}

struct CourseListView: View {
    let user: User
    @ObservedObject var dashboardViewModel: DashboardViewModel // Changed to @ObservedObject

    init(user: User, dashboardViewModel: DashboardViewModel) {
        self.user = user
        self.dashboardViewModel = dashboardViewModel
    }

    var body: some View {
        VStack {
            Text("Select a Course")
                .font(.largeTitle)
                .bold()
                .padding()

            if dashboardViewModel.isLoading {
                ProgressView()
            } else if !dashboardViewModel.courses.isEmpty {
                List(dashboardViewModel.courses, id: \.id) { course in
                    NavigationLink(destination: AttendanceHistoryDetailView(user: user, course: course)) {
                        Text(course.name)
                            .font(.headline)
                            .padding(.vertical, 5)
                    }
                }
            } else {
                Text("No courses found. Please contact your administrator.")
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            dashboardViewModel.fetchCourses(for: user)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
