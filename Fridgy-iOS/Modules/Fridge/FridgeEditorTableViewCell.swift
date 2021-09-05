//
//  FridgeEditorTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 05/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

protocol EditorTableViewCellDelegate: AnyObject {
    func didEndEditing(at index: Int, text: String)
}

class FridgeEditorTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    static let identifier = "FridgeEditorTableViewCell"

    @IBOutlet weak var textField: UITextField!
    
    weak var delegate: EditorTableViewCellDelegate?
    var section: Int?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        textField.delegate = self
    }

    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setup(section: Int, delegate: EditorTableViewCellDelegate) {
        self.section = section
        self.delegate = delegate
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let section = section, let text = textField.text else { return true  }
        textFieldResignFirstResponder()
        delegate?.didEndEditing(at: section, text: text)
        textField.text = ""
        return false
    }
    
    func textFieldBecomeFirstResponder() {
        textField.becomeFirstResponder()
    }
    
    func textFieldResignFirstResponder() {
        textField.resignFirstResponder()
    }
}
