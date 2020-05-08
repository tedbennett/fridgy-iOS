//
//  AddDateTableViewCell.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 08/05/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class AddNameTableCell: UITableViewCell {
 
    @IBOutlet weak var nameTextField: UITextField!

    
}

class AddDateTableCell: UITableViewCell {

    @IBOutlet weak var dateTextField: UITextField!
    
    let datePicker = UIDatePicker()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        createDatePickerView()
    }
    
    func createDatePickerView() {
        // text field formatting
        dateTextField.textAlignment = .center

        // date picker formatting
        datePicker.datePickerMode = .date

        // toolbar with done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(acceptDate))
        toolbar.setItems([doneButton], animated: true)


        dateTextField.inputAccessoryView = toolbar
        dateTextField.inputView = datePicker
    }
    
    func addTextFieldToolbar() {
        // toolbar with done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        

        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(acceptText))
        toolbar.setItems([doneButton], animated: true)
    }
    
    @objc func acceptDate() {
        // format date for text string
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        dateTextField.text = formatter.string(from: datePicker.date)
        self.endEditing(true)
    }
    
    @objc func acceptText() {
        self.endEditing(true)
    }
    

    
}



