//
//  FridgeViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices

class FridgeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!
    let refreshControl = UIRefreshControl()
    
    var model = FridgeModel()
    
    var categoryBeingEdited: Int?
    var cellBeingEdited: IndexPath?
    
    var rowBeingDragged: IndexPath?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.dragInteractionEnabled = true
        
        tableView.register(
            FridgeTableHeaderView.self,
           forHeaderFooterViewReuseIdentifier: FridgeTableHeaderView.identifier
        )
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        setupRefreshControl()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        if GlobalSettings.updateAppVersion() != GlobalSettings.appVersion {
            if GlobalSettings.appVersion == "3.0.0" {
                performSegue(withIdentifier: "presentWelcomeView", sender: self)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupRefreshControl()
        model.refresh()
        emptyLabel.isHidden = !model.isEmpty()
        tableView.reloadData()
    }
    

    @objc func dismissKeyboard() {
        // Try and find cell being edited to get it's text
        if let index = categoryBeingEdited {
            let indexPath = IndexPath(row: model.categories[index].items.count, section: index)
            if let cell = tableView.cellForRow(at: indexPath) as? FridgeEditorTableViewCell {
                cell.finishEditing()
                view.endEditing(false)
            }
        } else if let indexPath = cellBeingEdited,
              let cell = tableView.cellForRow(at: indexPath) as? FridgeEditorTableViewCell {
            cell.finishEditing()
            view.endEditing(false)
        }
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        emptyLabel.isHidden = true
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = false
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        emptyLabel.isHidden = !model.isEmpty()
        navigationItem.rightBarButtonItem?.isEnabled = true
        navigationItem.leftBarButtonItem?.isEnabled = true
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentEditCategories" {
            guard let nav = segue.destination as? UINavigationController else { return }
            guard let vc = nav.viewControllers.first as? EditCategoriesViewController else { return }
            vc.model = model
            vc.delegate = self
        }
    }
}

// MARK: UITableViewDelegate

extension FridgeViewController: UITableViewDelegate {
    
    // MARK: TableView Header
    
    func tableView(
        _ tableView: UITableView,
        viewForHeaderInSection section: Int
    ) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: FridgeTableHeaderView.identifier
        ) as! FridgeTableHeaderView
        let category = model.getCategory(at: section)
        view.setup(title: category.name, section: section, delegate: self)
        return view
    }
    
    func tableView(
        _ tableView: UITableView,
        heightForHeaderInSection section: Int
    ) -> CGFloat {
        return 40
    }
    
    // MARK: TableView Swipe Actions
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let items = model.getItems(for: indexPath.section)
        guard indexPath.row < items.count else { return nil }
        
        let removeItem = UIContextualAction(
            style: .destructive,
            title: "Delete"
        ) { [weak self] (action, view, completionHandler) in
            self?.model.removeItem(at: indexPath)
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            
            if let empty = self?.model.isEmpty() {
                self?.emptyLabel.isHidden = !empty
            }
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [removeItem])
    }
    
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        // Prevent swipe actions for editing cell
        let items = model.getItems(for: indexPath.section)
        guard indexPath.row < items.count else { return nil }
        
        let item = model.getItem(for: indexPath)
        if item.inShoppingList {
            let action = UIContextualAction(
                style: .normal,
                title: "Remove from Shopping List"
            ) { [weak self] _, _, completionHandler in
                self?.model.removeFromShoppingList(at: indexPath)
                self?.tableView.reloadRows(at: [indexPath], with: .none)
                completionHandler(true)
            }
            action.backgroundColor = .systemGreen
            return UISwipeActionsConfiguration(actions: [action])
        } else {
            let action = UIContextualAction(
                style: .normal,
                title: "Add to Shopping List"
            ) { [weak self] _, _, completionHandler in
                self?.model.addToShoppingList(at: indexPath)
                self?.tableView.reloadRows(at: [indexPath], with: .none)
                completionHandler(true)
            }
            action.backgroundColor = .systemGreen
            return UISwipeActionsConfiguration(actions: [action])
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if categoryBeingEdited == nil && cellBeingEdited == nil {
            cellBeingEdited = indexPath
            tableView.reloadRows(at: [indexPath], with: .none)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
        return nil
    }
}

// MARK: UITableViewDataSource

extension FridgeViewController: UITableViewDataSource {
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        let items = model.getItems(for: section)
        if categoryBeingEdited == section {
            return items.count + 1
        }
        return items.count
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return model.categories.count
    }
    
    
    // MARK: TableView Cell
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let items = model.getItems(for: indexPath.section)
        if categoryBeingEdited == indexPath.section && indexPath.row == items.count {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: FridgeEditorTableViewCell.identifier,
                for: indexPath
            ) as? FridgeEditorTableViewCell else {
                fatalError("Failed to dequeue FridgeEditorTableViewCell")
            }
            cell.setup(text: nil, isShoppingList: false, delegate: self)
            return cell
        }
        
        if cellBeingEdited == indexPath {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: FridgeEditorTableViewCell.identifier,
                for: indexPath
            ) as? FridgeEditorTableViewCell else {
                fatalError("Failed to dequeue FridgeEditorTableViewCell")
            }
            let item = model.getItem(for: indexPath)
            cell.setup(text: item.name, isShoppingList: item.inShoppingList, delegate: self)
            return cell
        }
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FridgeTableViewCell.identifier,
            for: indexPath
        ) as? FridgeTableViewCell  else {
            fatalError("Failed to dequeue FridgeTableViewCell")
        }
        cell.setup(item: model.getItem(for: indexPath))
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? FridgeEditorTableViewCell else { return }
        cell.textField.becomeFirstResponder()
    }
}

// MARK: EditorTableViewCellDelegate

extension FridgeViewController: EditorTableViewCellDelegate {
    
    func didEndEditing(text: String) {
        if text != "" {
            if let categoryBeingEdited = categoryBeingEdited {
                model.addItem(text: text, section: categoryBeingEdited)
            } else if let cellBeingEdited = cellBeingEdited {
                model.updateItem(at: cellBeingEdited, text: text)
            }
        }
        
        categoryBeingEdited = nil
        cellBeingEdited = nil
        emptyLabel.isHidden = !model.isEmpty()
        tableView.reloadData()
    }
}

// MARK: HeaderTableViewCellDelegate

extension FridgeViewController: HeaderTableViewCellDelegate {
    func didStartEditing(at index: Int) {
        if self.categoryBeingEdited == nil {
            cellBeingEdited = nil
            categoryBeingEdited = index
            tableView.reloadData()
            let row = model.getItems(for: index).count
            tableView.scrollToRow(at: IndexPath(row: row, section: index), at: .bottom, animated: true)
        }
    }
}

// MARK: EditCategoriesDelegate

extension FridgeViewController: EditCategoriesDelegate {
    func didFinishEditingCategories() {
        tableView.reloadData()
    }
}

// MARK: UITableViewDragDelegate

extension FridgeViewController: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        rowBeingDragged = indexPath
        guard model.isInBounds(indexPath) else {
            return []
        }
        
        let item = model.getItem(for: indexPath)
        
        let data = item.uniqueId.data(using: .utf8)
            
        let itemProvider = NSItemProvider()
        
        itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypePlainText as String, visibility: .all) { completion in
            completion(data, nil)
            return nil
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        return [
            UIDragItem(itemProvider: itemProvider)
        ]
    }
}

// MARK: UITableViewDropDelegate

extension FridgeViewController: UITableViewDropDelegate {
    
    func tableView(
        _ tableView: UITableView,
        dropSessionDidUpdate session: UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UITableViewDropProposal {
        var dropProposal = UITableViewDropProposal(operation: .cancel)
        
        // Accept only one drag item.
        guard session.items.count == 1 else {
            rowBeingDragged = nil
            return dropProposal
        }
        
        // The .move drag operation is available only for dragging within this app and while in edit mode.
        if tableView.hasActiveDrag {
            dropProposal = UITableViewDropProposal(
                operation: .move,
                intent: .insertAtDestinationIndexPath
            )
        } else {
            rowBeingDragged = nil
        }
        
        return dropProposal
    }
    
    func tableView(
        _ tableView: UITableView,
        canHandle session: UIDropSession
    ) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    func tableView(
        _ tableView: UITableView,
        performDropWith coordinator: UITableViewDropCoordinator
    ) {
        guard let rowBeingDragged = rowBeingDragged else {
            return
        }
        
        let destinationIndexPath: IndexPath
        
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            // Get last index path of table view.
            let section = tableView.numberOfSections - 1
            let row = tableView.numberOfRows(inSection: section)
            destinationIndexPath = IndexPath(row: row, section: section)
        }
        
        self.model.moveItem(from: rowBeingDragged, to: destinationIndexPath)

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        tableView.beginUpdates()
        tableView.deleteRows(at: [rowBeingDragged], with: .fade)
        tableView.insertRows(at: [destinationIndexPath], with: .fade)
        tableView.endUpdates()
    }
}

// MARK: UIRefreshControl

extension FridgeViewController {
    func setupRefreshControl() {
        if FridgeManager.shared.inSharedFridge {
            refreshControl.addTarget(self, action: #selector(onRefreshTriggered), for: .valueChanged)
            tableView.refreshControl = refreshControl
        } else {
            tableView.refreshControl = nil
        }
    }
    
    @objc func onRefreshTriggered() {
        let context = AppDelegate.persistentContainer.newBackgroundContext()
        Task {
            do {
                try await FridgeManager.shared.fetchFridge(context: context)
                await MainActor.run {
                    refreshControl.endRefreshing()
                    model.refresh()
                    emptyLabel.isHidden = !model.isEmpty()
                    tableView.reloadData()
                }
            } catch {
                // Show alert
                print(error)
            }
        }
    }
}
