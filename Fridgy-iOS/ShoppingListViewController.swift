//
//  ShoppingListViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 10/05/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

protocol RemoveItem {
    func removeItem(uniqueId: String)
}

class ShoppingListViewController: UITableViewController {
    
    private var selectedRows = [IndexPath]()
    var items = [ShoppingListItem]()
    
    var delegate: (AddItem & EditItem & RemoveItem)?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedRows.isEmpty {
            addOrRestockButton.image = nil
            addOrRestockButton.title = "Restock"
        }
        if !selectedRows.contains(indexPath) {
            selectedRows.append(indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if selectedRows.contains(indexPath) {
            selectedRows.removeAll(where: {value in value == indexPath} )
        }
        if selectedRows.isEmpty {
            addOrRestockButton.title = nil
            addOrRestockButton.image = UIImage.init(systemName: "plus")
        }
    }
    
    @IBOutlet weak var addOrRestockButton: UIBarButtonItem!
    @IBAction func addOrRestockAction(_ sender: UIBarButtonItem) {
        if selectedRows.isEmpty {
            addItemPopup()
        } else {
            restockFridge()
        }
    }
    
    private func restockFridge() {
        let alert = UIAlertController(title: "Restock Fridge?", message: "The selected favourited items in this list will be restocked in your fridge using their saved shelf lives", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (_) in
            if let paths = self?.selectedRows {
                var itemsToBeRestocked = [ShoppingListItem]()
                for indexPath in paths {
                    if let item = self?.items[indexPath.row] {
                        itemsToBeRestocked.append(item)
                    }
                }
                for itemToEdit in itemsToBeRestocked {
                    if itemToEdit.shoppingListOnly {
                        self?.delegate?.removeItem(uniqueId: itemToEdit.uniqueId)
                    } else {
                        self?.delegate?.editItem(name: nil, expiry: nil, favourite: nil, runningLow: false, shoppingListOnly: false, removed: false, uniqueId: itemToEdit.uniqueId)
                    }
                    self?.items.removeAll(where: {$0 == itemToEdit})
                }
                self?.tableView.reloadData()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    private func addItemPopup() {
        let alert = UIAlertController(title: "Add Item", message: nil, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Enter Name"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert, weak self] (_) in
            if let text = alert?.textFields![0].text {
                let uniqueId = UUID().uuidString
                self?.delegate?.addItem(name: text, expiry: nil, favourite: nil, runningLow: nil, shoppingListOnly: true, removed: nil, uniqueId: uniqueId)
                self?.items.append(ShoppingListItem(name: text, shoppingListOnly: true, uniqueId: uniqueId))
                self?.tableView.reloadData()
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // MARK tables
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "shoppingListCell", for: indexPath) as? ShoppingListTableViewCell else {
            fatalError("Unexpected Index Path")
        }
        
        configureCell(cell, at: indexPath)
        
        return cell
    }
    
    
    private func updateView() {
        tableView.isHidden = !(items.count > 0)
    }
    
    private func configureCell(_ cell: ShoppingListTableViewCell, at indexPath: IndexPath) {
        cell.itemNameLabel.text = items[indexPath.row].name
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completionHandler) in
            
            if let itemToDelete = self?.items[indexPath.row] {
                if itemToDelete.shoppingListOnly {
                    self?.delegate?.removeItem(uniqueId: itemToDelete.uniqueId)
                    self?.items.removeAll(where: {$0 == itemToDelete})
                    self?.tableView.reloadData()
                } else {
                    let deletePopUp = UIAlertController(title: "Delete Item?", message: "This item will be deleted from your fridge too.", preferredStyle: .alert)
                    
                    let listAction = UIAlertAction(title: "OK", style: .default) { (action) in
                        self?.delegate?.removeItem(uniqueId: itemToDelete.uniqueId)
                        self?.items.removeAll(where: {$0 == itemToDelete})
                        self?.tableView.reloadData()
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                    deletePopUp.addAction(listAction)
                    deletePopUp.addAction(cancelAction)
                    self!.present(deletePopUp, animated: true, completion: nil)
                }
            }
            completionHandler(true)
            
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return configuration
    }
}

struct ShoppingListItem : Equatable {
    
    static func == (lhs: ShoppingListItem, rhs: ShoppingListItem) -> Bool {
        return lhs.uniqueId == rhs.uniqueId
    }
    
    var name : String
    var shoppingListOnly : Bool
    var uniqueId : String
    
}
