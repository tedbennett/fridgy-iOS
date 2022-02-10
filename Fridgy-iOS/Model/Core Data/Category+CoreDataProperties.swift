//
//  Category+CoreDataProperties.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 09/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//
//

import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var name: String
    @NSManaged public var uniqueId: String
    @NSManaged public var index: Int32
    @NSManaged public var children: NSSet?
    
    convenience init(name: String, index: Int, context: NSManagedObjectContext) {
        self.init(context: context)
        self.name = name
        self.index = Int32(index)
        self.uniqueId = UUID().uuidString
    }
    
    var items: [Item] {
        (children?.allObjects as? [Item])?.sorted { $0.index < $1.index } ?? []
    }

}

// MARK: Generated accessors for children
extension Category {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: Item)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: Item)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}

extension Category : Identifiable {

}
