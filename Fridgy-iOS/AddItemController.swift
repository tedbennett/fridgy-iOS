//
//  AddItemController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 29/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

protocol AddItem {
    func addItem(name: String, expiry: Date)
}

class AddItemController: UIViewController {

    private var expiry = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createDatePickerView()
    }

    private let datePicker = UIDatePicker()
    
    @IBOutlet weak var itemNameOutlet: UITextField!
    @IBOutlet weak var itemDateOutlet: UITextField!
    
    
    func createDatePickerView() {
        // text field formatting
        itemDateOutlet.textAlignment = .center
        
        // date picker formatting
        datePicker.datePickerMode = .date
        
        // toolbar with done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(acceptDate))
        toolbar.setItems([doneButton], animated: true)
        
        
        itemDateOutlet.inputAccessoryView = toolbar
        itemDateOutlet.inputView = datePicker
    }
    
    @objc func acceptDate() {
        // format date for text string
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        itemDateOutlet.text = formatter.string(from: datePicker.date)
        expiry = datePicker.date
        self.view.endEditing(true)
    }
    
    
    @IBAction func addItemAction(_ sender: Any) {
        if itemNameOutlet.text != "" {
            delegate?.addItem(name: itemNameOutlet.text ?? "???", expiry: expiry)
            navigationController?.popViewController(animated: true)
        }
    }
    
    var delegate: AddItem?
}
