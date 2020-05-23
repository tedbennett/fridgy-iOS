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
    
    
    func createPages() -> [Page] {
        
        let page1 : Page = Bundle.main.loadNibNamed("Page", owner: self, options: nil)?.first as! Page
        page1.titleLabel.text = "Welcome To Fridgy"
        page1.bodyLabel.text = "Fridgy is an app that helps you \norganise your fridge"
        let page2 : Page = Bundle.main.loadNibNamed("Page", owner: self, options: nil)?.first as! Page
        page2.titleLabel.text = "No Waste"
        page2.bodyLabel.text = "Fridgy sorts your fridge by expiration date to help you know what food needs eating\n\n\nNot sure what to make? \nSelect some items from your fridge and search for recipes in the top-right menu"
        let page3 : Page = Bundle.main.loadNibNamed("Page", owner: self, options: nil)?.first as! Page
        page3.titleLabel.text = "No Micromanagement"
        page3.bodyLabel.text = "Running low on something? \njust swipe left on that item.\n\n Run out? \nJust swipe right"
        let page4 : Page = Bundle.main.loadNibNamed("Page", owner: self, options: nil)?.first as! Page
        page4.titleLabel.text = "Shopping Lists"
        page4.bodyLabel.text = "Favourite an item to let Fridgy know it’s something that’s always in your fridge\n\n\nYour favourites are automatically added to your shopping list when they're running low or have run out.\n\n\nOnce you’ve stocked up, you can add any items from your shopping list back into your fridge in one tap"
        
        let page5 : Page = Bundle.main.loadNibNamed("Page", owner: self, options: nil)?.first as! Page
        page5.titleLabel.text = "Enjoy!"
        page5.bodyLabel.text = "Feel free to leave me some feedback on the App Store :)"
        page5.exitLabel.isHidden = false

        return [page1, page2, page3, page4, page5]
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
