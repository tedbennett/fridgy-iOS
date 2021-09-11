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

    @NSManaged public var index: Int16
    @NSManaged public var uniqueId: String
    @NSManaged public var name: String
    @NSManaged public var category: String
    
    @NSManaged public var shoppingListItem: ShoppingListItem?

    var inShoppingList: Bool {
        shoppingListItem != nil
    }
    
}

extension Item : Identifiable {

}
