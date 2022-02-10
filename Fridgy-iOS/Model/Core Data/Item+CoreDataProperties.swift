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
    @NSManaged public var shoppingListItem: ShoppingListItem?
    
    convenience init(name: String, index: Int? = nil, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = name
        if let index = index {
            self.index = Int32(index)
        } else {
            self.index = Int32.max
        }
        self.uniqueId = UUID().uuidString
        self.shoppingListItem = nil
    }
    
    
    var inShoppingList: Bool {
        shoppingListItem != nil
    }
}

extension Item : Identifiable {

}
