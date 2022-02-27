//
//  Utility.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 26/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import UIKit

struct Utility {
    static func alert(_ title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("OK", comment: ""),
                                   style: .default, handler: nil)
        alertController.addAction(action)
        return alertController
    }
    
    static var fridgeId: String? {
        get {
            UserDefaults.standard.string(forKey: "fridgeId")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "fridgeId")
        }
    }
    
    static var appleIdUid: String? {
        get {
            UserDefaults.standard.string(forKey: "appleIdUid")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "appleIdUid")
        }
    }
    
    static var plusId: String? {
        get {
            UserDefaults.standard.string(forKey: "plusId")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "plusId")
        }
    }
    
    static var admin: String? {
        get {
            UserDefaults.standard.string(forKey: "admin")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "admin")
        }
    }
    
    static var users: [User]? {
        get {
            if let data = UserDefaults.standard.data(forKey: "users"),
               let users = try? JSONDecoder().decode([User].self, from: data) {
                return users
            }
            return nil
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: "users")
        }
    }
    
    static var launchedBefore: Bool {
        get {
            UserDefaults.standard.bool(forKey: "launchedBefore")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "launchedBefore")
        }
    }
    
    static var lastOpenedVersion: String? {
        get {
            UserDefaults.standard.string(forKey: "LAST_OPENED_VERSION")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "LAST_OPENED_VERSION")
        }
    }
}
