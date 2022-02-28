//
//  TutorialPageViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 28/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import UIKit
import AVKit

class TutorialPageViewController: UIViewController {

    enum PageType {
        case addItems
        case moveItems
        case slideActions
        case shoppingList
        case refreshFridge
        
        func filename(darkMode: Bool) -> String {
            let mode = darkMode ? "dark" : "light"
            switch self {
                case .addItems:
                    return "add_items_\(mode)"
                case .moveItems:
                    return "move_items_\(mode)"
                case .slideActions:
                    return "swipe_actions_\(mode)"
                case .shoppingList:
                    return "shopping_list_\(mode)"
                case .refreshFridge:
                    return "refresh_fridge_\(mode)"
            }
        }
        
        var title: String {
            switch self {
                case .addItems:
                    return "Add Items"
                case .moveItems:
                    return "Move Items"
                case .slideActions:
                    return "Slide Actions"
                case .shoppingList:
                    return "Shopping List"
                case .refreshFridge:
                    return "Shared Fridges"
            }
        }
        
        var topText: String {
            switch self {
                case .addItems:
                    return ""
                case .moveItems:
                    return "To move items, press and hold an item, then drag it"
                case .slideActions:
                    return "You can add items to your shopping list by swiping left on them in your fridge"
                case .shoppingList:
                    return "You can add extra items to the shopping list by pressing the \"+\" button"
                case .refreshFridge:
                    return "Shared Fridges allows you to invite others to access and edit your Fridge"
            }
        }
        
        var bottomText: String {
            switch self {
                case .addItems:
                    return "To add items, just press the \"+\" button at the top of a category"
                case .moveItems:
                    return "You can add more categories by pressing the categories button at the top-right"
                case .slideActions:
                    return "You can also delete items by swiping right"
                case .shoppingList:
                    return "Items that are checked off that are not already in your fridge are added to the \"Other\" category"
                case .refreshFridge:
                    return "Once you are in a Shared Fridge, just pull down to refresh"
            }
        }
    }
    
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playerParent: UIView!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var topLabel: UILabel!
    var playerView = PlayerView()
    var type: PageType!
    
    convenience init(type: PageType) {
        self.init(nibName: "TutorialPageViewController", bundle: nil)
        self.type = type
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        playerView.translatesAutoresizingMaskIntoConstraints = false
        
        playerParent.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: playerParent.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: playerParent.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: playerParent.bottomAnchor),
            playerView.topAnchor.constraint(equalTo: playerParent.topAnchor)
        ])
        
        titleLabel.text = type.title
        topLabel.text = type.topText
        bottomLabel.text = type.bottomText
        
        let isDark = traitCollection.userInterfaceStyle == .dark
        playerView.setup(filename: type.filename(darkMode: isDark), ext: isDark ? ".mov" : ".mp4")
    }
    
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isDark = traitCollection.userInterfaceStyle == .dark
        playerView.setup(filename: type.filename(darkMode: isDark), ext: isDark ? ".mov" : ".mp4")
    }
}


class PlayerView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    
    func setup(filename: String, ext: String) {
        let url = Bundle.main.url(forResource: filename, withExtension: ext)!
        let playerItem = AVPlayerItem(url: url)
        
        let player = AVQueuePlayer(playerItem: playerItem)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        
        playerLayer.cornerRadius = 20
        layer.addSublayer(playerLayer)
        layer.cornerRadius = 20
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        player.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
