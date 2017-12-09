//
//  ViewController.swift
//  Package Tracking
//
//  Created by Matt Giovanniello on 11/28/17.
//  Copyright © 2017 Matt Giovanniello. All rights reserved.
//

import UIKit
import LocalAuthentication
import Alamofire



class ViewController: UIViewController {
    
    
    @IBOutlet weak var errorMessage: UILabel!
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    var result = ""
    var username = ""
    var password = ""
    var error: NSError?
    var resultCode: Int?
    var loggedInUser: String?
    var tutorialViewed: String?
    
    var defaultsData = UserDefaults.standard
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        username = defaultsData.string(forKey: "username") ?? String()

        if username != "" {
            usernameField.text = username
            touchIDAuthenticate()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tutorialViewed = defaultsData.string(forKey: "tutorialViewed") ?? String()
        if tutorialViewed != "yes" {
            performSegue(withIdentifier: "SegueToTutorial", sender: nil)
        }
    }
    
    
    func saveDefaultsData() {
        defaultsData.set(username, forKey: "username")
    }
    
    
    func checkCredentials() {
        
        
        if username == "" || password == "" {
            self.showAlert(title: "Empty Field", message: "Please enter your username and password.")
        }
        
        let params: Parameters = ["username":username, "password":password]

        
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        Alamofire.request("https://api.bc.edu/a/", method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            self.checkResults(of: response.result.value!)
            
        }

        
    }
    

    
    func checkResults(of result: String) {
        if result == "Successful bind!" {
            saveDefaultsData()
            
            
            performSegue(withIdentifier: "MainScreen", sender: nil)
            
        }
        else if result == "Bind failed" {
            showAlert(title: "Incorrect Credentials", message: "Please try again.")
        }
    }

    
    
    
    
    
    func touchIDAuthenticate() {
        let context = LAContext()
        var error: NSError?
        
        user.userName = username

        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "View packages for \(username)@bc.edu"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [unowned self] success, authenticationError in
                
                DispatchQueue.main.async {
                    if success {
                        self.performSegue(withIdentifier: "MainScreen", sender: nil)
                    }
                    }
                }
            
        } else {
            let ac = UIAlertController(title: "Touch ID Not Available", message: "Your device is not configured for Touch ID.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    

    
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        
        username = usernameField.text!
        password = passwordField.text!
        user.userName = username

        checkCredentials()
        
    }
}
