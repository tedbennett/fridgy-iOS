//
//  FridgeTableViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 30/04/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

class FridgeTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, AddItem, EditItem, RemoveItem, FavouriteItem {
    
    
    @IBOutlet weak var emptyTableLabel: UILabel!
    @IBOutlet weak var addItemOutlet: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var optionsOutlet: UIBarButtonItem!
    
    @IBAction func optionsAction(_ sender: UIBarButtonItem) {
        if !selectedRows.isEmpty {
            print(selectedRows)
            var allRunningLow = true
            
            var allFavourited = false
            
            for indexPath in self.selectedRows {
                let item = self.fetchedResultsController.object(at: indexPath)
                allRunningLow = allRunningLow && item.runningLow
                allFavourited = allFavourited && item.favourite
            }
            
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let helpAction = UIAlertAction(title: "Help", style: .default) { (action) in
                self.performSegue(withIdentifier: "Welcome Segue", sender: nil)
            }
            
            let listAction = UIAlertAction(title: "Shopping List", style: .default) { (action) in
                self.performSegue(withIdentifier: "Shopping List Segue", sender: nil)
            }
            let searchAction = UIAlertAction(title: "Search for Recipes...", style: .default) { (action) in
                var selectedItems = [String]()
                for indexPath in self.selectedRows {
                    let item = self.fetchedResultsController.object(at: indexPath)
                    if item.name != nil {
                        selectedItems.append(item.name!)
                    }
                }
                self.deselectAllItems(animated: true)
                let searchQuery = selectedItems.joined(separator:"+")
                if let url = URL(string: "http://www.google.com/search?q=\(searchQuery)+recipes") {
                    UIApplication.shared.open(url)
                }
                
            }
            let runningLowAction = UIAlertAction(title: allRunningLow ? "Mark In Stock" : "Mark Running Low", style: .default) { (action) in
                for indexPath in self.selectedRows {
                    let item = self.fetchedResultsController.object(at: indexPath)
                    self.editItem(name: nil, expiry: nil, favourite: nil, runningLow: allRunningLow ? false : true, shoppingListOnly: nil, removed: nil, uniqueId: item.uniqueId!)
                }
                self.deselectAllItems(animated: true)
            }
            let markEmptyAction = UIAlertAction(title: "Mark Favourites Out of Stock", style: .default) { (action) in
                var itemsToBeMarked = [FridgeItem]()
                for indexPath in self.selectedRows {
                    itemsToBeMarked.append(self.fetchedResultsController.object(at: indexPath))
                }
                for item in itemsToBeMarked {
                    if item.favourite {
                        self.editItem(name: nil, expiry: nil, favourite: nil, runningLow: nil, shoppingListOnly: nil, removed: true, uniqueId: item.uniqueId!)
                    }
                }
                self.deselectAllItems(animated: true)
            }
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
                var itemsToBeDeleted = [FridgeItem]()
                for indexPath in self.selectedRows {
                    itemsToBeDeleted.append(self.fetchedResultsController.object(at: indexPath))
                }
                for item in itemsToBeDeleted {
                    self.removeItem(uniqueId: item.uniqueId!)
                }
                self.deselectAllItems(animated: true)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheet.addAction(helpAction)
            actionSheet.addAction(searchAction)
            actionSheet.addAction(listAction)
            actionSheet.addAction(runningLowAction)
            actionSheet.addAction(markEmptyAction)
            actionSheet.addAction(deleteAction)
            actionSheet.addAction(cancelAction)
            self.present(actionSheet, animated: true, completion: nil)
        } else {
            self.performSegue(withIdentifier: "Shopping List Segue", sender: nil)
        }
    }
    
    private var selectedRows = [IndexPath]()
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedRows.isEmpty {
            optionsOutlet.image = UIImage(systemName: "ellipsis")
            optionsOutlet.title = nil
        }
        if !selectedRows.contains(indexPath) {
            selectedRows.append(indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        selectedRows.removeAll(where: {value in value == indexPath} )
        if selectedRows.isEmpty {
            optionsOutlet.image = nil
            optionsOutlet.title = "Shopping List"
        }
    }
    
    let persistentContainer = NSPersistentContainer.init(name: "Model")
    
    lazy var fetchedResultsController: NSFetchedResultsController<FridgeItem> = {
        
        let fetchRequest: NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()
        
        let predicateIsNotEmpty = NSPredicate(format: "removed == false")
        let predicateNotShoppingList = NSPredicate(format: "shoppingListOnly == false")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateIsNotEmpty, predicateNotShoppingList])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "expiry", ascending: true)]
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "sectionIdentifier", cacheName: nil)
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
        
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "openedAppBefore") {
            performSegue(withIdentifier: "Welcome Segue", sender: nil)
            defaults.set(true, forKey: "openedAppBefore")
        }
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
    
    func addItem(name: String, expiry: Date?, favourite: Bool?, runningLow: Bool?, shoppingListOnly: Bool?, removed: Bool?, uniqueId: String) {
        let item = FridgeItem(context: fetchedResultsController.managedObjectContext)
        
        item.name = name
        if let expiry = expiry {
            item.expiry = expiry
            item.shelfLife = expiry.timeIntervalSince(Date())
        }
        item.favourite = favourite ?? false
        item.runningLow =  runningLow ?? false
        item.shoppingListOnly = shoppingListOnly ?? false
        item.removed = removed ?? false
        
        item.uniqueId = uniqueId
        
        try! fetchedResultsController.managedObjectContext.save()
    }
    
    func editItem(name: String?, expiry: Date?, favourite: Bool?, runningLow: Bool?, shoppingListOnly: Bool?, removed: Bool?, uniqueId: String) {
        let request : NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()
        
        request.predicate = NSPredicate(format: "uniqueId = %@", uniqueId)
        var item : FridgeItem?
        let matches = try? fetchedResultsController.managedObjectContext.fetch(request)
        assert(matches?.count == 1, "editItem - Database error")
        if matches?.count == 1 {
            item = matches?[0]
        }
        if item != nil {
            if let name = name {
                item!.name = name
            }
            if let expiry = expiry {
                item!.expiry = expiry
            }
            if let favourite = favourite {
                item!.favourite = favourite
            }
            if let runningLow = runningLow {
                item!.runningLow = runningLow
            }
            if let shoppingListOnly = shoppingListOnly {
                item!.shoppingListOnly = shoppingListOnly
            }
            if let removed = removed {
                item!.removed = removed
            }
            try? fetchedResultsController.managedObjectContext.save()
        }
    }
    
    func removeItem(uniqueId: String) {
        let request : NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()
        
        request.predicate = NSPredicate(format: "uniqueId = %@", uniqueId)
        var item : FridgeItem?
        let matches = try? fetchedResultsController.managedObjectContext.fetch(request)
        assert(matches?.count == 1, "removeItem - Database error")
        if matches?.count == 1 {
            item = matches?[0]
        }
        if item != nil {
            fetchedResultsController.managedObjectContext.delete(item!)
            try? fetchedResultsController.managedObjectContext.save()
        }
    }
    
    func favouriteItem(uniqueId: String) {
        guard let context = container?.viewContext else { return }
        
        let request : NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()
        request.predicate = NSPredicate(format: "uniqueId = %@", uniqueId)
        
        var item : FridgeItem?
        let matches = try? context.fetch(request)
        assert(matches?.count == 1, "favourite - Database error")
        if matches?.count == 1 {
            item = matches?[0]
        }
        if item != nil {
            item!.favourite = !item!.favourite
            try? item!.managedObjectContext?.save()
        }
    }
    
    // MARK tables
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "fridgeItemCell", for: indexPath) as? FridgeItemTableCell else {
            fatalError("Unexpected Index Path")
        }
        configureCell(cell, at: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let sectionInfo = fetchedResultsController.sections![section]
        switch sectionInfo.indexTitle {
            case "0": return "Expired"
            case "1": return "Expires today"
            case "2": return "Expires within 3 days"
            case "3": return "Expires this week"
            case "4": return "Expires this month"
            case "5": return "Expires in more than a month"
            default: return "?"
        }
    }
    
    // MARK table helper functions
    private func configureCell(_ cell: FridgeItemTableCell, at indexPath: IndexPath) {
        let item = fetchedResultsController.object(at: indexPath)
        
        
        cell.itemNameLabel.text = item.name
        cell.runningLowView.isHidden = !item.runningLow
        cell.favouriteButton.setImage(UIImage.init(systemName: item.favourite ? "star.fill" : "star") , for: UIControl.State.normal)
        cell.uniqueId = item.uniqueId
        cell.delegate = self
        
    }
    
    // Commenting out since I may use this for detail expiry date
    //    private func getExpiryString(for expiry: Date?) -> String {
    //        if (expiry != nil) {
    //            let startOfDay = Calendar.current.startOfDay(for: Date())
    //            let expiryInDays = Calendar.current.dateComponents([.day], from: startOfDay, to: expiry!).day!
    //            switch expiryInDays {
    //                case _ where expiryInDays > 60: return "In \(expiryInDays/30) months"
    //                case _ where expiryInDays > 14: return "In \(expiryInDays/7) weeks"
    //                case _ where expiryInDays > 1: return "In \(expiryInDays) days"
    //                case 1: return "In 1 day"
    //                case 0: return "In <1 day"
    //                case -1: return "1 day ago"
    //                case _ where expiryInDays < -14: return ">14 days ago"
    //                case _ where expiryInDays < -1: return "\(abs(expiryInDays)) days ago"
    //                default: return "???"
    //            }
    //        } else {
    //            return "???"
    //        }
    //    }
    
    // MARK swipe actions
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let item = self.fetchedResultsController.object(at: indexPath)
        
        let deleteAction = UIContextualAction(style: .destructive, title: item.favourite ? "Out of stock" : "Delete") { (_, _, completionHandler) in
            
            if item.favourite {
                item.removed = true
                try? item.managedObjectContext?.save()
            } else {
                let actionSheet = UIAlertController(title: "Delete Item?", message: "This action cannot be reversed. \n Only your favourites are saved in your shopping list", preferredStyle: .alert)
                
                let listAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    item.managedObjectContext?.delete(item)
                    try? item.managedObjectContext?.save()
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                actionSheet.addAction(listAction)
                actionSheet.addAction(cancelAction)
                self.present(actionSheet, animated: true, completion: nil)
            }
            
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .systemRed
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { (_, _, completionHandler) in
            
            self.performSegue(withIdentifier: "Edit Item Segue", sender: item)
            completionHandler(true)
        }
        editAction.backgroundColor = .systemGray
        
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = self.fetchedResultsController.object(at: indexPath)
        
        let runningLowAction = UIContextualAction(style: .normal, title: item.runningLow ? "In Stock" : "Running Low") { (_, _, completionHandler) in
            item.runningLow = !item.runningLow
            try? item.managedObjectContext?.save()
            completionHandler(true)
        }
        
        
        runningLowAction.backgroundColor = item.runningLow ? .systemGreen : .systemOrange
        
        let configuration = UISwipeActionsConfiguration(actions: [runningLowAction])
        
        return configuration
    }
    
    // MARK: segue stuff
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add Item Segue" {
            if let vc = segue.destination as? AddItemController {
                vc.delegate = self
            }
        } else if segue.identifier == "Edit Item Segue" {
            if let vc = segue.destination as? EditItemController, let item = sender as? FridgeItem {
                
                vc.editDelegate = self
                vc.name = item.name
                if let itemExpiry = item.expiry {
                    vc.expiry = itemExpiry
                }
                vc.favourite = item.favourite
                vc.uniqueId = item.uniqueId
            }
        } else if segue.identifier == "Shopping List Segue" {
            if let vc = segue.destination as? ShoppingListViewController {
                
                vc.delegate = self
                
                if let context = container?.viewContext {
                    
                    let request : NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()
                    
                    let favouriteAndDeleted = NSCompoundPredicate(andPredicateWithSubpredicates: [
                        NSPredicate(format: "favourite == true"), NSPredicate(format: "removed == true")])
                    let favouriteAndLow = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "favourite == true"), NSPredicate(format: "runningLow == true")])
                    
                    request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [favouriteAndDeleted, favouriteAndLow, NSPredicate(format: "shoppingListOnly == true")])
                    
                    if let matches = try? context.fetch(request) {
                        for match in matches {
                            vc.items.append(ShoppingListItem(name: match.name ?? "", shoppingListOnly: match.shoppingListOnly, uniqueId: match.uniqueId ?? ""))
                        }
                    }
                }
            }
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
                break
            default:
                break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        
        let section = IndexSet(integer: sectionIndex)
        
        switch type {
            case .delete:
                tableView.deleteSections(section, with: .automatic)
            case .insert:
                tableView.insertSections(section, with: .automatic)
            default:
                break
        }
    }
}

extension FridgeTableViewController {
    func deselectAllItems(animated: Bool) {
        for indexPath in selectedRows { tableView.deselectRow(at: indexPath, animated: animated) }
        selectedRows  = [IndexPath]()
        optionsOutlet.image = nil
        optionsOutlet.title = "Shopping List"
    }
}


