//
//  GroupSignUpViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 23/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import UIKit
import AuthenticationServices
import CryptoKit
import FirebaseAuth

class GroupSignUpViewController: UIViewController {
    
    @IBOutlet weak var authorizationButtonParent: UIView!
    
    private var currentNonce: String?
    
    var authorizationButton: ASAuthorizationAppleIDButton = {
        var button: ASAuthorizationAppleIDButton
        if #available(iOS 13.2, *) {
            button = ASAuthorizationAppleIDButton(type: .signUp, style: .black)
        } else {
            button = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .black)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.cornerRadius = 10
        button.addTarget(self, action: #selector(handleLogInWithAppleID), for: .touchUpInside)
        return button
    }()
    @IBOutlet weak var createFridgeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createFridgeButton.layer.cornerRadius = 10
        authorizationButtonParent.addSubview(authorizationButton)
        authorizationButtonParent.layer.cornerRadius = 10
        
        NSLayoutConstraint.activate([
            authorizationButton.leadingAnchor.constraint(equalTo: authorizationButtonParent.leadingAnchor, constant: 1),
            authorizationButton.trailingAnchor.constraint(equalTo: authorizationButtonParent.trailingAnchor, constant: -1),
            authorizationButton.topAnchor.constraint(equalTo: authorizationButtonParent.topAnchor, constant: 1),
            authorizationButton.bottomAnchor.constraint(equalTo: authorizationButtonParent.bottomAnchor, constant: -1)
        ])
        updateView()
        updateNavBar()
        
        if UserDefaults.standard.string(forKey: "fridgeId") != nil {
            presentGroupView()
        }
    }
    
    func updateView() {
        let signedIn = Auth.auth().currentUser != nil
        authorizationButtonParent.isHidden = signedIn
        createFridgeButton.isHidden = !signedIn
        
        updateNavBar()
    }
    
    func updateNavBar() {
        if Auth.auth().currentUser != nil {
            let optionsButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(onOptionsPressed))
            optionsButton.tintColor = .systemGreen
            navigationItem.rightBarButtonItem = optionsButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func onOptionsPressed() {
        let alert = UIAlertController(
            title: "Options",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.view.tintColor = .systemGreen
        
        alert.addAction(
            UIAlertAction(
                title: "Logout",
                style: .default,
                handler:{ [weak self] (UIAlertAction) in
                    guard let self = self else { return }
                    self.logout()
                }
            )
        )
        
        alert.addAction(
            UIAlertAction(
                title: "Restore Purchase",
                style: .destructive,
                handler:{ [weak self] (UIAlertAction) in
                    guard let self = self else { return }
                    self.restorePurchases()
                }
            )
        )
        
        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            )
        )
        
        self.present(alert, animated: true, completion: {
        })
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Failed to sign out")
        }
        updateView()
    }
    
    func restorePurchases() {
        StoreObserver.shared.restore()
    }
    
    func handleJoinSession(id: String) {
        if let user = Auth.auth().currentUser  {
            let context = AppDelegate.persistentContainer.newBackgroundContext()
            // User signed in and not in session, join session
            Task {
                let fridgeExists = try await NetworkManager.shared.checkFridgeExists(id: id)
                
                if fridgeExists {
                    // Join
                    try await FridgeManager.shared.joinFridge(user: user.uid, fridgeId: id, context: context)
                    await MainActor.run {
                        presentGroupView()
                    }
                } else {
                    // Notify user
                    await MainActor.run {
                        let alert = UIAlertController(
                            title: "Shared Fridge Not Found",
                            message: nil,
                            preferredStyle: .alert
                        )
                        alert.addAction(
                            UIAlertAction(title: "OK", style: .default, handler: nil)
                        )
                        present(alert, animated: true, completion: nil)
                    }
                }
            }
            
        } else {
            // User not signed in
            let alert = UIAlertController(
                title: "Sign up before joining",
                message: "You need to sign up for a free account before joining",
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(title: "OK", style: .default, handler: nil)
            )
            present(alert, animated: true, completion: nil)
        }
        
    }
    
    func presentGroupView() {
        guard UserDefaults.standard.string(forKey: "fridgeId") != nil,
              UserDefaults.standard.string(forKey: "admin") != nil,
              UserDefaults.standard.object(forKey: "users") != nil else {
                  // TODO: Show error message
                  return
              }
        performSegue(withIdentifier: "presentGroupSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentGroupSegue",
           let vc = segue.destination as? GroupViewController,
           let admin = UserDefaults.standard.string(forKey: "admin"),
           let data = UserDefaults.standard.data(forKey: "users"),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            vc.groupMembers = users.filter { $0.id != admin }.sorted(by: { $0.name > $1.name })
            vc.groupHost = users.first(where: { $0.id == admin })
            vc.isAdmin = Auth.auth().currentUser?.uid == UserDefaults.standard.string(forKey: "admin")
        }
    }
    
    @IBAction func onCreateFridgePressed(_ sender: UIButton) {
        guard let user = Auth.auth().currentUser?.uid else {
            return
        }
        let categories = try! AppDelegate.viewContext.fetch(Category.fetchRequest())
        Task {
            try await FridgeManager.shared.createFridge(user: user, name: "My Fridge", categories: categories)
            await MainActor.run {
                presentGroupView()
            }
        }
    }
}


extension GroupSignUpViewController: ASAuthorizationControllerDelegate {
    
    @objc func handleLogInWithAppleID() {
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        currentNonce = randomNonceString()
        request.nonce = sha256(currentNonce!)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        controller.delegate = self
        controller.presentationContextProvider = self
        
        controller.performRequests()
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
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
                
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    guard let authResult = authResult else {
                        print(error!.localizedDescription)
                        return
                    }
                    
                    // Check if user exists
                    Task {
                        let exists = try await NetworkManager.shared.checkUserExists(id: authResult.user.uid)
                        
                        if !exists {
                            let name = appleIDCredential.fullName?.givenName
                            let email = appleIDCredential.email
                            try await NetworkManager.shared.createUser(name: name, email: email, id: authResult.user.uid)
                        }
                        // TODO: Check if user is in a group already
                        await MainActor.run { [weak self] in
                            self?.updateView()
                        }
                    }
                }
                break
            default:
                break
        }
    }
}

extension GroupSignUpViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
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
