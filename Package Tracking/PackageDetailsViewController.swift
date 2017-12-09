//
//  PackageDetailsViewController.swift
//  Package Tracking
//
//  Created by Matt Giovanniello on 11/29/17.
//  Copyright © 2017 Matt Giovanniello. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class PackageDetailsViewController: UIViewController {
    
    @IBOutlet weak var trackingNumberField: UILabel!
    @IBOutlet weak var packageStatusText: UILabel!
    
    @IBOutlet weak var carrierField: UILabel!
    
    @IBOutlet weak var imageStatusBar: UIImageView!
    @IBOutlet weak var imageOnItsWay: UIImageView!
    @IBOutlet weak var imageEnRouteToBCMailServices: UIImageView!
    @IBOutlet weak var imageMailRoomProcessing: UIImageView!
    
    @IBOutlet weak var step1HeaderText: UILabel!
    @IBOutlet weak var step1DetailsText: UILabel!
    @IBOutlet weak var step2HeaderText: UILabel!
    @IBOutlet weak var step2DetailsText: UILabel!
    
    @IBOutlet weak var step3HeaderText: UILabel!
    
    @IBOutlet weak var step3DetailsText: UILabel!

    
    @IBOutlet weak var internalPackageIDField: UILabel!
    @IBOutlet weak var internalPackageLocationField: UILabel!
    
    
    @IBOutlet weak var centerStatusImage: UIImageView!
    @IBOutlet weak var centerStatusLabel: UILabel!
    @IBOutlet weak var centerStatusDetailsLabel: UITextView!
    @IBOutlet weak var pickedUpButton: UIButton!
    
    
    var defaultsData = UserDefaults.standard
    
    var packageItem: String?
    var packageName: String?
    var carrier: String?
    var trackingNumberStatus: String?
    var statusCode: Int?
    var deliveryDate: String?
    var mailRoomStatus: String?
    var internalPackageID: String?
    var internalPackageLocation: String?
    var range: Int?
    var endIndex: Int?
    
    var activityIndicator = UIActivityIndicatorView()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = packageName
        trackingNumberField.text = packageItem
        
        mailRoomStatus = defaultsData.string(forKey: "packageStatus-\(packageItem!)") ?? String()
        internalPackageLocation = defaultsData.string(forKey: "packageLocation-\(packageItem!)") ?? String()
        
        if mailRoomStatus == "Picked Up" {
            updateUserInterface()
        } else if mailRoomStatus == "Ready for Pickup" {
            updateUserInterface()
        } else {
            getPackageShippingCarrier {
                print("Success - getPackageShippingCarrier completed")
                self.getPackageStatusFromCarrier {
                    print("Success - getPackageStatusFromCarrier completed")
                    self.getPackageStatusFromBC {
                        print("Success - getPackageStatusFromBC completed")
                        self.getPackageLocation {
                            print("Success - getPackageLocation completed")
                            self.updateUserInterface()
                        }
                    }
                }
            }
        }
    }
    
    
    func saveDefaultsData() {
        defaultsData.set(mailRoomStatus, forKey: "packageStatus-\(packageItem!)")
    }
    
    
    
    
    func setUpActivityIndicator() {
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.color = UIColor.black
        view.addSubview(activityIndicator)
    }
    
    
    
    
    // First step
    
    
    func getPackageShippingCarrier(completed: @escaping () -> ()) {
        
        setUpActivityIndicator()
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // check the shipping carrier
        
        let trackingURL = "https://shipit-api.herokuapp.com/api/guess/" + "\(trackingNumberField.text!)"
        
        Alamofire.request(trackingURL).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                self.carrier = json[0].stringValue
                print("\(self.carrier!)")
                self.carrierField.text = self.carrier
                
            case .failure(let error):
                print("ERROR: \(error) failed to detect shipping carrier from url \(trackingURL)")
            }
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            completed()
        }
        
    }
    
    
    // Second step
    
    
    func getPackageStatusFromCarrier(completed: @escaping () -> ()) {
        
        setUpActivityIndicator()
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        
        
        // this currently only works for USPS -- so if it's not USPS, just mark trackingNumberStatus as "En Route"
        
        
        if carrierField.text == "usps" {
            // get the package status from the carrier
            
            let trackingURL = "https://shipit-api.herokuapp.com/api/carriers/" + "\(carrierField.text!)" + "/" + "\(self.trackingNumberField.text!)"
            
            Alamofire.request(trackingURL).responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    self.trackingNumberStatus = json["activities"][0]["details"].stringValue
                    self.statusCode = json["status"].intValue
                    self.deliveryDate = json["eta"].stringValue
                    print(self.deliveryDate!)
                    
                    
                case .failure(let error):
                    print("ERROR: \(error) failed to get package status from url \(trackingURL)")
                }
            }
        } else {
            
            switch self.carrier {
            case "usps"?:
                self.carrier = "USPS"
            case "ups"?:
                self.carrier = "UPS"
            case "fedex"?:
                self.carrier = "FedEx"
            default:
                self.carrier = self.carrier?.capitalized
                
                self.trackingNumberStatus = "En Route from \(self.carrier!)"
            }
            
            self.packageStatusText.text = self.trackingNumberStatus
        }
        self.activityIndicator.stopAnimating()
        UIApplication.shared.endIgnoringInteractionEvents()
        completed()
    }
    
    
    
    // Third step
    
    func getPackageStatusFromBC(completed: @escaping () -> ()) {
        
        // this is the bottleneck
        
        setUpActivityIndicator()
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // check to see if Mail Services has received the package yet
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        Alamofire.request("https://bc.sclintra.com/ec3x3i/search?query=\(trackingNumberField.text!)", method: .get, encoding: JSONEncoding.default, headers: headers).responseString { response in
            self.checkResults(of: response.result.value!)
            
            
            switch response.result {
            case .success( _):
                
                // extract the code from the webpage with the internal package ID
                if let checkInternalPackageID = (response.result.value?.slice(from: "AssetData: [{\"Id\":", to: ",")) {
                    self.internalPackageID = checkInternalPackageID
                    self.internalPackageIDField.text = self.internalPackageID!
                }
                
                
            case .failure(let error):
                print("ERROR: \(error) failed to get package status from BC tracking site)")
                
            }
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            completed()
        }
    }
    
    
    
    // Fourth step
    
    func getPackageLocation(completed: @escaping () -> ()) {
        
        setUpActivityIndicator()
        activityIndicator.startAnimating()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        // now use this internal package ID to get the location of the package
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        Alamofire.request("https://bc.sclintra.com/ec3x3i/asset/\(internalPackageIDField.text!)/\(trackingNumberField.text!)", method: .get, encoding: JSONEncoding.default, headers: headers).responseString { response in
            switch response.result {
            case .success( _):
                
                // extract the code from the webpage with the package location (within the mail room)
                self.internalPackageLocation = response.result.value?.slice(from: "Current Location:         <span>", to: "</span>")
                
                if self.internalPackageLocation != nil {
                    self.internalPackageLocationField.text = self.internalPackageLocation!

                }
                
                
            case .failure(let error):
                print("ERROR: \(error) failed to get package location from BC tracking site)")
            }
            
            self.activityIndicator.stopAnimating()
            UIApplication.shared.endIgnoringInteractionEvents()
            completed()
        }
    }
    
    
    // Check results of whether package is in BC's system
    
    func checkResults(of result: String) {
        
        if result.contains("Picked Up") {
            mailRoomStatus = "Picked Up"
            saveDefaultsData()
        } else if result.contains("Ready for Pickup") {
            mailRoomStatus = "Ready for Pickup"
            saveDefaultsData()
        } else if result.contains("Received") {
            mailRoomStatus = "Received"
        } else {
            mailRoomStatus = "Not Received"
        }
    }
    
    func animateText(itemToAnimate: UILabel) {
        UIView.animate(withDuration: 0.5, animations: {
            itemToAnimate.alpha = 0
            self.view.addSubview(itemToAnimate)
            itemToAnimate.alpha = 1.0
        })
    }
    
    
    func animateDetailsText(itemToAnimate: UITextView) {
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
    
    
    func animateButton(itemToAnimate: UIButton) {
        itemToAnimate.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
            itemToAnimate.alpha = 1.0
        }
            , completion: nil )
    }
    
    
    
    // gray out image/text
    
    func halfAnimateText(itemToAnimate: UILabel) {
        UIView.animate(withDuration: 0.5, animations: {
            itemToAnimate.alpha = 0
            self.view.addSubview(itemToAnimate)
            itemToAnimate.alpha = 0.5
        })
    }
    
    
    
    func halfAnimateImage(itemToAnimate: UIImageView) {
        itemToAnimate.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
            itemToAnimate.alpha = 0.5
        }
            , completion: nil )
    }
    
    
    
    
    
    func updateUserInterface() {
        
        
        if mailRoomStatus == "Ready for Pickup" {
            centerStatusImage.isHidden = false
            centerStatusLabel.isHidden = false
            centerStatusDetailsLabel.isHidden = false
            pickedUpButton.isHidden = false

            
            // show Ready for Pickup message
            animateText(itemToAnimate: centerStatusLabel)
            animateDetailsText(itemToAnimate: centerStatusDetailsLabel)
            animateImage(itemToAnimate: centerStatusImage)
            animateButton(itemToAnimate: pickedUpButton)
            
            centerStatusImage.image = UIImage(named: "ready-for-pickup")
            centerStatusLabel.text = "Ready for Pickup"
        
            centerStatusDetailsLabel.text = "Shelf: \(internalPackageLocation!)"
            defaultsData.set(internalPackageLocation, forKey: "packageLocation-\(packageItem!)")


            
        } else if mailRoomStatus == "Picked Up" {
            centerStatusImage.isHidden = false
            centerStatusLabel.isHidden = false
            
            // show Picked Up message
            animateText(itemToAnimate: centerStatusLabel)
            animateImage(itemToAnimate: centerStatusImage)
            
            centerStatusImage.image = UIImage(named: "picked-up")
            centerStatusLabel.text = "Picked Up"
            
        } else if carrier == "" && mailRoomStatus == "Not Received" {
            
            centerStatusImage.isHidden = false
            centerStatusLabel.isHidden = false
            
            
            // additional details label
            animateText(itemToAnimate: centerStatusLabel)
            centerStatusDetailsLabel.isHidden = false
            
            // show Unknown Status message
            animateText(itemToAnimate: centerStatusLabel)
            animateDetailsText(itemToAnimate: centerStatusDetailsLabel)
            animateImage(itemToAnimate: centerStatusImage)
            
            centerStatusImage.image = UIImage(named: "unknown-status")
            centerStatusLabel.text = "No Updates"
            centerStatusDetailsLabel.text = "It might take a few days for updates to appear. Check back in a few days to see if new updates have occurred."
            
        } else {
            
            
            imageStatusBar.isHidden = false
            animateImage(itemToAnimate: imageStatusBar)
            
            
            // unhide step 1 assets
            imageOnItsWay.isHidden = false
            step1HeaderText.isHidden = false
            step1DetailsText.isHidden = false
            
            // unhide step 2 assets
            imageEnRouteToBCMailServices.isHidden = false
            step2HeaderText.isHidden = false
            step2DetailsText.isHidden = false
            
            
            
            if statusCode == 1 || statusCode == 2 {
                
                // fade in Step 1
                
                animateText(itemToAnimate: step1HeaderText)
                animateText(itemToAnimate: step1DetailsText)
                animateImage(itemToAnimate: imageOnItsWay)
                
                // gray out others
                
                halfAnimateText(itemToAnimate: step2HeaderText)
                halfAnimateText(itemToAnimate: step2DetailsText)
                halfAnimateImage(itemToAnimate: imageEnRouteToBCMailServices)
                
                halfAnimateText(itemToAnimate: step3HeaderText)
                halfAnimateText(itemToAnimate: step3DetailsText)
                halfAnimateImage(itemToAnimate: imageMailRoomProcessing)
                

                let easyDate = deliveryDate?.prefix(10)
                step1HeaderText.text = "On Its Way"
                step1DetailsText.text = "\(trackingNumberStatus!)\nExpected Delivery Date: \(easyDate!)"
                
                
            }
            
            if statusCode == 3 {
                
                // fade in Step 1
                
                animateText(itemToAnimate: step1HeaderText)
                animateText(itemToAnimate: step1DetailsText)
                animateImage(itemToAnimate: imageOnItsWay)
                
                // gray out others
                
                halfAnimateText(itemToAnimate: step2HeaderText)
                halfAnimateText(itemToAnimate: step2DetailsText)
                halfAnimateImage(itemToAnimate: imageEnRouteToBCMailServices)
                
                halfAnimateText(itemToAnimate: step3HeaderText)
                halfAnimateText(itemToAnimate: step3DetailsText)
                halfAnimateImage(itemToAnimate: imageMailRoomProcessing)
            
                
                
                
                step1HeaderText.text = "On Its Way"
                step1DetailsText.text = "\(trackingNumberStatus!)\n"
                
                
            }
            if statusCode == 4 {
                
                
                step1HeaderText.text = "On Its Way"
                step1DetailsText.text = ""
                
                
            }
            
            
            // unhide step 3 assets
            imageMailRoomProcessing.isHidden = false
            step3HeaderText.isHidden = false
            step3DetailsText.isHidden = false

            
            
            
            if mailRoomStatus == "Received" {
                
                // fade in Step 3
                
                animateText(itemToAnimate: step3HeaderText)
                animateText(itemToAnimate: step3DetailsText)
                animateImage(itemToAnimate: imageMailRoomProcessing)
                
                // gray out others
                
                halfAnimateText(itemToAnimate: step1HeaderText)
                halfAnimateText(itemToAnimate: step1DetailsText)
                halfAnimateImage(itemToAnimate: imageOnItsWay)
                
                halfAnimateText(itemToAnimate: step2HeaderText)
                halfAnimateText(itemToAnimate: step2DetailsText)
                halfAnimateImage(itemToAnimate: imageEnRouteToBCMailServices)
                

                
                
                step3DetailsText.text = "Your package will be ready soon."
                
            }
            
            if carrier == "usps" && mailRoomStatus == "Not Received" {
                
                // fade in Step 2
                
                animateText(itemToAnimate: step2HeaderText)
                animateText(itemToAnimate: step2DetailsText)
                animateImage(itemToAnimate: imageEnRouteToBCMailServices)
                
                // gray out others
                
                halfAnimateText(itemToAnimate: step1HeaderText)
                halfAnimateText(itemToAnimate: step1DetailsText)
                halfAnimateImage(itemToAnimate: imageOnItsWay)
                
                halfAnimateText(itemToAnimate: step3HeaderText)
                halfAnimateText(itemToAnimate: step3DetailsText)
                halfAnimateImage(itemToAnimate: imageMailRoomProcessing)
                
                
                
                
            }
            
            if carrier != "usps" && mailRoomStatus == "Not Received" {
                print("On its way, not via USPS")
                // fade in Step 1
                
                animateText(itemToAnimate: step1HeaderText)
                animateText(itemToAnimate: step1DetailsText)
                animateImage(itemToAnimate: imageOnItsWay)
                
                // gray out others
                
                halfAnimateText(itemToAnimate: step2HeaderText)
                halfAnimateText(itemToAnimate: step2DetailsText)
                halfAnimateImage(itemToAnimate: imageEnRouteToBCMailServices)
                
                halfAnimateText(itemToAnimate: step3HeaderText)
                halfAnimateText(itemToAnimate: step3DetailsText)
                halfAnimateImage(itemToAnimate: imageMailRoomProcessing)

                
                
                step1HeaderText.text = "On Its Way"
                step1DetailsText.text = "Shipped via \(carrier!)\n"
                step2DetailsText.isHidden = true
                
            }
        }
    }
    
    
    @IBAction func pickedUpButtonPressed(_ sender: UIButton) {
        mailRoomStatus = "Picked Up"
        centerStatusDetailsLabel.isHidden = true
        pickedUpButton.isHidden = true
        saveDefaultsData()
        updateUserInterface()
    }
    
    
}

extension String {
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}
