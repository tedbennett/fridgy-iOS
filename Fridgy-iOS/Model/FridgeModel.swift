//
//  FridgeModel.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 09/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import Foundation
import CoreData

class FridgeModel {
    
    
    private var lookup: [String: [Item]] = [:]
    var categories = UserDefaults.standard.stringArray(forKey: "categories") ?? ["Other"] {
        didSet {
            UserDefaults.standard.setValue(categories, forKey: "categories")
        }
    }
    
    init() {
        if !UserDefaults.standard.bool(forKey: "launchedBefore") {
            categories = ["Other"]
            UserDefaults.standard.setValue(true, forKey: "launchedBefore")
        }
        loadFromStore()
    }
    
    // MARK: Lifecycle
    
    private func loadFromStore() {
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
        updateIndices()
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
    
    func refresh() {
        loadFromStore()
    }
    
    // MARK: Category Accessors
 
    func getCategory(at section: Int) -> String {
        return categories[section]
    }
    
    func addCategory(_ text: String, at index: Int? = nil) {
        if let index = index {
            categories.insert(text, at: index)
        } else {
            categories.append(text)
        }
        lookup[text] = []
    }
    
    func removeCategory(at index: Int) {
        let category = categories.remove(at: index)
        if let items = lookup[category] {
            items.forEach { AppDelegate.viewContext.delete($0) }
        }
        AppDelegate.saveContext()
        lookup[category] = nil
    }
    
    // MARK: Item Accessors
    
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
    
    func addItem(text: String, section: Int, row: Int? = nil) {
        let category = categories[section]
        let index = getItems(for: section).count
        let item = Item(context: AppDelegate.viewContext)
        item.name = text
        item.category = category
        item.index = Int16(index)
        item.uniqueId = UUID().uuidString
        
        if let row = row {
            lookup[category]?.insert(item, at: row)
        } else {
            // Insert at end
            if lookup[category] != nil {
                lookup[category]?.append(item)
            } else {
                lookup[category] = [item]
            }
        }
        
        AppDelegate.saveContext()
    }
    
    func updateItem(at indexPath: IndexPath, text: String) {
        let item = getItem(for: indexPath)
        item.name = text
        item.shoppingListItem?.name = text
        AppDelegate.saveContext()
    }
    
    @discardableResult
    func moveItem(from origin: IndexPath, to destination: IndexPath) -> Bool {
        let category = getCategory(at: origin.section)
        guard let item = lookup[category]?.remove(at: origin.row) else {
            return false
        }
        
        let destinationCategory = getCategory(at: destination.section)
        lookup[destinationCategory]?.insert(item, at: destination.row)
        
        updateIndices()
        
        return true
    }
    
    func removeItem(at indexPath: IndexPath) {
        let category = categories[indexPath.section]
        if let item = lookup[category]?.remove(at: indexPath.row) {
            AppDelegate.viewContext.delete(item)
            
            updateIndices()
        }
    }
    
    // MARK: Helpers
    
    func isInBounds(_ indexPath: IndexPath) -> Bool {
        let items = getItems(for: indexPath.section)
        return indexPath.row < items.count
    }
    
    // MARK: Shopping List
    
    func addToShoppingList(at indexPath: IndexPath) {
        let item = getItem(for: indexPath)
        let shoppingListItem = ShoppingListItem(context: AppDelegate.viewContext)
        shoppingListItem.name = item.name
        shoppingListItem.uniqueId = item.uniqueId
        shoppingListItem.fridgeItem = item
        
        AppDelegate.saveContext()
    }
    
    func removeFromShoppingList(at indexPath: IndexPath) {
        let category = categories[indexPath.section]
        if lookup[category] != nil {
            if let shoppingListItem = lookup[category]?[indexPath.row].shoppingListItem {
                AppDelegate.viewContext.delete(shoppingListItem)
                AppDelegate.saveContext()
            }
        }
    }
}
