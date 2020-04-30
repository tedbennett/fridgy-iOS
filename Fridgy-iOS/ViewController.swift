//
//  ViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 27/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddItem {

    var items : [Item] = [] {
        didSet {
            items.sort()
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        items.append(Item(name: "Cucumber", expiry: Date(timeInterval: -10 * 86400, since: startOfDay)))
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as! ItemCell
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! AddItemController
        vc.delegate = self
    }
    
    func addItem(name: String, expiry: Date) {
        items.append(Item(name: name, expiry: expiry))
        tableView.reloadData()
    }
    
}

class Item : Comparable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.expiry == rhs.expiry
    }
    
    static func < (lhs: Item, rhs: Item) -> Bool {
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
