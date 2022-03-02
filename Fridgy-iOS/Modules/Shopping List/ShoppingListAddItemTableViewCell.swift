//
//  ShoppingListAddItemTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 10/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

protocol AddItemToShoppingListDelegate: AnyObject {
    func didFinishEditing(text: String, spawnNewItem: Bool)
}

class ShoppingListAddItemTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    static let identifier = "ShoppingListAddItemTableViewCell"
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var checkButton: UIButton!
    
    weak var delegate: AddItemToShoppingListDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textField.delegate = self
        
        let largeConfig = UIImage.SymbolConfiguration(
            pointSize: 20,
            weight: .regular,
            scale: .medium
        )
        
        checkButton.setImage(UIImage(
            systemName: "circle",
            withConfiguration: largeConfig
        ), for: .normal)
    }
    
    func finishEditing(spawnNewItem: Bool) {
        guard let text = textField.text else { return }
        delegate?.didFinishEditing(text: text, spawnNewItem: spawnNewItem && !text.isEmpty)
        if !(spawnNewItem && !text.isEmpty) {
            textField.resignFirstResponder()
        }
        textField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        finishEditing(spawnNewItem: true)
        return true
    }
}
