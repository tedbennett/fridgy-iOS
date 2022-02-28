//
//  AppDelegate.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 27/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import StoreKit
import AuthenticationServices

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        var titleFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleFont = UIFont(
            descriptor:
                titleFont.fontDescriptor
                .withDesign(.rounded)? /// make rounded
                .withSymbolicTraits(.traitBold) ?? titleFont.fontDescriptor,
            size: titleFont.pointSize
        )
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: titleFont,
            .foregroundColor: UIColor.systemGreen
        ]
        
        
        SKPaymentQueue.default().add(StoreObserver.shared)
        
        checkLogin()
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        SKPaymentQueue.default().remove(StoreObserver.shared)
    }
    
    func checkLogin() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        guard let appleIdUid = Utility.appleIdUid else {
            // Logout
            return
        }
        appleIDProvider.getCredentialState(forUserID: appleIdUid) { (credentialState, error) in
            switch credentialState {
                case .authorized:
                    break // The Apple ID credential is valid.
                case .revoked, .notFound:
                    if UserManager.shared.isLoggedIn,
                       let id = UserManager.shared.userId {
                        try? UserManager.shared.logout()
                        Task {
                            try await UserManager.shared.deleteAccount(id: id)
                        }
                    }
                default:
                    break
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    static var persistentContainer: NSPersistentContainer {
        return (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }
    
    static var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    let container = NSPersistentCloudKitContainer(name: "Fridgy")
    
    // MARK: - Core Data Saving support
    
    static func saveContext () {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

    
    func testAccount() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signIn(withEmail: "test@test.com", password: "test123", completion: {
                authResult, error in
                Task {
                    try await NetworkManager.shared.createUser(name: "James", email: "test@test.com", id: authResult!.user.uid)
                }
            })
        }
    }
}

