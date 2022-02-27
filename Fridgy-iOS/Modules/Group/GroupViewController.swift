//
//  GroupViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 10/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import UIKit
import FirebaseAuth

class GroupViewController: UIViewController {
    
    var groupHost: User!
    var groupMembers: [User] = []
    var name = "Group"
    
    var isAdmin = false
    
    weak var leaveDelegate: GroupLeaveDelegate?
    
    @IBOutlet weak var userTableView: UITableView!
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = name
        navigationItem.hidesBackButton = true
        
        if isAdmin {
            let addUserButton = UIBarButtonItem(image: UIImage(systemName: "person.badge.plus"), style: .plain, target: self, action: #selector(onAddUserPressed))
            let optionsButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(onOptionsPressed))
            optionsButton.tintColor = .systemGreen
            optionsButton.imageInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
            addUserButton.tintColor = .systemGreen
            addUserButton.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -20)

            navigationItem.rightBarButtonItems = [optionsButton, addUserButton]
        } else {
            let leaveButton = UIBarButtonItem(title: "Leave", style: .plain, target: self, action: #selector(onLeavePressed))
            leaveButton.tintColor = .systemRed
            navigationItem.leftBarButtonItem = leaveButton
        }
        
        userTableView.delegate = self
        userTableView.dataSource = self
        setupRefreshControl()
    }
    
    func handleJoinSession(id: String) {
        if id != Utility.fridgeId {
            let alert = UIAlertController(
                title: "Already in Group",
                message: "Leave your current group before joining another",
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(title: "OK", style: .default, handler: nil)
            )
            present(alert, animated: true, completion: nil)
        }
    }
    
    func deleteGroup() {
        let alert = UIAlertController(
            title: "Delete Group?",
            message: "This will remove all members from your group",
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: "Cancel", style: .default, handler: nil)
        )
        alert.addAction(
            UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                Task {
                    try await FridgeManager.shared.deleteFridge()
                    await MainActor.run { [weak self] in
                        _ = self?.navigationController?.popViewController(animated: true)
                    }
                }
            })
        )
        present(alert, animated: true, completion: nil)
    }
    
    func leaveGroup() {
        guard let user = Auth.auth().currentUser?.uid else {
            return
        }
        
        Task {
            try await FridgeManager.shared.leaveFridge(user: user)
            await MainActor.run { [weak self] in
                _ = self?.navigationController?.popViewController(animated: true)
                leaveDelegate?.didLeaveGroup()
            }
        }
    }
    
    func removeUserFromGroup(indexPath: IndexPath) {
        let user = groupMembers[indexPath.row]
        Task {
            try await FridgeManager.shared.removeUserFromFridge(user: user.id)
        }
        groupMembers.remove(at: indexPath.row)
        userTableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    @objc func onLeavePressed() {
        leaveGroup()
    }
    
    @objc func onAddUserPressed() {
        guard let fridgeId = Utility.fridgeId else { return }
        let items: [Any] = ["Join my fridge on Fridgy!", URL(string: "https://www.fridgy-app.com/group/\(fridgeId)")!]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(ac, animated: true)
    }
    
    @objc func onOptionsPressed() {
        let alert = UIAlertController(
            title: "Admin Actions",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.view.tintColor = .systemGreen
        
        alert.addAction(
            UIAlertAction(
                title: "Delete Group",
                style: .destructive,
                handler:{ [weak self] (UIAlertAction) in
                    guard let self = self else { return }
                    self.deleteGroup()
                }
            )
        )
        
        alert.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil
            )
        )
        
        self.present(alert, animated: true, completion: {
        })
    }
}

// MARK: UITableViewDelegate and DataSource

extension GroupViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return groupMembers.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "GroupTableViewCell") as? GroupTableViewCell else {
            fatalError("Failed to dequeue GroupTableViewCell")
        }
        let name = indexPath.section == 0 ? groupHost.name : groupMembers[indexPath.row].name
        cell.setup(name: name)
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "ADMIN"
        } else {
            return "MEMBERS"
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == 1 else { return nil }
        
        return nil //"Pull down to refresh the Fridge view to sync!"
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isAdmin, indexPath.section == 1 else { return nil }
        
        let removeItem = UIContextualAction(
            style: .destructive,
            title: "Remove"
        ) { [weak self] (action, view, completionHandler) in
            self?.removeUserFromGroup(indexPath: indexPath)
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [removeItem])
    }
}

// MARK: UIRefreshControl

extension GroupViewController {
    func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(onRefreshTriggered), for: .valueChanged)
        userTableView.refreshControl = refreshControl
    }
    
    @objc func onRefreshTriggered() {
        guard let fridgeId = Utility.fridgeId else { return }
        Task {
            let exists = try await NetworkManager.shared.checkFridgeExists(id: fridgeId)
            if !exists {
                leaveGroup()
                return
            }
            
            let users = try await NetworkManager.shared.getUsers(fridgeId: fridgeId)
            await MainActor.run {
                let admin = groupHost.id
                groupMembers = users.filter { $0.id != admin }.sorted(by: { $0.name > $1.name })
                Utility.users = users
                userTableView.reloadData()
                refreshControl.endRefreshing()
            }
        }
    }
}

class GroupTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    
    func setup(name: String) {
        nameLabel.text = name
    }
}

