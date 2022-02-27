//
//  TutorialViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 27/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import UIKit
import AVFoundation

class TutorialViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        playerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.heightAnchor.constraint(equalToConstant: 200),
            playerView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        
        
        playerView.setup(filename: "add_items")
        // Do any additional setup after loading the view.
    }
    
    var playerView = PlayerView()

}

class PlayerView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    
    func setup(filename: String) {
        let url = Bundle.main.url(forResource: filename, withExtension: ".mov")!
        let playerItem = AVPlayerItem(url: url)
        
        let player = AVQueuePlayer(playerItem: playerItem)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer.addSublayer(playerLayer)
        
        playerLooper = AVPlayerLooper(player: player, templateItem: playerItem)
        
        player.play()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}
