//
//  SceneDelegate.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 27/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit
import AuthenticationServices

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        UserManager.shared.presentationDelegate = self
        
        checkFridge()
        
        if let url = connectionOptions.userActivities.first?.webpageURL {
            handleUrl(url)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let url = userActivity.webpageURL {
            handleUrl(url)
        }
    }
    
    func checkFridge() {
        if let id = Utility.fridgeId, let user = UserManager.shared.userId {
            Task {
                let exists = try await NetworkManager.shared.checkFridgeExists(id: id)
                let inFridge = try await NetworkManager.shared.checkInFridge(userId: user, fridgeId: id)
                if !exists || !inFridge {
                    Utility.fridgeId = nil
                    await MainActor.run {
                        if let tabBarController = self.window?.rootViewController as? UITabBarController,
                           let nav = tabBarController.selectedViewController as? UINavigationController {
                            nav.visibleViewController?.alert(with: "Shared Fridge left", message: "Your fridge will no longer be synced")
                        }
                    }
                }
            }
            
        }
    }
    
    func handleUrl(_ url: URL) {
        guard url.host == "www.fridgy-app.com" || url.host == "fridgy-app.com",
              url.pathComponents.count == 3,
              url.pathComponents[1] == "group" else {
                  return
              }
        let groupId = url.pathComponents[2]
        if let tabBarController = self.window?.rootViewController as? UITabBarController {
            tabBarController.selectedIndex = 2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            if let tabBarController = self.window?.rootViewController as? UITabBarController,
               let nav = tabBarController.selectedViewController as? UINavigationController {
                if let groupVC = nav.visibleViewController as? GroupViewController {
                    groupVC.handleJoinSession(id: groupId)
                } else if let signupVC = nav.visibleViewController as? GroupSignUpViewController {
                    signupVC.handleJoinSession(id: groupId)
                }
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

// MARK: ASAuthorizationControllerPresentationContextProviding

extension SceneDelegate: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.window!
    }
}
