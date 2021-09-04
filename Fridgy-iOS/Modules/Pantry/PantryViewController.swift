//
//  PantryViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

class PantryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    var data: [String] = ["One", "Two", "Three", "Four"]
}


// MARK: UITableViewDelegate

extension PantryViewController: UITableViewDelegate {
    
}


// MARK: UITableViewDataSource

extension PantryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FridgeTableViewCell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
}
