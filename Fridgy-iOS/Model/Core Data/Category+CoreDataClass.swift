//
//  Category+CoreDataClass.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 09/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject, Codable {

    enum CodingKeys: String, CodingKey {
        case name = "n"
        case id = "id"
        case children = "c"
    }
    
    required convenience public init(from decoder: Decoder) throws {
        let context = decoder.userInfo[CodingUserInfoKey.managedObjectContext] as! NSManagedObjectContext
        
        self.init(context: context)
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        uniqueId = try container.tryDecode(String.self, forKey: .id)
        name = try container.tryDecode(String.self, forKey: .name)
        let children = try container.tryDecode([Item].self, forKey: .children)
        self.children = Set(children) as NSSet
        index = Int32.max
    }
    
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(uniqueId, forKey: .id)
        try container.encode(items, forKey: .children)
    }
}