//
//  NetworkManager.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 05/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

class NetworkManager {
    static var shared = NetworkManager()
    
    private init() {}
    
    private var db = Firestore.firestore()
    
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
        
        return Fridge(categories: categories)
    }
    
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
    
    func joinFridge(userId: String, fridgeId: String) async throws {
        guard let fridge = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        
    }
    
    func leaveFridge() async throws {
        guard let fridge = UserDefaults.standard.string(forKey: "fridgeId") else { throw ApiError.noFridgeId }
        
        
    }
    
    private func decode<T: Decodable>(_ json: [String:Any]) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: json)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let decoded = try decoder.decode(T.self, from: data)
        return decoded
    }
}



struct Fridge: Codable {
//    var id: String
//    var users: [User]
    var categories: [FridgeCategory]
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
    var isAdmin: Bool
}

enum ApiError: Error {
    case noFridgeId
    case failedToDecodeData
}
