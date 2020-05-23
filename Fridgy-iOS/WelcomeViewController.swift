//
//  WelcomeViewController.swift
//  Fridgy-iOS
//
//  Created by Ted Bennett on 23/05/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, UIScrollViewDelegate {

    var pages = [Page]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.delegate = self
        
        pages = createPages()
        setupPageScrollView(slides: pages)
        
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        view.bringSubviewToFront(pageControl)
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private func page(title: String, body: NSAttributedString, hideExit: Bool = true) -> Page {
        let page = Bundle.main.loadNibNamed("Page", owner: self, options: nil)?.first as! Page
        page.titleLabel.text = title
        page.bodyLabel.attributedText = body
        page.exitLabel.isHidden = hideExit
        return page
    }
    private func createPages() -> [Page] {
        

        
        let headerAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
        let bodyAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)]

        let page1body = NSAttributedString(string: "Fridgy is an app that helps you \norganise your fridge", attributes: bodyAttributes)
        
        let page2body = NSMutableAttributedString(string: "Know what's about to expire", attributes: headerAttributes)
        page2body.append(NSAttributedString(string: "\nFridgy sorts your fridge by expiration date to help you know what food needs eating\n\n", attributes: bodyAttributes))
        page2body.append(NSAttributedString(string: "Not sure what to make?", attributes: headerAttributes))
        page2body.append(NSAttributedString(string: "\nSelect some items from your fridge and search for recipes in the top-right menu", attributes: bodyAttributes))
       
        let page3body = NSMutableAttributedString(string: "Running low on something?\n", attributes: headerAttributes)
        page3body.append(NSAttributedString(string: "Just swipe left on that item, and Fridgy will remember that for you.\n\n", attributes: bodyAttributes))
        page3body.append(NSAttributedString(string: "Run out?\n", attributes: headerAttributes))
        page3body.append(NSAttributedString(string: "Just swipe right!", attributes: bodyAttributes))
        
        let page4body = NSAttributedString(string: "Favourite an item to let Fridgy know it’s something that’s always in your fridge\n\nYour favourites are automatically added to your shopping list when they're running low or have run out.\n\nOnce you’ve gone shopping, you can add any items from your shopping list back into your fridge in one tap", attributes: bodyAttributes)
        
        let page5body = NSAttributedString(string: "Feel free to leave me some feedback on the App Store :)", attributes: bodyAttributes)
        

        return [page(title: "Welcome To Fridgy", body: page1body),
                page(title: "No Waste", body: page2body),
                page(title: "No Micromanagement", body: page3body),
                page(title: "Shopping Lists", body: page4body),
                page(title: "Enjoy!", body: page5body, hideExit: false)]
    }
    
    func setupPageScrollView(slides : [Page]) {
        scrollView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(pages.count), height: view.frame.height)
        scrollView.isPagingEnabled = true
        
        for i in 0 ..< pages.count {
            pages[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: view.frame.height)
            scrollView.addSubview(pages[i])
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }
    
    
}
