//
//  GlobalSettings.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 11/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import Foundation

struct GlobalSettings {
    
    static var appVersion = "2.0.0"
    
    // This checks whether we are opening the app for the first time since an update to show
    static func updateAppVersion() -> String? {
        let oldVersion = UserDefaults.standard.string(forKey: "LAST_OPENED_VERSION")
        UserDefaults.standard.setValue(appVersion, forKey: "LAST_OPENED_VERSION")
        return oldVersion
    }
}
