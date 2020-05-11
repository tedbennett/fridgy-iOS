//
//  FridgeTableViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 30/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

class FridgeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddItem, EditItem {
    
    @IBOutlet weak var emptyTableLabel: UILabel!
    @IBOutlet weak var addItemOutlet: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func optionsAction(_ sender: UIBarButtonItem) {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let listAction = UIAlertAction(title: "Shopping List", style: .default) { (action) in
            self.performSegue(withIdentifier: "Shopping List Segue", sender: nil)
        }
        
        let selectAction = UIAlertAction(title: "Select Mode", style: .default) { (action) in
            print("didPress block")
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("didPress cancel")
        }
        actionSheet.addAction(listAction)
        actionSheet.addAction(selectAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    let persistentContainer = NSPersistentContainer.init(name: "Model")
    
    lazy var fetchedResultsController: NSFetchedResultsController<FridgeItem> = {
        
        let fetchRequest: NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "expiry", ascending: true)]
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        navigationController!.navigationBar.prefersLargeTitles = true
        addItemOutlet.layer.cornerRadius = 8
        
        loadFromDatabase()
    }
    
    func loadFromDatabase(){
        persistentContainer.loadPersistentStores { (persistentStoreDescription, error) in
            if let error = error {
                print("Unable to Load Persistent Store")
                print("\(error), \(error.localizedDescription)")
            } else {
                do {
                    try self.fetchedResultsController.performFetch()
                } catch {
                    let fetchError = error as NSError
                    print("Unable to Perform Fetch Request")
                    print("\(fetchError), \(fetchError.localizedDescription)")
                }
                self.updateView()
            }
        }
    }
    override func viewDidAppear(_ animated: Bool){
        self.tableView.reloadData()
    }

    private func updateView() {
        var hasItems = false
        if let items = fetchedResultsController.fetchedObjects {
            hasItems = items.count > 0
        }
    
        tableView.isHidden = !hasItems
        emptyTableLabel.isHidden = hasItems
    }

    var container : NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    func addItem(name: String, expiry: Date, favourite: Bool) {
        guard let context = container?.viewContext else { return }
        
        let item = FridgeItem(context: context)
        
        item.name = name
        item.expiry = expiry
        item.favourite = favourite
        item.runningLow = false
        item.shoppingListOnly = false
        item.uniqueId = UUID().uuidString
        
        try? context.save()
    }
    
    func editItem(name: String, expiry: Date, favourite: Bool, uniqueId: String) {
        guard let context = container?.viewContext else { return }
        
        let request : NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()
        
        request.predicate = NSPredicate(format: "uniqueId = %@", uniqueId)
        var item : FridgeItem?
        let matches = try? context.fetch(request)
        assert(matches?.count == 1, "editItem - Database error")
        if matches?.count == 1 {
            item = matches?[0]
        }

        
        if item != nil {
            item!.name = name
            item!.expiry = expiry
            item!.favourite = favourite
            
            item!.uniqueId = UUID().uuidString
            try? item!.managedObjectContext?.save()
        }
    }

    
    // MARK tables
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = fetchedResultsController.fetchedObjects else { return 0 }
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "fridgeItemCell", for: indexPath) as? FridgeItemTableCell else {
            fatalError("Unexpected Index Path")
        }
        
        configureCell(cell, at: indexPath)
        
        return cell
    }
    
    // MARK table helper functions
    private func configureCell(_ cell: FridgeItemTableCell, at indexPath: IndexPath) {
        let item = fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
        cell.itemExpiryLabel.text = getExpiryString(for: item.expiry)
        cell.itemNameLabel.text = item.name
        cell.runningLowView.isHidden = !item.runningLow
        cell.favouriteView.isHidden = !item.favourite
    }
    
    private func getExpiryString(for expiry: Date?) -> String {
        if (expiry != nil) {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let expiryInDays = Calendar.current.dateComponents([.day], from: startOfDay, to: expiry!).day!
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
        } else {
            return "???"
        }
    }

    // MARK swipe actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {

            let deleteAction = UIContextualAction(style: .destructive, title: nil) { (_, _, completionHandler) in

                let item = self.fetchedResultsController.object(at: indexPath)
                item.managedObjectContext?.delete(item)
                try? item.managedObjectContext?.save()
                completionHandler(true)
            }

            deleteAction.image = UIImage(systemName: "trash")
            deleteAction.backgroundColor = .systemRed

            let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
            return configuration
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.fetchedResultsController.object(at: indexPath)

        let runningLowAction = UIContextualAction(style: .normal, title: item.runningLow ? "In Stock" : "Running Low") { (_, _, completionHandler) in
            item.runningLow = !item.runningLow
            try? item.managedObjectContext?.save()
            completionHandler(true)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { (_, _, completionHandler) in
            
            self.performSegue(withIdentifier: "Edit Item Segue", sender: item)
            
            completionHandler(true)
        }
        runningLowAction.backgroundColor = item.runningLow ? .systemGreen : .systemOrange
        editAction.backgroundColor = .systemGray
        let configuration = UISwipeActionsConfiguration(actions: [runningLowAction, editAction])
    
        
        return configuration
    }
    
    // MARK segue stuff
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add Item Segue" {
            if let vc = segue.destination as? AddItemController {
                vc.delegate = self
            }
        } else if segue.identifier == "Edit Item Segue" {
            if let vc = segue.destination as? EditItemController, let item = sender as? FridgeItem {
                
                vc.editDelegate = self
                vc.name = item.name
                if item.expiry != nil {
                    vc.expiry = item.expiry!
                }
                vc.favourite = item.favourite
                vc.uniqueId = item.uniqueId
            }
        } else if segue.identifier == "Shopping List Segue" {
            
        }
    }
}

extension FridgeTableViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        
        updateView()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
            case .insert:
                if let indexPath = newIndexPath {
                    tableView.insertRows(at: [indexPath], with: .fade)
                }
            case .delete:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            case .update:
                if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
                    configureCell(cell as! FridgeItemTableCell, at: indexPath)
                }
                break;
            default:
                print("...")
        }
    }
    

}
    

