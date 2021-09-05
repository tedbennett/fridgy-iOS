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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.isEditing = true
        
//        tableView.dragDelegate = self
//        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        tableView.register(
            FridgeTableHeaderView.self,
           forHeaderFooterViewReuseIdentifier: FridgeTableHeaderView.identifier
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
            
            lookup = fetchedItems.reduce(into: [:]) { dict, item in
                dict[item.category, default: []].append(item)
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
}

// MARK: UITableViewDelegate

extension FridgeViewController: UITableViewDelegate {
    
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
    
    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: FridgeTableHeaderView.identifier
        ) as! FridgeTableHeaderView
        let category = categories[section]
        view.setup(title: category, action: { [weak self] in
            guard let self = self else { return }
            if self.categoryBeingEdited == nil {
                self.categoryBeingEdited = section
                self.tableView.reloadData()
            }
        })
        return view
    }
    
    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return 40
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let items = getItems(for: indexPath.section)
        if categoryBeingEdited == indexPath.section && indexPath.row == items.count {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: FridgeEditorTableViewCell.identifier, for: indexPath) as? FridgeEditorTableViewCell else {
                fatalError("Failed to dequeue FridgeEditorTableViewCell")
            }
            cell.setup(section: indexPath.section, delegate: self)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "FridgeTableViewCell",
            for: indexPath
        )
        
        cell.textLabel?.text = items[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? FridgeEditorTableViewCell else { return }
        cell.textField.becomeFirstResponder()
    }
    
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
        
    func removeItem(at indexPath: IndexPath) {
        let category = categories[indexPath.section]
        if let item = lookup[category]?.remove(at: indexPath.row) {
            AppDelegate.viewContext.delete(item)
        }
        
        updateIndices()
        tableView.reloadData()
    }
}


// MARK: EditorTableViewCellDelegate

extension FridgeViewController: EditorTableViewCellDelegate {
    
    func didEndEditing(at index: Int, text: String) {
        let category = categories[index]
        
        let items = getItems(for: index)
        
        let item = Item(context: AppDelegate.viewContext)
        item.name = text
        item.category = category
        item.index = Int16(items.count)
        item.inShoppingList = false
        
        AppDelegate.saveContext()
        
        if lookup[category] != nil {
            lookup[category]?.append(item)
        } else {
            lookup[category] = [item]
        }
        
        categoryBeingEdited = nil
        let indexPath = IndexPath(row: items.count, section: index)
        if let cell = tableView.cellForRow(at: indexPath) as? FridgeEditorTableViewCell {
            cell.textFieldResignFirstResponder()
        }
        view.resignFirstResponder()
        view.endEditing(true)
        tableView.reloadData()
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
