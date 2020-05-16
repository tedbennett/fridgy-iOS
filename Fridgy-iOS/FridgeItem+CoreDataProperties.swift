//
//  FridgeItem+CoreDataProperties.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 15/05/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//
//

import Foundation
import CoreData


extension FridgeItem {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FridgeItem> {
        return NSFetchRequest<FridgeItem>(entityName: "FridgeItem")
    }
    
    @NSManaged public var expiry: Date?
    @NSManaged public var favourite: Bool
    @NSManaged public var name: String?
    @NSManaged public var removed: Bool
    @NSManaged public var runningLow: Bool
    @NSManaged public var shelfLife: Double
    @NSManaged public var shoppingListOnly: Bool
    @NSManaged public var uniqueId: String?
    @objc public var sectionIdentifier: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let expiryInDays = Calendar.current.dateComponents([.day], from: startOfDay, to: expiry!).day!
        switch expiryInDays {
            case _ where expiryInDays > 30:  return 5
            case _ where expiryInDays > 7: return 4
            case _ where expiryInDays > 3: return 3
            case _ where expiryInDays > 0: return 2
            case 0: return 1
            case _ where expiryInDays < 0: return 0
            default: return 0
        }
    }
}
