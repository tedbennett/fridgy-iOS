//
//  FridgeEditorTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 05/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

protocol EditorTableViewCellDelegate: AnyObject {
    func didEndEditing(text: String)
}

class FridgeEditorTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    static let identifier = "FridgeEditorTableViewCell"

    @IBOutlet weak var shoppingListImageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    weak var delegate: EditorTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textField.delegate = self
    }

    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(text: String?, isShoppingList: Bool, delegate: EditorTableViewCellDelegate) {
        self.delegate = delegate
        
        textField.text = text
        shoppingListImageView.isHidden = !isShoppingList
    }
    
    func finishEditing() {
        guard let text = textField.text else { return }
        textField.resignFirstResponder()
        delegate?.didEndEditing(text: text)
        textField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        finishEditing()
        return true
    }
}
