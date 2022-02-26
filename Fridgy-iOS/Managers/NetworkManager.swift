//
//  NetworkManager.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 05/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class NetworkManager {
    static var shared = NetworkManager()
    
    private init() {}
    
    private var db = Firestore.firestore()
    
    // ========================================================================
    // MARK: Fridge
    // ========================================================================
    
    func getFridge() async throws -> Fridge {
        guard let id = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        let categoryCollection = try await db.collection("fridges/\(id)/categories").getDocuments()
        
        var categories: [FridgeCategory] = []
        
        for category in categoryCollection.documents {
            let itemCollection = try await db.collection("fridges/\(id)/categories/\(category.documentID)/items").getDocuments()
            guard let name = category.data()["name"] as? String else { continue }
            let items: [FridgeItem] = itemCollection.documents.compactMap { try? $0.data(as: FridgeItem.self) }
            categories.append(FridgeCategory(items: items, id: category.documentID, name: name))
        }
        
        let users = try await getUsers(fridgeId: id)
        
        let details = try await db.collection("fridges").document(id).getDocument()
        
        guard let admin = details.data()?["admin"] as? String else { throw ApiError.failedToDecodeData }
        
        return Fridge(users: users, categories: categories, admin: admin)
    }
    
    func createFridge(name: String, admin: String) async throws -> String {
        let id = UUID().uuidString
        try await db.collection("fridges").document(id).setData([
            "name": name,
            "admin": admin,
            "id": id
        ])
        return id
    }
    
    func checkFridgeExists(id: String) async throws -> Bool {
        let doc = try await db.collection("fridges").document(id).getDocument()
        
        return doc.exists
    }
    
    // ========================================================================
    // MARK: Items
    // ========================================================================
    
    func addFridgeItem(name: String, inShoppingList: Bool, inFridge: Bool, id: String, category: String) async throws {
        guard let fridge = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        try await db.collection("fridges/\(fridge)/categories/\(category)/items").document(id).setData([
            "name": name,
            "inFridge": inFridge,
            "inShoppingList": inShoppingList,
            "id": id
        ])
    }
    
    func deleteFridgeItem(id: String, category: String) async throws {
        guard let fridge = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        try await db.collection("fridges/\(fridge)/categories/\(category)/items").document(id).delete()
    }
    
    func updateItem(name: String, inShoppingList: Bool, inFridge: Bool, id: String, category: String) async throws {
        guard let fridge = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        try await db.collection("fridges/\(fridge)/categories/\(category)/items").document(id).setData([
            "name": name,
            "inShoppingList": inShoppingList,
            "inFridge": inFridge,
            "id": id
        ])
    }
    
    func changeItemCategory(destination: String, id: String, category: String) async throws {
        guard let fridge = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        let doc = try await db.collection("fridges/\(fridge)/categories/\(category)/items").document(id).getDocument()
        
        try await db.collection("fridges/\(fridge)/categories/\(destination)/items").document(id).setData(doc.data()!)
        
        try await db.collection("fridges/\(fridge)/categories/\(category)/items").document(id).delete()
    }
    
    // ========================================================================
    // MARK: Categories
    // ========================================================================
    
    func createCategory(id: String, name: String) async throws {
        guard let fridge = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        try await db.collection("fridges/\(fridge)/categories").document(id).setData([
            "name": name,
            "id": id
        ])
    }
    
    func deleteCategory(id: String) async throws {
        guard let fridge = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        try await db.collection("fridges/\(fridge)/categories").document(id).delete()
    }
    
    // ========================================================================
    // MARK: Users
    // ========================================================================
    
    func createUser(name: String?, email: String?, id: String) async throws {
        try await db.collection("users").document(id).setData([
            "name": name ?? NSNull(),
            "email": email ?? NSNull(),
            "id": id,
            "provider": "apple"
        ])
    }
    
    func getUser(id: String) async throws -> User {
        let doc = try await db.collection("users").document(id).getDocument()
        guard let user = try doc.data(as: User.self) else { throw ApiError.failedToDecodeData }
        return user
    }
    
    func getUsers(fridgeId: String) async throws -> [User] {
        let userCollection = try await db.collection("users").whereField("fridgeId", isEqualTo: fridgeId).getDocuments()
        
        let users = userCollection.documents.compactMap { try? $0.data(as: User.self) }
        
        return users
    }
    
    func deleteUser(id: String) async throws {
        try await db.collection("users").document(id).delete()
    }
    
    func checkUserExists(id: String) async throws -> Bool {
        let doc = try await db.collection("users").document(id).getDocument()
        return doc.data() != nil
    }
    
    // ========================================================================
    // MARK: Membership
    // ========================================================================
    
    func checkInFridge(userId: String, fridgeId: String) async throws -> Bool {
        let doc = try await db.collection("fridges").document(fridgeId).getDocument()
        return doc.data() != nil
    }
    
    func joinFridge(userId: String, fridgeId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fridgeId": fridgeId
        ])
    }
    
    func leaveFridge(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fridgeId": NSNull()
        ])
    }
    
    func deleteFridge() async throws {
        guard let id = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        try await db.collection("fridges").document(id).delete()
    }
}



struct Fridge: Codable {
//    var id: String
    var users: [User]
    var categories: [FridgeCategory]
    var admin: String
}

struct FridgeCategory: Codable {
    var items: [FridgeItem]
    var id: String
    var name: String
}

struct FridgeItem: Codable {
    var inShoppingList: Bool
    var inFridge: Bool
    var name: String
    var id: String
    
}

struct User: Codable {
    var name: String
    var id: String
}

enum ApiError: Error {
    case noFridgeId
    case failedToDecodeData
}
