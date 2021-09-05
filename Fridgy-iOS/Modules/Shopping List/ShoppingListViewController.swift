//
//  ShoppingListViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        populateItems()
    }
    
    var items: [ShoppingListTableItem] = []
    
    func populateItems() {
        let shoppingListFetch: NSFetchRequest = ShoppingListItem.fetchRequest()
        if let fetchedItems = try? AppDelegate.viewContext.fetch(shoppingListFetch) {
            items = fetchedItems.map { ShoppingListTableItem($0) }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        populateItems()
        tableView.reloadData()
    }
}


// MARK: UITableViewDelegate

extension ShoppingListViewController: UITableViewDelegate {
    
}


// MARK: UITableViewDataSource

extension ShoppingListViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return items.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ShoppingListTableViewCell.identifier, for: indexPath) as? ShoppingListTableViewCell else {
            fatalError("Failed to dequeue ShoppingListTableViewCell")
        }
        cell.setup(name: items[indexPath.row].name)
        return cell
    }
}


struct ShoppingListTableItem {
    var fridgeItem: Item?
    var shoppingItem: ShoppingListItem?
    
    init(_ fridgeItem: Item) {
        self.fridgeItem = fridgeItem
    }
    
    init(_ shoppingItem: ShoppingListItem) {
        self.shoppingItem = shoppingItem
    }
    
    var name: String {
        if let fridgeItem = fridgeItem {
            return fridgeItem.name
        }
        if let shoppingItem = shoppingItem {
            return shoppingItem.name
        }
        fatalError("ShoppingListTableItem has no item set")
    }
}
