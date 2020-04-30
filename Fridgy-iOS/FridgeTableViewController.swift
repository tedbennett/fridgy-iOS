//
//  FridgeTableViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 30/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class FridgeTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSampleItems()
    }

    private var items = [FridgeItem]() {
        didSet {
            items.sort()
        }
    }
    
    private func loadSampleItems() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let sampleItem = FridgeItem(name: "Cucumber", expiry: Date(timeInterval: -10 * 86400, since: startOfDay))
        items.append(sampleItem)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fridgeItemCell", for: indexPath) as! FridgeItemTableCell
        
        cell.itemNameLabel.text = items[indexPath.row].name
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let expiryInDays = Calendar.current.dateComponents([.day], from: startOfDay, to: items[indexPath.row].expiry).day!
        
        var expiryInDaysString = "?"
        if expiryInDays > 1 {
            expiryInDaysString = "In \(expiryInDays) days"
        } else if expiryInDays == 1 {
            expiryInDaysString = "In \(expiryInDays) day"
        } else if expiryInDays == -1 {
            expiryInDaysString = "\(abs(expiryInDays)) day ago"
        } else if expiryInDays < -1 {
            expiryInDaysString = "\(abs(expiryInDays)) days ago"
        } else {
            expiryInDaysString = "In <1 day"
        }
        
        
        cell.itemExpiryLabel.text = expiryInDaysString

        return cell
    }


}

class FridgeItem : Comparable {
    static func == (lhs: FridgeItem, rhs: FridgeItem) -> Bool {
        lhs.expiry == rhs.expiry
    }
    
    static func < (lhs: FridgeItem, rhs: FridgeItem) -> Bool {
        return lhs.expiry < rhs.expiry
    }
    
    var name = ""
    
    var expiry = Date()
    
    convenience init(name: String, expiry: Date) {
        self.init()
        self.name = name
        self.expiry = expiry
    }
    
}
