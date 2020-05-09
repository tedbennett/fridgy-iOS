//
//  FridgeTableViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 30/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class FridgeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddItem {
    
    func addItem(name: String, expiry: Date) {
        let newItem = FridgeItem(name: name, expiry: expiry)
        items.append(newItem)
        //updateDatabase(newItem)
    }
    
    @IBOutlet weak var emptyTableLabel: UILabel!
    @IBOutlet weak var addItemOutlet: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //loadSampleItems()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        navigationController!.navigationBar.prefersLargeTitles = true
        addItemOutlet.layer.cornerRadius = 8
    }

    private var items = [FridgeItem]() {
        didSet {
            items.sort()
            tableView.reloadData()
            tableView.isHidden = (items.count == 0)
            emptyTableLabel.isHidden = !(items.count == 0)
        }
    }
    
    private func loadSampleItems() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let sampleItem = FridgeItem(name: "Cucumber", expiry: Date(timeInterval: -10 * 86400, since: startOfDay))
        items.append(sampleItem)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add Item Segue" {
            if let vc = segue.destination as? AddItemController {
                vc.delegate = self
            }
        }
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in
                // delete the item here
                completionHandler(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            deleteAction.backgroundColor = .systemRed
            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
            if !items[indexPath.row].runningLow {
                let runningLowAction = UIContextualAction(style: .normal, title: "Running Low") { (_, _, completionHandler) in
                    self.items[indexPath.row].runningLow = true
                    if let cell = tableView.cellForRow(at: indexPath) as? FridgeItemTableCell{
                        cell.runningLowView.isHidden = false
                    }
                    completionHandler(true)
                }
                runningLowAction.backgroundColor = .systemOrange
                let configuration = UISwipeActionsConfiguration(actions: [runningLowAction])
                return configuration
            } else {
                let undoAction = UIContextualAction(style: .normal, title: "Undo") { (_, _, completionHandler) in
                    self.items[indexPath.row].runningLow = false
                    if let cell = tableView.cellForRow(at: indexPath) as? FridgeItemTableCell{
                        cell.runningLowView.isHidden = true
                    }
                    completionHandler(true)
                }
                undoAction.backgroundColor = .systemGreen
                let configuration = UISwipeActionsConfiguration(actions: [undoAction])
                return configuration
            }
            
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
            case _ where expiryInDays > 60: return "In \(expiryInDays/30) months"
            case _ where expiryInDays > 14: return "In \(expiryInDays/7) weeks"
            case _ where expiryInDays > 1: return "In \(expiryInDays) days"
            case 1: return "In 1 day"
            case 0: return "In <1 day"
            case -1: return "1 day ago"
            case _ where expiryInDays < -14: return ">14 days ago"
            case _ where expiryInDays < -1: return "\(abs(expiryInDays)) days ago"
            default: return "???"
        }
    }
    
    var runningLow = false
    
    convenience init(name: String, expiry: Date) {
        self.init()
        self.name = name
        self.expiry = expiry
    }
    
}
