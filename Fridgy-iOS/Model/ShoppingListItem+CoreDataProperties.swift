//
//  ShoppingListItem+CoreDataProperties.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 05/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//
//

import Foundation
import CoreData


extension ShoppingListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingListItem> {
        return NSFetchRequest<ShoppingListItem>(entityName: "ShoppingListItem")
    }

    @NSManaged public var name: String
    
    @NSManaged public var fridgeItem: Item?
}

extension ShoppingListItem : Identifiable {

}
