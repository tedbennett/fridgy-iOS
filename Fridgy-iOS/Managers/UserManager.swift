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
import CryptoKit

class UserManager: NSObject {
    
    static var shared = UserManager()
    
    private override init() { }
    
    var isLoggedIn: Bool {
        Auth.auth().currentUser != nil
    }
    
    
    
    func signInWith(appleIDCredential: ASAuthorizationAppleIDCredential) async throws -> AuthDataResult {
        guard let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
              fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
        
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        
        return try await Auth.auth().signIn(with: credential)
        
    }
    
    func logout() throws {
        try Auth.auth().signOut()
    }
    
    func deleteAccount(id: String) async throws {
        try await NetworkManager.shared.deleteUser(id: id)
    }
    
    var currentNonce: String?
    weak var presentationDelegate: ASAuthorizationControllerPresentationContextProviding?
    var signInCompletion: ((Bool) -> Void)?
}

// MARK: Sign In With Apple

extension UserManager: ASAuthorizationControllerDelegate {
    func handleLogInWithAppleID(completion: @escaping (Bool) -> Void) {
        signInCompletion = completion
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        currentNonce = randomNonceString()
        request.nonce = sha256(currentNonce!)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        controller.delegate = self
        controller.presentationContextProvider = presentationDelegate
        
        controller.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                Task {
                    let authResult = try await UserManager.shared.signInWith(appleIDCredential: appleIDCredential)
                    Utility.appleIdUid = appleIDCredential.user
                    
                    let exists = try await NetworkManager.shared.checkUserExists(id: authResult.user.uid)
                    if !exists {
                        let name = appleIDCredential.fullName?.givenName
                        let email = appleIDCredential.email
                        try await NetworkManager.shared.createUser(name: name, email: email, id: authResult.user.uid)
                    }
                    await MainActor.run {
                        signInCompletion?(true)
                    }
                }
            default: signInCompletion?(false)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        signInCompletion?(false)
    }
    
    private func randomNonceString() -> String {
        let length = 32
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}
