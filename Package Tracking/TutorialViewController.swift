//
//  TutorialViewController.swift
//  Package Tracking
//
//  Created by Matt Giovanniello on 12/5/17.
//  Copyright © 2017 Matt Giovanniello. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {
    
    
    @IBOutlet weak var tutorialImage: UIImageView!
    @IBOutlet weak var tutorialHeader: UILabel!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var exitTutorialButton: UIButton!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    var lastScreenViewed: Int?
    var currentScreen = 0
    var tutorialViewed: String?
    
    @IBOutlet weak var welcomeHeader: UILabel!
    @IBOutlet weak var welcomeText: UILabel!
    
    var defaultsData = UserDefaults.standard

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tutorialViewed = "yes"
        defaultsData.set(tutorialViewed, forKey: "tutorialViewed")
        
        displayScreen(screen: 0)
        
    }
    
    func displayScreen(screen: Int) {
        animateHeader(itemToAnimate: tutorialHeader)
        animateText(itemToAnimate: tutorialText)
        animateImage(itemToAnimate: tutorialImage)
        tutorialImage.image = UIImage(named: "packtrack-demo-\(screen)")
        if screen == 0 {
            backButton.isEnabled = false
            tutorialImage.isHidden = true
            tutorialHeader.isHidden = true
            tutorialText.isHidden = true
            welcomeHeader.isHidden = false
            welcomeText.isHidden = false
            animateHeader(itemToAnimate: welcomeHeader)
            animateHeader(itemToAnimate: welcomeText)
        }
        if screen == 1 {
            tutorialImage.isHidden = false
            tutorialHeader.isHidden = false
            tutorialText.isHidden = false
            welcomeHeader.isHidden = true
            welcomeText.isHidden = true
            backButton.isEnabled = true
            nextButton.isEnabled = true
            tutorialHeader.text = "Login to the App"
            tutorialText.text = "Enter your BC username and password to get started. You'll be able to use Touch ID for faster access after you've logged in."
        }
        if screen == 2 {
            backButton.isEnabled = true
            nextButton.isEnabled = true
            tutorialHeader.text = "View Your Packages"
            tutorialText.text = "Tap the (+) button to add a new package. They'll be stored on the My Packages page for easy access later."
        }
        if screen == 3 {
            backButton.isEnabled = true
            nextButton.isEnabled = true
            tutorialHeader.text = "Add New Packages"
            tutorialText.text = "Copy and paste the tracking number from an email or website – or type it in manually. Give the package a name, and never think of that long number again."
        }
        
        if screen == 4 {
            backButton.isEnabled = true
            nextButton.isEnabled = false
            tutorialHeader.text = "Check the Package's Status"
            tutorialText.text = "There's a lot that happens before you get the \"Package ready for pickup\" email. See your package's location in real-time on the Package Details screen. When it's ready to be picked up, the mailroom and shelf number will automatically appear."
        }
    }
    
    func animateHeader(itemToAnimate: UILabel) {
        UIView.animate(withDuration: 0.5, animations: {
            itemToAnimate.alpha = 0
            self.view.addSubview(itemToAnimate)
            itemToAnimate.alpha = 1.0
        })
    }
    
    func animateText(itemToAnimate: UITextView) {
        UIView.animate(withDuration: 0.5, animations: {
            itemToAnimate.alpha = 0
            self.view.addSubview(itemToAnimate)
            itemToAnimate.alpha = 1.0
        })
    }
    
    
    func animateImage(itemToAnimate: UIImageView) {
        itemToAnimate.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
            itemToAnimate.alpha = 1.0
        }
            , completion: nil )
    }
    
    

    @IBAction func nextButtonPressed(_ sender: UIBarButtonItem) {
        currentScreen += 1
        displayScreen(screen: currentScreen)
    }
    
    @IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
        currentScreen -= 1
        displayScreen(screen: currentScreen)
    }
    
    @IBAction func exitTutorialButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    
}
