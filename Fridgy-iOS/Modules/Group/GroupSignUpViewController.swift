//
//  GroupSignUpViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 23/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import UIKit
import AuthenticationServices
import StoreKit
import SPConfetti

protocol GroupLeaveDelegate: AnyObject {
    func didLeaveGroup()
}

class GroupSignUpViewController: UIViewController {
    
    enum State {
        case notLoggedIn
        case loggedIn(product: SKProduct)
        case loggedInNoProduct
        case plus
    }
    
    var state: State = .notLoggedIn {
        didSet {
            updateView()
        }
    }
    @IBOutlet weak var notLoggedInView: UIView!
    @IBOutlet weak var loggedInView: UIView!
    @IBOutlet weak var plusView: UIView!
    
    @IBOutlet weak var authorizationButtonParent: UIView!
    @IBOutlet weak var createFridgeButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var currentNonce: String?
    
    private var product: SKProduct?
    
    var authorizationButton: ASAuthorizationAppleIDButton = {
        var button: ASAuthorizationAppleIDButton
        if #available(iOS 13.2, *) {
            button = ASAuthorizationAppleIDButton(type: .signUp, style: .black)
        } else {
            button = ASAuthorizationAppleIDButton(authorizationButtonType: .default, authorizationButtonStyle: .black)
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.cornerRadius = 10
        button.addTarget(self, action: #selector(handleLogInWithAppleID), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        upgradeButton.titleLabel?.textAlignment = .center
        authorizationButtonParent.addSubview(authorizationButton)
        NSLayoutConstraint.activate([
            authorizationButton.leadingAnchor.constraint(equalTo: authorizationButtonParent.leadingAnchor, constant: 1),
            authorizationButton.trailingAnchor.constraint(equalTo: authorizationButtonParent.trailingAnchor, constant: -1),
            authorizationButton.topAnchor.constraint(equalTo: authorizationButtonParent.topAnchor, constant: 1),
            authorizationButton.bottomAnchor.constraint(equalTo: authorizationButtonParent.bottomAnchor, constant: -1)
        ])
        Utility.plusId = nil
        if UserManager.shared.isLoggedIn {
            if let plusId = Utility.plusId,
               plusId == UserManager.shared.userId {
                state = .plus
            } else {
                state = .loggedInNoProduct
            }
        } else {
            state = .notLoggedIn
        }
        
        StoreObserver.shared.delegate = self
        StoreObserver.shared.fetchProducts()
        showLoadingView()
        if Utility.fridgeId != nil {
            presentGroupView()
        }
        
        SPConfettiConfiguration.particlesConfig.colors = [#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1), #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1), #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)]
    }
    
    func updateView() {
        switch state {
            case .notLoggedIn:
                plusView.isHidden = true
                loggedInView.isHidden = true
                notLoggedInView.isHidden = false
            case .loggedIn(let product):
                plusView.isHidden = true
                loggedInView.isHidden = false
                notLoggedInView.isHidden = true
                upgradeButton.isHidden = false
                if let price = product.regularPrice {
                    upgradeButton.setTitle("Upgrade to Fridgy Plus\n\(price)", for: .normal)
                } else {
                    upgradeButton.setTitle("Upgrade to Fridgy Plus", for: .normal)
                }
                infoLabel.text = "Upgrade to Fridgy Plus to create a shared fridge!"
                
            case .loggedInNoProduct:
                plusView.isHidden = true
                loggedInView.isHidden = false
                notLoggedInView.isHidden = true
                upgradeButton.isHidden = true
                infoLabel.text = "Unable to contact storefront for Fridgy Plus"
                
            case .plus:
                plusView.isHidden = false
                loggedInView.isHidden = true
                notLoggedInView.isHidden = true
        }
        
        if UserManager.shared.isLoggedIn {
            let optionsButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(onOptionsPressed))
            optionsButton.tintColor = .systemGreen
            navigationItem.rightBarButtonItem = optionsButton
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func onOptionsPressed() {
        let alert = UIAlertController(
            title: "Options",
            message: nil,
            preferredStyle: .actionSheet
        )
        
        alert.view.tintColor = .systemGreen
        
        alert.addAction(
            UIAlertAction(
                title: "Logout",
                style: .default,
                handler:{ [weak self] (UIAlertAction) in
                    guard let self = self else { return }
                    self.logout()
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
        
        present(alert, animated: true)
    }
    
    func logout() {
        do {
            try UserManager.shared.logout()
        } catch {
            print("Failed to sign out")
        }
        state = .notLoggedIn
    }
    
    func handleJoinSession(id: String) {
        if let user = UserManager.shared.user  {
            let context = AppDelegate.persistentContainer.newBackgroundContext()
            // User signed in and not in session, join session
            showLoadingView()
            Task {
                let fridgeExists = try await NetworkManager.shared.checkFridgeExists(id: id)
                
                if fridgeExists {
                    // Join
                    try await FridgeManager.shared.joinFridge(user: user.uid, fridgeId: id, context: context)
                    await MainActor.run {
                        presentGroupView()
                    }
                } else {
                    // Notify user
                    await MainActor.run {
                        alert(with: "Shared Fridge Not Found", message: "")
                    }
                }
            }
            
        } else {
            // User not signed in
            alert(with: "Sign up before joining", message: "You need to sign up for a free account before joining")
        }
        
    }
    
    func presentGroupView() {
        guard Utility.fridgeId != nil,
              Utility.admin != nil,
              Utility.users != nil else {
                  // TODO: Show error message
                  return
              }
        hideLoadingView()
        performSegue(withIdentifier: "presentGroupSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "presentGroupSegue",
           let vc = segue.destination as? GroupViewController,
           let admin = Utility.admin,
           let users = Utility.users {
            vc.groupMembers = users.filter { $0.id != admin }.sorted(by: { $0.name > $1.name })
            vc.groupHost = users.first(where: { $0.id == admin })
            vc.isAdmin = UserManager.shared.userId == Utility.admin
            vc.leaveDelegate = self
        }
    }
}

// MARK: IBActions

extension GroupSignUpViewController {
    
    @objc func handleLogInWithAppleID() {
        showLoadingView()
        UserManager.shared.handleLogInWithAppleID { [weak self] success in
            if success {
                if let plusId = Utility.plusId,
                   plusId == UserManager.shared.userId {
                    self?.state = .plus
                } else if let product = self?.product {
                    self?.state = .loggedIn(product: product)
                } else {
                    self?.state = .loggedInNoProduct
                }
            }
            self?.hideLoadingView()
        }
    }
    
    @IBAction func onUpgradeButtonPressed(_ sender: UIButton) {
        guard let product = product else {
            return
        }
        showLoadingView()
        
        StoreObserver.shared.buy(product)
    }
    
    @IBAction func onRestoreButtonPressed(_ sender: UIButton) {
        showLoadingView()
        StoreObserver.shared.restore()
    }
    
    @IBAction func onCreateFridgePressed(_ sender: UIButton) {
        guard let user = UserManager.shared.userId else {
            return
        }
        showLoadingView()
        let categories = try! AppDelegate.viewContext.fetch(Category.fetchRequest())
        Task {
            try await FridgeManager.shared.createFridge(user: user, name: "My Fridge", categories: categories)
            await MainActor.run {
                presentGroupView()
            }
        }
    }
}

// MARK: StoreObserverDelegate

extension GroupSignUpViewController: StoreObserverDelegate {
    
    func didReceiveProducts(_ products: [SKProduct]) {
        hideLoadingView()
        if products.first?.productIdentifier == "fridgy_iap_1" {
            // Show button
            let product = products.first!
            self.product = product
            switch state {
                case .loggedInNoProduct:
                    self.state = .loggedIn(product: product)
                default: break
            }
        } else {
            // Show error
            alert(with: "Something went wrong", message: "Oops, it seems that Fridgy Plus is unavailable")
        }
    }
    
    func failedToReceiveProducts() {
        // Show error
        alert(with: "Something went wrong", message: "Oops, it seems that Fridgy Plus is unavailable")
    }
    
    func restoreDidSucceed(_ productId: String) {
        hideLoadingView()
        if productId == "fridgy_iap_1" {
            Utility.plusId = UserManager.shared.userId
            state = .plus
            SPConfetti.startAnimating(.centerWidthToDown, particles: [.arc], duration: 2)
            alert(with: "Restore Succeeded", message: "Fridgy Plus purchase restored")
        } else {
            alert(with: "Something went wrong", message: "Unrecognised restored purchase")
        }
    }
    
    func purchaseDidSucceed() {
        hideLoadingView()
        Utility.plusId = UserManager.shared.userId
        state = .plus
        SPConfetti.startAnimating(.centerWidthToDown, particles: [.arc], duration: 2)
    }
    
    func purchaseCancelled() {
        hideLoadingView()
    }
    
    func restoreCancelled() {
        hideLoadingView()
    }
    
    func restoreDidFail(with error: Error) {
        hideLoadingView()
        print("Restore Failed: \(error.localizedDescription)")
        alert(with: "Restore Failed", message: "Please try again later.")
    }
    
    func purchaseDidFail(with error: Error) {
        hideLoadingView()
        print("Purchase Failed: \(error.localizedDescription)")
        alert(with: "Purchase Failed", message: "You have not been charged.")
    }
    
}

// MARK: LoadingView

extension GroupSignUpViewController {
    func showLoadingView() {
        activityIndicator.startAnimating()
        navigationController?.navigationBar.isUserInteractionEnabled = false
        view.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.loadingView.alpha = 1
        })
    }
    
    func hideLoadingView() {
        activityIndicator.stopAnimating()
        navigationController?.navigationBar.isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            self?.loadingView.alpha = 0
        })
    }
}

// MARK: GroupLeaveDelegate

extension GroupSignUpViewController: GroupLeaveDelegate {
    func didLeaveGroup() {
        alert(with: "Shared Fridge left", message: "Your fridge will no longer be shared with others")
    }
}
