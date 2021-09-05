//
//  FridgeTableHeaderView.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 04/09/2021.
//  Copyright © 2021 Ted Bennett. All rights reserved.
//

import UIKit

protocol HeaderTableViewCellDelegate: AnyObject {
    func didStartEditing(at index: Int)
}

class FridgeTableHeaderView: UITableViewHeaderFooterView {
    
    static let identifier = "FridgeTableHeaderView"
    
    var section: Int?
    weak var delegate: HeaderTableViewCellDelegate?
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = .gray
        return label
    }()
    
    let button: UIButton = {
        let button = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular, scale: .default)
        button.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)
        return button
    }()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(button)
        contentView.addSubview(titleLabel)
        
        button.addTarget(self, action: #selector(onPress(_:)), for: .touchUpInside)
        
        configureAutoLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureAutoLayout() {
        button.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.trailingAnchor
            ),
            button.widthAnchor.constraint(
                equalToConstant: 20
            ),
            button.heightAnchor.constraint(
                equalToConstant: 20
            ),
            button.centerYAnchor.constraint(
                equalTo: contentView.centerYAnchor
            ),
            
            titleLabel.heightAnchor.constraint(
                equalToConstant: 20
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: button.leadingAnchor,
                constant: 8)
            ,
            titleLabel.leadingAnchor.constraint(
                equalTo: contentView.layoutMarginsGuide.leadingAnchor
            ),
            titleLabel.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor, constant: -4
            )
        ])
    }
    
    func setup(title: String, section: Int, delegate: HeaderTableViewCellDelegate) {
        titleLabel.text = title.uppercased()
        self.delegate = delegate
        self.section = section
    }
    
    @objc private func onPress(_ sender: UIButton) {
        guard let section = section else { return }
        delegate?.didStartEditing(at: section)
    }
}
