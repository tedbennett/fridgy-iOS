//
//  Item+CoreDataProperties.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var uniqueId: String
    @NSManaged public var name: String
    @NSManaged public var index: Int32
    @NSManaged public var category: Category?
    @NSManaged public var inShoppingList: Bool
    @NSManaged public var inFridge: Bool
    
    
    convenience init(name: String, index: Int? = nil, inShoppingList: Bool, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = name
        if let index = index {
            self.index = Int32(index)
        } else {
            self.index = Int32.max
        }
        uniqueId = UUID().uuidString
        inFridge = !inShoppingList
        self.inShoppingList = inShoppingList
        
        
        let categoryFetch = Category.fetchRequest()
        categoryFetch.predicate = NSPredicate(format: "name == %@", "Other")
        category = (try? context.fetch(categoryFetch))?.first
    }
    
    convenience init(item: FridgeItem, context: NSManagedObjectContext) {
        self.init(context: context)
        name = item.name
        index = Int32.max
        uniqueId = item.id
        inFridge = item.inFridge
        inShoppingList = item.inShoppingList
    }
}

extension Item : Identifiable {

}
