//
//  TutorialViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 27/02/2022.
//  Copyright © 2022 Ted Bennett. All rights reserved.
//

import UIKit

class TutorialViewController: UIPageViewController {
    
    var pageItems: [UIViewController] = []
    var pageIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pageItems = [
            TutorialPageViewController(type: .addItems),
            TutorialPageViewController(type: .moveItems),
            TutorialPageViewController(type: .slideActions),
            TutorialPageViewController(type: .shoppingList),
            TutorialPageViewController(type: .refreshFridge)
        ]
        view.backgroundColor = .systemBackground
        
        UIPageControl.appearance().currentPageIndicatorTintColor = .systemGreen
        UIPageControl.appearance().pageIndicatorTintColor = .systemGray5
        
        delegate = self
        dataSource = self
        
        setViewControllers([pageItems[0]], direction: .forward, animated: false)
        
        navigationItem.hidesBackButton = true
        let doneButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(onDoneButtonPressed))
        doneButton.tintColor = .systemGreen
        navigationItem.rightBarButtonItem = doneButton
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        view.addSubview(label)
        label.text = "Swipe to continue"
        
        
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: scrollView!.bottomAnchor)
        ])
    }
    
    @objc func onDoneButtonPressed() {
        dismiss(animated: true)
    }
}

extension TutorialViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        pageItems.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        pageIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pageItems.firstIndex(of: viewController),
              index > 0 else {
            return nil
        }
        return pageItems[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pageItems.firstIndex(of: viewController),
              index < pageItems.count - 1 else {
                  return nil
              }
        return pageItems[index + 1]
    }
}

extension UIPageViewController {
    var scrollView: UIScrollView? {
        for view in view.subviews {
            if view is UIScrollView {
                return view as? UIScrollView
            }
        }
        return nil
    }
}
