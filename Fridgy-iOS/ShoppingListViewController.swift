//
//  ShoppingListViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 10/05/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var shoppingList = [String]()
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func addItemAction(_ sender: UIButton) {
        shoppingList.append("")
        tableView.reloadData()
        
        let cell = tableView.cellForRow(at: IndexPath(row: shoppingList.count - 1, section: 0) as IndexPath) as! ShoppingListTableViewCell
        cell.itemNameTextField.isUserInteractionEnabled = true
        cell.itemNameTextField.becomeFirstResponder()
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        navigationController!.navigationBar.prefersLargeTitles = true
        
        loadFromDatabase()
    }
    
    
    private func addSampleRows() {
        shoppingList.append("Cheese")
        shoppingList.append("Milk")
    }
    
    private func setupView() {
        
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "shoppingListCell", for: indexPath) as? ShoppingListTableViewCell else {
            fatalError("Unexpected Index Path")
        }
        
        configureCell(cell, at: indexPath)
        //cell.itemNameTextField.text =  shoppingList[indexPath.row]
        
        return cell
    }
    
    let persistentContainer = NSPersistentContainer.init(name: "Model")
    
    lazy var fetchedResultsController: NSFetchedResultsController<FridgeItem> = {
        
        let fetchRequest: NSFetchRequest<FridgeItem> = FridgeItem.fetchRequest()
        let predicate1 = NSPredicate(format: "shoppingListOnly == true")
        let predicate2 = NSPredicate(format: "favourite == true")
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicate1, predicate2])
        //fetchRequest.predicate = NSPredicate(format: "favourite == true")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "expiry", ascending: true)]

        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
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
    
    private func updateView() {
        var hasItems = false
        if let items = fetchedResultsController.fetchedObjects {
            hasItems = items.count > 0
        }
        
        tableView.isHidden = !hasItems
        //emptyTableLabel.isHidden = hasItems
    }
    
    private func configureCell(_ cell: ShoppingListTableViewCell, at indexPath: IndexPath) {
        let item = fetchedResultsController.object(at: indexPath)
        
        // Configure Cell
        cell.itemNameLabel.isHidden = false
        cell.itemNameLabel.text = item.name
        cell.itemNameTextField.isHidden = true
        cell.itemNameTextField.isUserInteractionEnabled = false
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
//            case .delete:
//                if let indexPath = indexPath {
//                    tableView.deleteRows(at: [indexPath], with: .fade)
//            }
//            case .update:
//                if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) {
//                    configureCell(cell as! FridgeItemTableCell, at: indexPath)
//                }
//                break;
            default:
                print("...")
        }
    }
    
    
}
