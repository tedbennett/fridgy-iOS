//
//  Item+CoreDataClass.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject, Codable {
    
    enum CodingKeys: String, CodingKey {
        case name = "n"
        case id = "id"
        case shoppingListItem = "sl"
    }
    
    required convenience public init(from decoder: Decoder) throws {
        let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as! NSManagedObjectContext
        
        self.init(context: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uniqueId = try container.tryDecode(String.self, forKey: .id)
        name = try container.tryDecode(String.self, forKey: .name)
        shoppingListItem = try container.tryDecode(ShoppingListItem?.self, forKey: .shoppingListItem)
        index = Int32.max
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(uniqueId, forKey: .id)
        try container.encode(shoppingListItem, forKey: .shoppingListItem)
    }
}

extension KeyedDecodingContainer {
    func tryDecode<T: Decodable>(_ type: T.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> T {
        do {
            return try decode(type, forKey: key)
        } catch {
            print("Failed to decode key \(key)")
            throw error
        }
    }
}


extension JSONDecoder {
    static func coreDataDecoder(context: NSManagedObjectContext) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.userInfo[.managedObjectContext] = context
        return decoder
    }
}

extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}
