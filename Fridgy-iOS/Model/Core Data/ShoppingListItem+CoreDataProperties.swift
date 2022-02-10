//
//  ShoppingListItem+CoreDataProperties.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 09/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//
//

import Foundation
import CoreData


extension ShoppingListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingListItem> {
        return NSFetchRequest<ShoppingListItem>(entityName: "ShoppingListItem")
    }

    @NSManaged public var name: String
    @NSManaged public var uniqueId: String
    @NSManaged public var index: Int32
    @NSManaged public var fridgeItem: Item?

    convenience init(
        name: String,
        index: Int? = nil,
        fridgeItem: Item?,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.name = name
        if let index = index {
            self.index = Int32(index)
        } else {
            self.index = Int32.max
        }
        self.uniqueId = UUID().uuidString
        self.fridgeItem = fridgeItem
    }
}

extension ShoppingListItem : Identifiable {

}
