//
//  ShoppingListViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 10/05/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class ShoppingListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var shoppingList = [String]()
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        addSampleRows()
        tableView.reloadData()
    }
    
    private func addSampleRows() {
        shoppingList.append("Cheese")
    }
    
    private func setupView() {
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shoppingList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "shoppingListCell", for: indexPath) as? ShoppingListTableViewCell else {
            fatalError("Unexpected Index Path")
        }
        cell.itemNameTextField.text =  shoppingList[indexPath.row]
        
        return cell
    }
}
