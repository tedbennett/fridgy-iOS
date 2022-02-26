//
//  FridgeManager.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 11/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import Foundation
import CoreData

// In charge of the remote fridge
// Handles sending updates and taking care of joining/leaving
class FridgeManager {
    static var shared = FridgeManager()
    
    private init() {
        // Check keychain if users bought premium before and if in group
        
        // Else check online as may have uninstalled the app
        
    }
    
    var inSharedFridge: Bool { UserDefaults.standard.string(forKey: "fridgeId") != nil }
    
    var pendingRecords: [Record] = []
    
    actor PendingRecordsStore {
        var records: [Record] = []
        func append(_ record: Record) {
            records.append(record)
        }
    }
    
    func fetchFridge(context: NSManagedObjectContext) async throws {
        // First check that all
        
        if !pendingRecords.isEmpty {
            let store = PendingRecordsStore()
            // Execute records synchronously
            for record in pendingRecords {
                let success = try await executeRecord(record)
                if !success {
                    await store.append(record)
                }
            }
            let records = await store.records
            if !records.isEmpty {
                // Send message to user that not all
                self.pendingRecords = records
            }
            let fridge = try await NetworkManager.shared.getFridge()
            try self.syncDatabase(fridge: fridge, context: context)
        } else {
            let fridge = try await NetworkManager.shared.getFridge()
            try syncDatabase(fridge: fridge, context: context)
        }
    }
    
    func syncDatabase(fridge: Fridge, context: NSManagedObjectContext) throws {
        let categories = try context.fetch(Category.fetchRequest())
        
        for category in fridge.categories {
            if let localCategory = categories.first(where: {$0.uniqueId == category.id}) {
                // Now sync fridge items
                for item in category.items {
                    if let localItem = localCategory.items.first(where: { $0.uniqueId == item.id }) {
                        // Check all of the details are correct
                        localItem.name = item.name
                        localItem.inFridge = item.inFridge
                        localItem.inShoppingList = item.inShoppingList
                    } else {
                        let new = Item(item: item, context: context)
                        localCategory.addToChildren(new)
                    }
                }
                
                // Now check that all local items were in the remote and haven't been deleted
                for localItem in localCategory.items {
                    if !category.items.contains(where: { $0.id == localItem.uniqueId }) {
                        context.delete(localItem)
                    }
                }
            } else {
                // If category doesn't exist, add it
                let _ = Category(category: category, context: context)
            }
        }
        
        for category in categories {
            if !fridge.categories.contains(where: {$0.id == category.uniqueId}) {
                context.delete(category)
            }
        }
        
        UserDefaults.standard.set(fridge.admin, forKey: "admin")
        
        if let data = try? JSONEncoder().encode(fridge.users) {
            UserDefaults.standard.set(data, forKey: "users")
        }
        
        try context.save()
    }
    
    func executeRecord(_ record: Record) async throws -> Bool {
        switch record {
            case .addItem(let name, let inShoppingList, let inFridge, let id, let category):
                try await NetworkManager.shared.addFridgeItem(name: name, inShoppingList: inShoppingList, inFridge: inFridge, id: id, category: category)
            case .deleteItem(let id, let category):
                try await NetworkManager.shared.deleteFridgeItem(id: id, category: category)
            case .updateItem(let name, let inShoppingList, let inFridge, let id, let category):
                try await NetworkManager.shared.updateItem(name: name, inShoppingList: inShoppingList, inFridge: inFridge, id: id, category: category)
            case .changeItemCategory(let destinationId, let id, let category):
                try await NetworkManager.shared.changeItemCategory(destination: destinationId, id: id, category: category)
            case .createCategory(let name, let id):
                try await NetworkManager.shared.createCategory(id: id, name: name)
            case .deleteCategory(let id):
                try await NetworkManager.shared.deleteCategory(id: id)
            case .leaveGroup(let id):
                try await NetworkManager.shared.leaveFridge(userId: id)
                break
        }
        return true
    }
    
    func attemptExecuteRecord(_ record: Record) {
        Task {
            do {
                let _ = try await executeRecord(record)
            } catch {
                pendingRecords.append(record)
            }
        }
    }
    
    func addItem(_ item: Item) {
        guard inSharedFridge else { return }
        let record = Record.addItem(
            name: item.name,
            inShoppingList: item.inShoppingList,
            inFridge: item.inFridge,
            id: item.uniqueId,
            category: item.category?.uniqueId ?? ""
        )
        attemptExecuteRecord(record)
    }
    
    func deleteItem(id: String, category: String) {
        guard inSharedFridge else { return }
        let record = Record.deleteItem(id: id, category: category)
        attemptExecuteRecord(record)
    }
    
    func updateItem(_ item: Item) {
        guard inSharedFridge else { return }
        let record = Record.updateItem(
            name: item.name,
            inShoppingList: item.inShoppingList,
            inFridge: item.inFridge,
            id: item.uniqueId,
            category: item.category?.uniqueId ?? ""
        )
        attemptExecuteRecord(record)
    }
    
    func changeItemCategory(_ item: Item, previous: String) {
        guard inSharedFridge else { return }
        let record = Record.changeItemCategory(
            destination: item.category?.uniqueId ?? "",
            id: item.uniqueId,
            category: previous
        )
        attemptExecuteRecord(record)
    }
    
    func createCategory(_ category: Category) {
        guard inSharedFridge else { return }
        let record = Record.createCategory(
            name: category.name,
            id: category.uniqueId
        )
        attemptExecuteRecord(record)
    }
    
    func deleteCategory(id: String) {
        guard inSharedFridge else { return }
        let record = Record.deleteCategory(
            id: id
        )
        attemptExecuteRecord(record)
    }
    
    func createFridge(user: String, name: String, categories: [Category]) async throws {
        let id = try await NetworkManager.shared.createFridge(name: name, admin: user)
        try await NetworkManager.shared.joinFridge(userId: user, fridgeId: id)
        UserDefaults.standard.set(id, forKey: "fridgeId")
        UserDefaults.standard.set(user, forKey: "admin")
        let users = try await NetworkManager.shared.getUsers(fridgeId: id)
        let data = try JSONEncoder().encode(users)
        UserDefaults.standard.set(data, forKey: "users")
        
        for category in categories {
            createCategory(category)
            for item in category.items {
                addItem(item)
            }
        }
    }
    
    func joinFridge(user: String, fridgeId: String, context: NSManagedObjectContext) async throws {
        try await NetworkManager.shared.joinFridge(userId: user, fridgeId: fridgeId)
        UserDefaults.standard.set(fridgeId, forKey: "fridgeId")
        try await fetchFridge(context: context)
    }
    
    func deleteFridge() async throws {
        if let data = UserDefaults.standard.data(forKey: "users") {
            let users = try JSONDecoder().decode([User].self, from: data)
            for user in users {
                try await NetworkManager.shared.leaveFridge(userId: user.id)
            }
        }
        
        try await NetworkManager.shared.deleteFridge()
        UserDefaults.standard.setValue(nil, forKey: "fridgeId")
        UserDefaults.standard.setValue(nil, forKey: "admin")
        UserDefaults.standard.setValue(nil, forKey: "users")
    }
    
    func removeUserFromFridge(user: String) async throws {
        try await NetworkManager.shared.leaveFridge(userId: user)
        
        if let data = UserDefaults.standard.data(forKey: "users") {
            var users = try JSONDecoder().decode([User].self, from: data)
            
            users.removeAll(where: { $0.id == user })
            
            let newData = try JSONEncoder().encode(users)
            UserDefaults.standard.set(newData, forKey: "users")
        }
    }
    
    func leaveFridge(user: String) async throws {
        
        try await NetworkManager.shared.leaveFridge(userId: user)
        UserDefaults.standard.setValue(nil, forKey: "fridgeId")
        UserDefaults.standard.setValue(nil, forKey: "admin")
        UserDefaults.standard.setValue(nil, forKey: "users")
    }
}


enum Record: Codable {
    case addItem(name: String, inShoppingList: Bool, inFridge: Bool, id: String, category: String)
    case deleteItem(id: String, category: String)
    case updateItem(name: String, inShoppingList: Bool, inFridge: Bool, id: String, category: String)
    case changeItemCategory(destination: String, id: String, category: String) // Heavier transaction
    case createCategory(name: String, id: String)
    case deleteCategory(id: String)
    case leaveGroup(id: String)
}

