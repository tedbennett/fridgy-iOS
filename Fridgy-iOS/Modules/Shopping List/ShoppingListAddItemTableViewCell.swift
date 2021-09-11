//
//  ShoppingListAddItemTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 10/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

protocol AddItemToShoppingListDelegate: AnyObject {
    func didFinishEditing(text: String)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        delegate?.didFinishEditing(text: text)
        textField.resignFirstResponder()
        textField.text = ""
        return true
    }
}
