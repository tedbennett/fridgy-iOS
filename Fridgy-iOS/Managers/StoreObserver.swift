//
//  StoreObserver.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 26/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import Foundation
import StoreKit

class StoreObserver: NSObject {
    
    static let shared = StoreObserver()
    
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    /// Keeps track of all purchases.
    var purchased = [SKPaymentTransaction]()
    
    /// Keeps track of all restored purchases.
    var restored = [SKPaymentTransaction]()
    
    /// Indicates whether there are restorable purchases.
    fileprivate var hasRestorablePurchases = false
    
    fileprivate var productRequest: SKProductsRequest!
    
    weak var delegate: StoreObserverDelegate?
    
    // MARK: - Initializer
    
    private override init() {}
    
    
    func fetchProducts() {
        // Create a set for the product identifiers.
        let productIdentifiers = Set(["fridgy_iap_1"])
        
        // Initialize the product request with the above identifiers.
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest.delegate = self
        
        // Send the request to the App Store.
        productRequest.start()
    }
    
    // MARK: - Submit Payment Request
    
    /// Create and add a payment request to the payment queue.
    func buy(_ product: SKProduct) {
        let payment = SKMutablePayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - Restore All Restorable Purchases
    
    /// Restores all previously completed purchases.
    func restore() {
        if !restored.isEmpty {
            restored.removeAll()
        }
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: - Handle Payment Transactions
    
    /// Handles successful purchase transactions.
    fileprivate func handlePurchased(_ transaction: SKPaymentTransaction) {
        purchased.append(transaction)
        print("Purchase complete: \(transaction.payment.productIdentifier).")
        
        // Finish the successful transaction.
        SKPaymentQueue.default().finishTransaction(transaction)
        
        DispatchQueue.main.async {
            self.delegate?.purchaseDidSucceed()
        }
    }
    
    /// Handles failed purchase transactions.
    fileprivate func handleFailed(_ transaction: SKPaymentTransaction) {
        // Do not send any notifications when the user cancels the purchase.
        if (transaction.error as? SKError)?.code == .paymentCancelled {
            DispatchQueue.main.async {
                self.delegate?.purchaseCancelled()
            }
        } else if let error = transaction.error {
            DispatchQueue.main.async {
                self.delegate?.purchaseDidFail(with: error)
            }
        }
        // Finish the failed transaction.
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    /// Handles restored purchase transactions.
    fileprivate func handleRestored(_ transaction: SKPaymentTransaction) {
        hasRestorablePurchases = true
        restored.append(transaction)
        print("Restored: \(transaction.payment.productIdentifier).")
        
        
        DispatchQueue.main.async {
            self.delegate?.restoreDidSucceed(transaction.payment.productIdentifier)
        }
        // Finishes the restored transaction.
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

// MARK: - SKPaymentTransactionObserver

/// Extends StoreObserver to conform to SKPaymentTransactionObserver.
extension StoreObserver: SKPaymentTransactionObserver {
    /// Called when there are transactions in the payment queue.
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
                case .purchasing: break
                    // Do not block the UI. Allow the user to continue using the app.
                case .deferred: print("Purchase deferred")
                    // The purchase was successful.
                case .purchased: handlePurchased(transaction)
                    // The transaction failed.
                case .failed: handleFailed(transaction)
                    // There're restored products.
                case .restored: handleRestored(transaction)
                @unknown default: fatalError("Invalid transaction state")
            }
        }
    }
    
    /// Logs all transactions that have been removed from the payment queue.
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            print("\(transaction.payment.productIdentifier) removed")
        }
    }
    
    /// Called when an error occur while restoring purchases. Notify the user about the error.
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if let error = error as? SKError {
            if error.code == .paymentCancelled {
                DispatchQueue.main.async {
                    self.delegate?.restoreCancelled()
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.restoreDidFail(with: error)
                }
            }
        }
    }
    
    /// Called when all restorable transactions have been processed by the payment queue.
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        
//        if !hasRestorablePurchases {
//            DispatchQueue.main.async {
//                self.delegate?.storeObserverDidReceiveMessage(Messages.noRestorablePurchases)
//            }
//        }
    }
}


// MARK: - StoreObserverDelegate

protocol StoreObserverDelegate: AnyObject {
    func didReceiveProducts(_ products: [SKProduct])
    
    func failedToReceiveProducts()
    
    func restoreDidSucceed(_ productId: String)
    
    func purchaseDidSucceed()
    
    func purchaseCancelled()
    
    func restoreCancelled()
    
    func restoreDidFail(with error: Error)
    
    func purchaseDidFail(with error: Error)
}

extension StoreObserver: SKProductsRequestDelegate {
    /// Used to get the App Store's response to your request and notify your observer.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.products.isEmpty {
            DispatchQueue.main.async {
                self.delegate?.didReceiveProducts(response.products)
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.failedToReceiveProducts()
            }
        }
    }
}
