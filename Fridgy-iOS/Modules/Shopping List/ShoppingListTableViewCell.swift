//
//  ShoppingListTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 05/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

protocol ShoppingListSelectDelegate: AnyObject {
    func didSelectItem(with id: String)
    func didDeselectItem(with id: String)
}


class ShoppingListTableViewCell: UITableViewCell {

    static let identifier = "ShoppingListTableViewCell"
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    
    var cellChecked = false
    var id: String?
    
    weak var delegate: ShoppingListSelectDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setup(item: Item, delegate: ShoppingListSelectDelegate) {
        self.delegate = delegate
        id = item.uniqueId
        nameLabel.text = item.name
        cellChecked = false
        
        let largeConfig = UIImage.SymbolConfiguration(
            pointSize: 20,
            weight: .regular,
            scale: .medium
        )
        
        checkButton.setImage(
            UIImage(systemName: "circle",
                    withConfiguration: largeConfig),
            for: .normal
        )
    }
}


// MARK: IBActions

extension ShoppingListTableViewCell {
    @IBAction func onButtonPressed(_ sender: UIButton) {
        let largeConfig = UIImage.SymbolConfiguration(
            pointSize: 20,
            weight: .regular,
            scale: .medium
        )
        checkButton.setImage(
            UIImage(systemName: cellChecked ? "circle" : "largecircle.fill.circle",
                    withConfiguration: largeConfig),
            for: .normal
        )
        cellChecked.toggle()
        guard let id = id else { return }
        if cellChecked {
            delegate?.didSelectItem(with: id)
        } else {
            delegate?.didDeselectItem(with: id)
        }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
