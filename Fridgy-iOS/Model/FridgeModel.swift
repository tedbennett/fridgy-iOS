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
    
    var categories: [Category] = []
    init() {
        if !UserDefaults.standard.bool(forKey: "launchedBefore") {
            let _ = Category(name: "Other", index: 0, context: AppDelegate.viewContext)
            try? AppDelegate.viewContext.save()
            UserDefaults.standard.setValue(true, forKey: "launchedBefore")
        } else {
            loadFromStore()
        }
    }
    
    // MARK: Lifecycle
    
    private func loadFromStore() {
        AppDelegate.viewContext.refreshAllObjects()
        let fetchRequest: NSFetchRequest = Category.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        if let fetchedItems = try? AppDelegate.viewContext.fetch(fetchRequest) {
            categories = fetchedItems
        }
        updateIndices()
    }

    private func updateIndices() {
        categories.enumerated().forEach { index, category in
            category.index = Int32(index)
            category.items.enumerated().forEach { index, item in
                item.index = Int32(index)
            }
        }
        AppDelegate.saveContext()
    }
    
    func refresh() {
        loadFromStore()
    }
    
    // MARK: Category Accessors
 
    func getCategory(at section: Int) -> Category {
        categories[section]
    }
    
    func addCategory(_ text: String, at index: Int? = nil) {
        let category = Category(
            name: text,
            index: index ?? categories.count,
            context: AppDelegate.viewContext
        )
        try! AppDelegate.viewContext.save()
        FridgeManager.shared.createCategory(category)
        
        if let index = index {
            categories.insert(category, at: index)
        } else {
            categories.append(category)
        }
    }
    
    func removeCategory(at index: Int) {
        let category = categories.remove(at: index)
        AppDelegate.viewContext.delete(category)
        FridgeManager.shared.deleteCategory(id: category.uniqueId)
        AppDelegate.saveContext()
    }
    
    func moveCategory(from origin: Int, to destination: Int) {
        let category = categories.remove(at: origin)
        categories.insert(category, at: destination)
        updateIndices()
    }
    
    // MARK: Item Accessors
    
    func getItem(for indexPath: IndexPath) -> Item {
        categories[indexPath.section].items[indexPath.row]
    }
    
    func getItems(for section: Int) -> [Item] {
        categories[section].items
    }
    
    func addItem(text: String, section: Int) {
        let category = categories[section]
        let index = category.items.count
        let item = Item(name: text, index: index, inShoppingList: false, context: AppDelegate.viewContext)
        
        category.addToChildren(item)
        AppDelegate.saveContext()
        
        FridgeManager.shared.addItem(item)
    }
    
    func updateItem(at indexPath: IndexPath, text: String) {
        let item = getItem(for: indexPath)
        item.name = text
        AppDelegate.saveContext()
        
        FridgeManager.shared.updateItem(item)
    }
    
    @discardableResult
    func moveItem(from origin: IndexPath, to destination: IndexPath) -> Bool {
        // Same category
         
        let category = categories[origin.section]
        let item = category.items[origin.row]
        if origin.section != destination.section {
            category.removeFromChildren(item)
        }
        
        let destinationCategory = getCategory(at: destination.section)
        
        var items = destinationCategory.items
        
        if origin.section == destination.section {
            items.remove(at: origin.row)
        }
        
        items.insert(item, at: destination.row)
        items.enumerated().forEach { index, item in
            item.index = Int32(index)
        }
        
        if origin.section != destination.section {
            destinationCategory.addToChildren(item)
            FridgeManager.shared.changeItemCategory(item, previous: category.uniqueId)
        }
        
        updateIndices()
        return true
    }
    
    func removeItem(at indexPath: IndexPath) {
        let category = categories[indexPath.section]
        let item = category.items[indexPath.row]
        category.removeFromChildren(item)
        AppDelegate.viewContext.delete(item)
        
        FridgeManager.shared.deleteItem(id: item.uniqueId, category: category.uniqueId)
        updateIndices()
    }
    
    // MARK: Helpers
    
    func isInBounds(_ indexPath: IndexPath) -> Bool {
        guard indexPath.section < categories.count else { return false}
        return indexPath.row < categories[indexPath.section].items.count
    }
    
    // MARK: Shopping List
    
    func addToShoppingList(at indexPath: IndexPath) {
        let item = getItem(for: indexPath)
        item.inShoppingList = true
        AppDelegate.saveContext()
        FridgeManager.shared.updateItem(item)
    }
    
    func removeFromShoppingList(at indexPath: IndexPath) {
        let item = getItem(for: indexPath)
        item.inShoppingList = false
        AppDelegate.saveContext()
        FridgeManager.shared.updateItem(item)
    }
}
