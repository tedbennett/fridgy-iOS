//
//  FridgeViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

class FridgeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var items: [FridgeItem] = []
    var expiringItems: [FridgeItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isEditing = true
        
        loadFromStore()
    }
    
    func loadFromStore() {
        let fetchRequest: NSFetchRequest = FridgeItem.fetchRequest()
        if let items = try? AppDelegate.viewContext.fetch(fetchRequest) {
            self.items = items.filter { !$0.expiresSoon }.sorted { $0.index < $1.index }
            self.expiringItems = items.filter { $0.expiresSoon }.sorted { $0.index < $1.index }
        }
    }
    
    private func updateIndices() {
        items.enumerated().forEach { index, item in
            item.index = Int16(index)
            item.expiresSoon = false
        }
        expiringItems.enumerated().forEach { index, item in
            item.index = Int16(index)
            item.expiresSoon = true
        }
        
        do {
            try AppDelegate.viewContext.save()
        } catch {
            fatalError("Failed to save view context when updating indices")
        }
        
    }
}


// MARK: UITableViewDelegate

extension FridgeViewController: UITableViewDelegate {
    
}


// MARK: UITableViewDataSource

extension FridgeViewController: UITableViewDataSource {
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        if section == 0 {
            return expiringItems.count
        } else {
            return items.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Expiring Soon"
        } else {
            return "Expiring Later"
        }
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeTableViewCell", for: indexPath)
        cell.textLabel?.text = indexPath.section == 0 ? expiringItems[indexPath.row].name : items[indexPath.row].name
        return cell
    }
    
    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(
        _ tableView: UITableView,
        shouldIndentWhileEditingRowAt indexPath: IndexPath
    ) -> Bool {
        return false
    }
    
    func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        var movedObject: FridgeItem
        if sourceIndexPath.section == 0 {
            movedObject = expiringItems[sourceIndexPath.row]
            expiringItems.remove(at: sourceIndexPath.row)
        } else {
            movedObject = items[sourceIndexPath.row]
            items.remove(at: sourceIndexPath.row)
        }
        
        if destinationIndexPath.section == 0 {
            expiringItems.insert(movedObject, at: destinationIndexPath.row)
        } else {
            items.insert(movedObject, at: destinationIndexPath.row)
        }
        
        updateIndices()
    }
}
