//
//  ShoppingListViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 10/05/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListViewController: UITableViewController {
    
    private var selectedRows = [IndexPath]()
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !selectedRows.contains(indexPath) {
            selectedRows.append(indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if selectedRows.contains(indexPath) {
            selectedRows.removeAll(where: {value in value == indexPath} )
        }
    }
    
    @IBAction func optionsAction(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Add Item", style: .default) { [weak self] (action) in
            self?.addItemPopup()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Restock Fridge", style: .default, handler: { [weak self] (_) in
            self?.restockFridge()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    private func restockFridge() {
        let alert = UIAlertController(title: "Restock Fridge?", message: "The selected favourited items in this list will be restocked in your fridge using their saved shelf lives", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] (_) in
            if let rows = self?.selectedRows {
                for indexPath in rows {
                    let item = self!.fetchedResultsController.object(at: indexPath)
                    
                    if item.shoppingListOnly {
                        item.managedObjectContext!.delete(item)
                    } else {
                        item.runningLow = false
                        item.removed = false
                    }
                    try? item.managedObjectContext!.save()
                }
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func addItemPopup() {
        let alert = UIAlertController(title: "Add Item", message: nil, preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "Enter Name"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert, weak self] (_) in
            let textField = alert?.textFields![0].text
            
            guard let context = self!.container?.viewContext else { return }
            
            let item = FridgeItem(context: context)
            
            item.name = textField!
            item.favourite = false
            item.runningLow = false
            item.shoppingListOnly = true
            item.removed = false
            item.uniqueId = UUID().uuidString
            
            try? context.save()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        loadFromDatabase()
    }
    
    private var container : NSPersistentContainer? = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
    
    // MARK tables
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = fetchedResultsController.fetchedObjects else { return 0 }
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "shoppingListCell", for: indexPath) as? ShoppingListTableViewCell else {
            fatalError("Unexpected Index Path")
        }
        
        configureCell(cell, at: indexPath)
        
        return cell
    }
    
    let persistentContainer = NSPersistentContainer.init(name: "Model")
    
    lazy var fetchedResultsController: NSFetchedResultsController<FridgeItem> = {
        
        let fetchRequest: NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()

        let favouriteAndDeleted = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "favourite == true"), NSPredicate(format: "removed == true")])
        let favouriteAndLow = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "favourite == true"), NSPredicate(format: "runningLow == true")])

        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [favouriteAndDeleted, favouriteAndLow, NSPredicate(format: "shoppingListOnly == true")])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "expiry", ascending: true)]

        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    func loadFromDatabase(){
        persistentContainer.loadPersistentStores { [weak self] (persistentStoreDescription, error) in
            if let error = error {
                print("Unable to Load Persistent Store")
                print("\(error), \(error.localizedDescription)")
            } else {
                do {
                    try self?.fetchedResultsController.performFetch()
                } catch {
                    let fetchError = error as NSError
                    print("Unable to Perform Fetch Request")
                    print("\(fetchError), \(fetchError.localizedDescription)")
                }
                self?.updateView()
            }
        }
    }
    
    private func updateView() {
        if let items = fetchedResultsController.fetchedObjects {
            tableView.isHidden = !(items.count > 0)
        }
    }
    
    private func configureCell(_ cell: ShoppingListTableViewCell, at indexPath: IndexPath) {
        let item = fetchedResultsController.object(at: indexPath)
        cell.itemNameLabel.text = item.name
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration? {
            
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completionHandler) in
            
            let item = self!.fetchedResultsController.object(at: indexPath)
            if item.shoppingListOnly {
                item.managedObjectContext?.delete(item)
            } else {
                let actionSheet = UIAlertController(title: "Delete Item?", message: "This item will be deleted from your fridge too.", preferredStyle: .alert)
                
                let listAction = UIAlertAction(title: "OK", style: .default) { (action) in
                    item.managedObjectContext!.delete(item)
                    try! item.managedObjectContext!.save()
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                actionSheet.addAction(listAction)
                actionSheet.addAction(cancelAction)
                self!.present(actionSheet, animated: true, completion: nil)
            }
            completionHandler(true)
        }
        
        deleteAction.image = UIImage(systemName: "trash")
        deleteAction.backgroundColor = .systemRed
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        return configuration
    }

}

extension ShoppingListViewController : NSFetchedResultsControllerDelegate {
    
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
            default:
                break
        }
    }
}
