//
//  FridgeTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 05/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

class FridgeTableViewCell: UITableViewCell {
    
    static let identifier = "FridgeTableViewCell"

    @IBOutlet weak var shoppingListImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(item: Item) {
        shoppingListImageView.isHidden = !item.inShoppingList
        textLabel?.text = item.name
    }

}
