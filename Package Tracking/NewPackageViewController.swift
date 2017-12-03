//
//  NewPackageViewController.swift
//  Package Tracking
//
//  Created by Matt Giovanniello on 11/29/17.
//  Copyright © 2017 Matt Giovanniello. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class NewPackageViewController: UIViewController {

    @IBOutlet weak var trackingNumberField: UITextField!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    @IBOutlet weak var packageNameField: UITextField!
    var packageItem: String?
    var packageName: String?
    var carrier: String?
    var activityIndicator = UIActivityIndicatorView()

    
    override func viewDidLoad() {
        super.viewDidLoad()

        enableDisableSaveButton()
        trackingNumberField.becomeFirstResponder()
        
    }
    
    
    func checkCarrier(completed: @escaping () -> ()) {
        
        setUpActivityIndicator()
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // check the shipping carrier
        packageItem = trackingNumberField.text
        let trackingURL = "https://shipit-api.herokuapp.com/api/guess/" + "\(packageItem!)"
        
        Alamofire.request(trackingURL).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                self.carrier = json[0].stringValue
                print("\(self.carrier!)")
                if self.carrier == "" {
                    self.showAlert(title: "Unable to Detect Carrier", message: "Double check the tracking number. If you're sure it's correct, tracking updates for this package won't appear until it is scanned in by BC Mail Services.")
                }
                
            case .failure(let error):
                print("ERROR: \(error) failed to detect shipping carrier from url \(trackingURL)")
            }
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            completed()
        }
    
        
    }
    
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    
    func setUpActivityIndicator() {
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.color = UIColor.black
        view.addSubview(activityIndicator)
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UnwindFromSave" {
            
            packageItem = trackingNumberField.text
                if self.packageNameField.text != "" {
                    self.packageName = self.packageNameField.text
                } else {
                    if self.carrier != "" {
                        switch self.carrier {
                        case "usps"?:
                            self.carrier = "USPS"
                        case "ups"?:
                            self.carrier = "UPS"
                        case "fedex"?:
                            self.carrier = "FedEx"
                        default:
                            self.carrier = self.carrier?.capitalized
                            
                        }
                        self.packageName = "\(carrier!) Package"
                    } else {
                        self.packageName = "Package"
                    }
                }
            }
        }
    
    

    

    func enableDisableSaveButton() {
        if let trackingNumberFieldCount = trackingNumberField.text?.count, trackingNumberFieldCount > 0 {
            saveBarButton.isEnabled = true
        } else {
            saveBarButton.isEnabled = false
        }
    }
    
    @IBAction func packageNameFieldChanged(_ sender: UITextField) {
        enableDisableSaveButton()
    }
    

    @IBAction func trackingNumberFieldUpdated(_ sender: UITextField)
    {
        checkCarrier {
            self.enableDisableSaveButton()
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
                dismiss(animated: true, completion: nil)

    }
    

}
