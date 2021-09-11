//
//  AddCategoryTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 09/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

protocol AddCategoryDelegate: AnyObject {
    func didEndEditing(text: String)
}

class AddCategoryTableViewCell: UITableViewCell, UITextFieldDelegate {

    static let identifier = "AddCategoryTableViewCell"
    
    @IBOutlet weak var textField: UITextField!
    
    weak var delegate: AddCategoryDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        textField.delegate = self
    }

    func setup(text: String?, delegate: AddCategoryDelegate) {
        self.delegate = delegate
        
        textField.text = text
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true  }
        textField.resignFirstResponder()
        delegate?.didEndEditing(text: text)
        textField.text = ""
        return true
    }
}
