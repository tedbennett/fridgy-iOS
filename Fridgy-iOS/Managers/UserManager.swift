//
//  UserManager.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 26/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import Foundation
import FirebaseAuth
import AuthenticationServices

class UserManager {
    static var shared = UserManager()
    
    private init() {
        
    }
    
    var isLoggedIn: Bool {
        Auth.auth().currentUser != nil
    }
    
    func createAccount(appleIDCredential: ASAuthorizationAppleIDCredential, nonce: String?) async throws {
        guard let nonce = nonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
              fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
        
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        
        let authResult = try await Auth.auth().signIn(with: credential)
            
        let exists = try await NetworkManager.shared.checkUserExists(id: authResult.user.uid)
        
        if !exists {
            let name = appleIDCredential.fullName?.givenName
            let email = appleIDCredential.email
            try await NetworkManager.shared.createUser(name: name, email: email, id: authResult.user.uid)
        }
    }
    
    func logout() throws {
        try Auth.auth().signOut()
    }
    
    func deleteAccount() async throws {
        guard let id = Auth.auth().currentUser?.uid else {
            return
        }
        // TODO: Function to delete the user
//        _ = Auth.auth().currentUser?.delete
        try await NetworkManager.shared.deleteUser(id: id)
    }
    
}
