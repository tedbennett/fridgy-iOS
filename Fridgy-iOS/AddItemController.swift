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

    @IBOutlet weak var nameTextField : UITextField!
    
    @IBOutlet weak var dateTextField: UITextField!

    private var expiry = Date()
    
    private let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createDatePickerView()
        addTextFieldToolbar()
    }
    
    func createDatePickerView() {
    
        // date picker formatting
        datePicker.datePickerMode = .date

        // toolbar with done button
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let barButton = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: #selector(acceptDate))
        toolBar.setItems([flexible, barButton], animated: false)

        dateTextField.inputAccessoryView = toolBar
        dateTextField.inputView = datePicker
    }
    
    func addTextFieldToolbar() {
        // toolbar with done button
        let toolBar = UIToolbar(frame: CGRect(x: 0.0,
                                              y: 0.0,
                                              width: UIScreen.main.bounds.size.width,
                                              height: 44.0))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let barButton = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: #selector(acceptText))
        toolBar.setItems([flexible, barButton], animated: false)
        nameTextField.inputAccessoryView = toolBar
    }
    
    @objc func acceptDate() {
        // format date for text string
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        dateTextField.text = formatter.string(from: datePicker.date)
        expiry = datePicker.date
        self.view.endEditing(true)
    }
    
    @objc func acceptText() {
        self.view.endEditing(true)
    }

    @IBAction func addItemAction(_ sender: UIButton) {
        if nameTextField.text != "" {
            delegate?.addItem(name: nameTextField.text ?? "???", expiry: expiry)
            navigationController?.popViewController(animated: true)
        }
    }
    
    var delegate: AddItem?
}
