//
//  FirestoreService.swift
//  Attendance Scanner
//
//  Created by Steven Kurt on 10/16/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {}
    
    var currentUser: FirebaseAuth.User? {
        auth.currentUser
    }
    
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    func signUp(email: String, password: String, name: String, role: String, studentID: String? = nil) async throws -> User {
        guard password.count >= ValidationRules.minPasswordLength else {
            throw AppError.authError("Password must be at least \(ValidationRules.minPasswordLength) characters")
        }
        
        if role == UserRole.student {
            guard let studentID = studentID, studentID.count == ValidationRules.studentIDLength else {
                throw AppError.authError("Student ID must be \(ValidationRules.studentIDLength) characters")
            }
        }
        
        let authResult = try await auth.createUser(withEmail: email, password: password)
        
        let user = User(
            id: authResult.user.uid,
            email: email,
            name: name,
            role: role,
            studentID: studentID,
            createdAt: Date()
        )
        
        try db.collection(FirestoreCollections.users)
            .document(authResult.user.uid)
            .setData(from: user)
        
        return user
    }
    
    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func fetchCurrentUser() async throws -> User? {
        guard let uid = currentUser?.uid else {
            return nil
        }
        
        let document = try await db.collection(FirestoreCollections.users)
            .document(uid)
            .getDocument()
        
        return try document.data(as: User.self)
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}
