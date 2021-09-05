//
//  ShoppingListTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 05/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

class ShoppingListTableViewCell: UITableViewCell {

    static let identifier = "ShoppingListTableViewCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func onButtonPressed(_ sender: UIButton) {
        checkButton.setImage(
            UIImage(systemName: "largecircle.fill.circle"),
            for: .normal
        )
    }
    
    func setup(name: String) {
        nameLabel.text = name
    }
}
