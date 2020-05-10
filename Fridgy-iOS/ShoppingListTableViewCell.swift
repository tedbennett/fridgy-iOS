//
//  ShoppingListTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 10/05/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class ShoppingListTableViewCell: UITableViewCell {

    @IBOutlet weak var itemNameTextField: UITextField!
    
    @IBOutlet weak var checkBoxOutlet: UIImageView!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        checkBoxOutlet.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
    }
}
