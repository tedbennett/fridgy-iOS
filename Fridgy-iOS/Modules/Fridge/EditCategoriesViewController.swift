//
//  EditCategoriesViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 09/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

protocol EditCategoriesDelegate: AnyObject {
    func didFinishEditingCategories()
}

class EditCategoriesViewController: UIViewController {
    
    var model: FridgeModel!
    weak var delegate: EditCategoriesDelegate?
    
    var isAddingCategory = false
    var editingCategory: IndexPath?
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isEditing = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.didFinishEditingCategories()
    }
    
    @objc func dismissKeyboard() {
        // Try and find cell being edited to get it's text
        if isAddingCategory {
            let indexPath = IndexPath(row: model.categories.count, section: 0)
            if let cell = tableView.cellForRow(at: indexPath) as? AddCategoryTableViewCell {
                cell.finishEditing()
                view.endEditing(false)
            }
        }
    }
}

// MARK: IBActions

extension EditCategoriesViewController {
    @IBAction func onAddButtonPressed(_ sender: UIBarButtonItem) {
        if editingCategory == nil {
            isAddingCategory = true
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        tableView.reloadData()
    }
    
    @IBAction func onDoneButtonPressed(_ sender: UIBarButtonItem) {
        dismissKeyboard()
        dismiss(animated: true)
    }
}


// MARK: UITableViewDelegate

extension EditCategoriesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if !isAddingCategory {
            editingCategory = indexPath
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? AddCategoryTableViewCell else { return }
        cell.textField.becomeFirstResponder()
    }
    
    // MARK: TableView Editing
    
    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        if indexPath.row == model.categories.count {
            return .none
        } else if editingCategory == indexPath {
            return .none
        } else if indexPath.row < model.categories.count && model.categories[indexPath.row].name == "Other" {
            return .none
        }
        return .delete
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == model.categories.count || editingCategory == indexPath {
            return false
        }
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if !model.getItems(for: indexPath.row).isEmpty {
                let alert = UIAlertController(title: "Category Not Empty", message: "Deleting this category will also delete its items!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
                
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
                    guard let self = self else { return }
                    self.model.removeCategory(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }))
                alert.view.tintColor = .systemGreen
                self.present(alert, animated: true, completion: nil)
            } else {
                model.removeCategory(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    // MARK: TableView Moving Cells
    
    func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        model.moveCategory(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }
}

// MARK: UITableViewDataSource

extension EditCategoriesViewController: UITableViewDataSource {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return isAddingCategory ? model.categories.count + 1 : model.categories.count
    }
    
    // MARK: TableView Cell
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if isAddingCategory && indexPath.row == model.categories.count {
            guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: AddCategoryTableViewCell.identifier
            ) as? AddCategoryTableViewCell else {
                fatalError("Failed to dequeue AddCategoryTableViewCell")
            }
            cell.setup(text: nil, delegate: self)
            return cell
        }
        if editingCategory == indexPath {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddCategoryTableViewCell.identifier
            ) as? AddCategoryTableViewCell else {
                fatalError("Failed to dequeue AddCategoryTableViewCell")
            }
            cell.setup(text: model.categories[indexPath.row].name, delegate: self)
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "editCategoryCell")!
        cell.textLabel?.text = model.categories[indexPath.row].name
        return cell
    }
}


// MARK: AddCategoryDelegate

extension EditCategoriesViewController: AddCategoryDelegate {
    func didEndEditing(text: String) {
        if !text.isEmpty {
            model.addCategory(text)
        }
        isAddingCategory = false
        editingCategory = nil
        
        tableView.reloadData()
    }
}

