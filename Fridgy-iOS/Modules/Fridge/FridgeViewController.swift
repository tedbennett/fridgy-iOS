//
//  FridgeViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

class FridgeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var lookup: [String: [Item]] = [:]
    var categories: [String] = [] {
        didSet {
            UserDefaults.standard.setValue(categories, forKey: "categories")
        }
    }
    
    func getItems(for section: Int) -> [Item] {
        let category = categories[section]
        guard let items = lookup[category] else {
            fatalError("Category not found in lookup")
        }
        return items
    }
    
    func getItem(for indexPath: IndexPath) -> Item {
        let items = getItems(for: indexPath.section)
        return items[indexPath.row]
    }
    
    var categoryBeingEdited: Int?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
//        tableView.dragDelegate = self
//        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        tableView.register(
            FridgeTableHeaderView.self,
           forHeaderFooterViewReuseIdentifier: FridgeTableHeaderView.identifier
        )
        
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

        loadFromStore()
    }
    
    func loadFromStore() {
        let fetchRequest: NSFetchRequest = Item.fetchRequest()
        if let fetchedItems = try? AppDelegate.viewContext.fetch(fetchRequest) {
            if let retrievedCategories = UserDefaults.standard.array(forKey: "categories") as? [String] {
                categories = retrievedCategories
            }
            // Make sure no categories are set to nil
            categories.forEach {
                lookup[$0] = []
            }
            
            fetchedItems.forEach { item in
                // Optional but we just populated lookup keys
                lookup[item.category]?.append(item)
            }
            
            lookup.forEach { key, array in
                lookup[key] = array.sorted { $0.index < $1.index }
            }
        }
    }
    
    private func updateIndices() {
        lookup.forEach { category, items in
            items.enumerated().forEach { index, item in
                item.category = category
                item.index = Int16(index)
            }
        }
        AppDelegate.saveContext()
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

// MARK: UITableViewDelegate

extension FridgeViewController: UITableViewDelegate {
    
    // MARK: TableView Header
    
    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: FridgeTableHeaderView.identifier
        ) as! FridgeTableHeaderView
        let category = categories[section]
        view.setup(title: category, section: section, delegate: self)
        return view
    }
    
    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return 40
    }
    
    // MARK: TableView Editing
    
    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(
        _ tableView: UITableView,
        shouldIndentWhileEditingRowAt indexPath: IndexPath
    ) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let items = getItems(for: indexPath.section)
        if indexPath.row == items.count {
            return false
        }
        return true
    }
    
    // MARK: TableView Swipe Actions
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let items = getItems(for: indexPath.section)
        guard indexPath.row < items.count else { return nil }
        
        let removeItem = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] (action, view, completionHandler) in
            self?.removeItem(at: indexPath)
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [removeItem])
    }
    
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // Prevent swipe actions for editing cell
        let items = getItems(for: indexPath.section)
        guard indexPath.row < items.count else { return nil }
        
        let item = getItem(for: indexPath)
        if item.shoppingListItem != nil {
            let action = UIContextualAction(
                style: .normal,
                title: "Remove from Shopping List"
            ) { [weak self] _, _, completionHandler in
                self?.removeFromShoppingList(at: indexPath)
                completionHandler(true)
            }
            action.backgroundColor = .systemYellow
            return UISwipeActionsConfiguration(actions: [action])
        } else {
            let action = UIContextualAction(
                style: .normal,
                title: "Add to Shopping List"
            ) { [weak self] _, _, completionHandler in
                self?.addToShoppingList(at: indexPath)
                completionHandler(true)
            }
            action.backgroundColor = .systemYellow
            return UISwipeActionsConfiguration(actions: [action])
        }
    }
    
    func addToShoppingList(at indexPath: IndexPath) {
        let item = getItem(for: indexPath)
        let shoppingListItem = ShoppingListItem(context: AppDelegate.viewContext)
        shoppingListItem.name = item.name
        shoppingListItem.fridgeItem = item
        
        AppDelegate.saveContext()
        tableView.reloadData()
    }
    
    func removeFromShoppingList(at indexPath: IndexPath) {
        let category = categories[indexPath.section]
        if lookup[category] != nil {
            if let shoppingListItem = lookup[category]?[indexPath.row].shoppingListItem {
                AppDelegate.viewContext.delete(shoppingListItem)
                AppDelegate.saveContext()
                tableView.reloadData()
            }
        }
    }
    
    func removeItem(at indexPath: IndexPath) {
        let category = categories[indexPath.section]
        if let item = lookup[category]?.remove(at: indexPath.row) {
            AppDelegate.viewContext.delete(item)
        }
        
        updateIndices()
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}

// MARK: UITableViewDataSource

extension FridgeViewController: UITableViewDataSource {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        let items = getItems(for: section)
        if categoryBeingEdited == section {
            return items.count + 1
        }
        return items.count
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    
    
    // MARK: TableView Cell
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let items = getItems(for: indexPath.section)
        if categoryBeingEdited == indexPath.section && indexPath.row == items.count {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: FridgeEditorTableViewCell.identifier,
                for: indexPath
            ) as? FridgeEditorTableViewCell else {
                fatalError("Failed to dequeue FridgeEditorTableViewCell")
            }
            cell.setup(section: indexPath.section, delegate: self)
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FridgeTableViewCell.identifier,
            for: indexPath
        ) as? FridgeTableViewCell  else {
            fatalError("Failed to dequeue FridgeTableViewCell")
        }
        cell.setup(item: items[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? FridgeEditorTableViewCell else { return }
        cell.textField.becomeFirstResponder()
    }
    
    // MARK: TableView Moving Cells
    
    func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        let sourceCategory = categories[sourceIndexPath.section]

        guard let movedObject = lookup[sourceCategory]?[sourceIndexPath.row] else {
            fatalError("Category not found in lookup")
        }
        
        let destinationCategory = categories[destinationIndexPath.section]
        
        lookup[sourceCategory]?.remove(at: sourceIndexPath.row)
        lookup[destinationCategory]?.insert(movedObject, at: destinationIndexPath.row)
        
        updateIndices()
    }
}

// MARK: EditorTableViewCellDelegate

extension FridgeViewController: EditorTableViewCellDelegate {
    
    func didEndEditing(at index: Int, text: String) {
        let category = categories[index]
        
        let items = getItems(for: index)
        if text != "" {
            let item = Item(context: AppDelegate.viewContext)
            item.name = text
            item.category = category
            item.index = Int16(items.count)
            
            AppDelegate.saveContext()
            
            if lookup[category] != nil {
                lookup[category]?.append(item)
            } else {
                lookup[category] = [item]
            }
        }
        
        categoryBeingEdited = nil
        tableView.reloadData()
    }
}

// MARK: HeaderTableViewCellDelegate

extension FridgeViewController: HeaderTableViewCellDelegate {
    func didStartEditing(at index: Int) {
        if self.categoryBeingEdited == nil {
            categoryBeingEdited = index
            tableView.reloadData()
            let row = getItems(for: index).count
            tableView.scrollToRow(at: IndexPath(row: row, section: index), at: .bottom, animated: true)
        }
    }
}


// MARK: UITableViewDragDelegate

//extension FridgeViewController: UITableViewDragDelegate {
//    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//        let item = getItem(for: indexPath)
//        let itemProvider = NSItemProvider(object: item)
//
//        let dragItem = UIDragItem(itemProvider: itemProvider)
//
//        return [dragItem]
//    }
//
//    func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
//        let placeName = placeNames[indexPath.row]
//
//        let data = placeName.data(using: .utf8)
//        let itemProvider = NSItemProvider()
//
//        itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypePlainText as String, visibility: .all) { completion in
//            completion(data, nil)
//            return nil
//        }
//
//        return [
//            UIDragItem(itemProvider: itemProvider)
//        ]
//    }
//}


// MARK: UITableViewDropDelegate

//extension FridgeViewController: UITableViewDropDelegate {
//    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
//        <#code#>
//    }
//
//
//}
