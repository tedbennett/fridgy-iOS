//
//  TabBarController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 02/03/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import UIKit

//
class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delegate = self
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        delegate = self
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return viewController != selectedViewController
    }
    
}
