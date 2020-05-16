//
//  FridgeItemTableCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 30/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

protocol FavouriteItem {
    func favouriteItem(uniqueId : String)
}

class FridgeItemTableCell: UITableViewCell {
    
    @IBOutlet weak var itemNameLabel: UILabel!
    @IBOutlet weak var runningLowView: UIView!
    @IBOutlet weak var favouriteButton: UIButton!
    
    var delegate : FavouriteItem?
    var uniqueId : String?
    
    @IBAction func favouriteAction(_ sender: UIButton) {
        delegate?.favouriteItem(uniqueId: uniqueId!)
    }
}
