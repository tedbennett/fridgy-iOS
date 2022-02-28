//
//  AppExtensions.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 26/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import Foundation
import StoreKit
import UIKit


// MARK: - SKProduct

extension SKProduct {
    /// - returns: The cost of the product formatted in the local currency.
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}

extension UIView {
    @IBInspectable private var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
}

extension UIViewController {
    func alert(with title: String, message: String) {
        let alertController = Utility.alert(title, message: message)
        alertController.view.tintColor = .systemGreen
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
}
