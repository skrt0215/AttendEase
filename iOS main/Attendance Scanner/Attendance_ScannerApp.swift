//
//  Attendance_ScannerApp.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 11/25/24.
//

import SwiftUI
import FirebaseCore

@main
struct Attendance_ScannerApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
