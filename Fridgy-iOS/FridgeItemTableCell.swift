//
//  FridgeItemTableCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 30/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class FridgeItemTableCell: UITableViewCell {
    
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var itemExpiryLabel: UILabel!
    @IBOutlet weak var runningLowView: UIView!
    @IBOutlet weak var favouriteView: UIView!    
}
