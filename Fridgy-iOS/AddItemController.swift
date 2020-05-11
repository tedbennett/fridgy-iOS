//
//  AddItemController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 29/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

protocol AddItem {
    func addItem(name: String, expiry: Date, favourite: Bool)
}

protocol EditItem {
    func editItem(name: String, expiry: Date, favourite: Bool, uniqueId: String)
}

class AddItemController: UIViewController {
    
    var expiry = Date()
    
    @IBOutlet weak var nameTextField : UITextField!
    
    @IBOutlet weak var dateTextField: UITextField!

    @IBOutlet weak var favouriteItemOutlet: UISwitch!
    
    @IBAction func cancelAction(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
    }
    @IBOutlet weak var doneButtonOutlet: UIButton!
    
    private let datePicker = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createDatePickerView()
        addTextFieldToolbar()
        doneButtonOutlet.layer.cornerRadius = 8
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
    
    fileprivate func formattedDate(_ date : Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
       return formatter.string(from: date)
    }
    
    @objc func acceptDate() {
        // format date for text string
        dateTextField.text = formattedDate(datePicker.date)
        expiry = datePicker.date
        self.view.endEditing(true)
    }
    
    @objc func acceptText() {
        self.view.endEditing(true)
    }

    @IBAction func doneButtonAction(_ sender: UIButton) {
        if nameTextField.text != "", dateTextField.text != "" {
            
            delegate?.addItem(name: nameTextField.text ?? "???", expiry: expiry, favourite: favouriteItemOutlet.isOn)
            dismiss(animated: true, completion: nil)
        }
    }
    
    var delegate: AddItem?
}

// Extension to give max text field length
private var __maxLengths = [UITextField: Int]()
extension UITextField {
    @IBInspectable var maxLength: Int {
        get {
            guard let l = __maxLengths[self] else {
                return 150
            }
            return l
        }
        set {
            __maxLengths[self] = newValue
            addTarget(self, action: #selector(fix), for: .editingChanged)
        }
    }
    @objc func fix(textField: UITextField) {
        let t = textField.text
        textField.text = String((t?.prefix(maxLength))!)
    }
}

class EditItemController : AddItemController {
    
    
    var name : String?
    var favourite : Bool?
    var uniqueId : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameTextField.text = name
        self.dateTextField.text = formattedDate(expiry)
        self.favouriteItemOutlet.isOn = favourite ?? false
    }
    
    var editDelegate: EditItem?
    
    @IBAction override func doneButtonAction(_ sender: UIButton) {
        if nameTextField.text != "", dateTextField.text != "" {
            
            editDelegate?.editItem(name: nameTextField.text ?? "???", expiry: expiry, favourite: favouriteItemOutlet.isOn, uniqueId: uniqueId ?? "")
            dismiss(animated: true, completion: nil)
        }
    }
}
