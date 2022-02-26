//
//  ShoppingListViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        populateItems()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    var isAddingItem = false
    
    var items: [Item] = []
    var idsToRemove: [String] = [] // Items that will be deleted
    
    func populateItems() {
        AppDelegate.viewContext.refreshAllObjects()
        let shoppingListFetch = Item.fetchRequest()
        shoppingListFetch.predicate = NSPredicate(format: "inShoppingList == %@", NSNumber(value: true))
        shoppingListFetch.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        if let fetchedItems = try? AppDelegate.viewContext.fetch(shoppingListFetch) {
            items = fetchedItems
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        populateItems()
        tableView.reloadData()
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func deleteItem(at index: Int) {
        let item = items.remove(at: index)
        
        item.inShoppingList = false
        item.inFridge = true
        FridgeManager.shared.updateItem(item)
        
        AppDelegate.saveContext()
        
        let indexPath = IndexPath(row: index, section: 0)
        self.tableView.deleteRows(at: [indexPath], with: .fade)
    }
}

// MARK: IBActions

extension ShoppingListViewController {
    
    @IBAction func onAddButtonPressed(_ sender: UIBarButtonItem) {
        isAddingItem = true
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        tableView.reloadData()
    }
}

// MARK: UITableViewDelegate

extension ShoppingListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return 40
    }
}


// MARK: UITableViewDataSource

extension ShoppingListViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return isAddingItem ? items.count + 1 : items.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if isAddingItem && indexPath.row == items.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ShoppingListAddItemTableViewCell.identifier, for: indexPath) as? ShoppingListAddItemTableViewCell else {
                fatalError("Failed to dequeue ShoppingListAddItemTableViewCell")
            }
            cell.delegate = self
            return cell
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ShoppingListTableViewCell.identifier, for: indexPath) as? ShoppingListTableViewCell else {
            fatalError("Failed to dequeue ShoppingListTableViewCell")
        }
        let item = items[indexPath.row]
        cell.setup(item: item, delegate: self)
        return cell
    }
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard let cell = cell as? ShoppingListAddItemTableViewCell else { return }
        cell.textField.becomeFirstResponder()
    }
}


// MARK: ShoppingListSelectDelegate

extension ShoppingListViewController: ShoppingListSelectDelegate {
    func didSelectItem(with id: String) {
        idsToRemove.append(id)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            if self.idsToRemove.contains(id), let index = self.items.firstIndex(where: { $0.uniqueId == id }) {
                self.deleteItem(at: index)
            }
        }
    }
    
    func didDeselectItem(with id: String) {
        if let index = idsToRemove.firstIndex(of: id) {
            idsToRemove.remove(at: index)
        }
    }
    
    func showInShoppingListAlert() {
        let alert = UIAlertController(title: "Item Not In Fridge", message: "This will be automatically added to the 'Other' category of your fridge when you check it.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}

// MARK: AddItemToShoppingListDelegate

extension ShoppingListViewController: AddItemToShoppingListDelegate {
    func didFinishEditing(text: String) {
        isAddingItem = false
        let item = Item(name: text, index: nil, inShoppingList: true, context: AppDelegate.viewContext)
        AppDelegate.saveContext()
        FridgeManager.shared.addItem(item)
        
        items.append(item)
        tableView.reloadData()
    }
}
