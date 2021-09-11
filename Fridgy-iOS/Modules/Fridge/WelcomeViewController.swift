//
//  WelcomeViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 11/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var fridgyLabel: UILabel!
    @IBOutlet weak var welcomeToLabel: UILabel!
    @IBOutlet weak var dismissButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var titleFont = UIFont.preferredFont(forTextStyle: .largeTitle)
        titleFont = UIFont(
            descriptor:
                titleFont.fontDescriptor
                .withDesign(.rounded)? /// make rounded
                .withSymbolicTraits(.traitBold) ?? titleFont.fontDescriptor,
            size: titleFont.pointSize
        )
        welcomeToLabel.font = titleFont
        fridgyLabel.font = titleFont
        dismissButton.layer.cornerRadius = 10
    }
    
    @IBAction func onDismissButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}
