//
//  FridgeTableViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 30/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class FridgeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSampleItems()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        navigationController!.navigationBar.prefersLargeTitles = true
    }

    private var items = [FridgeItem]() {
        didSet {
            items.sort()
            tableView.reloadData()
        }
    }
    
    private func loadSampleItems() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let sampleItem = FridgeItem(name: "Cucumber", expiry: Date(timeInterval: -10 * 86400, since: startOfDay))
        items.append(sampleItem)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fridgeItemCell", for: indexPath) as! FridgeItemTableCell
        
        cell.itemNameLabel.text = items[indexPath.row].name
        cell.itemExpiryLabel.text = items[indexPath.row].expiryString
        
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
    
    private var expiry = Date()
    
    var expiryString : String {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let expiryInDays = Calendar.current.dateComponents([.day], from: startOfDay, to: expiry).day!
        switch expiryInDays {
            case _ where expiryInDays > 1: return "In \(expiryInDays) days"
            case 1: return "In 1 day"
            case 0: return "In <1 day"
            case -1: return "1 day ago"
            case _ where expiryInDays < -1: return "In \(abs(expiryInDays)) days"
            default: return "???"
        }
    }
    
    convenience init(name: String, expiry: Date) {
        self.init()
        self.name = name
        self.expiry = expiry
    }
    
}
