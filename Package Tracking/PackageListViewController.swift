//
//  PackageListViewController.swift
//  Package Tracking
//
//  Created by Matt Giovanniello on 11/28/17.
//  Copyright © 2017 Matt Giovanniello. All rights reserved.
//

import UIKit

class PackageListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addButton: UIBarButtonItem!
    var packageItem: String?
    
    var defaultsData = UserDefaults.standard
    
    var packageNamesArray = [String]()
    var packagesArray = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        packageNamesArray = defaultsData.stringArray(forKey: "packageNamesArray") ?? [String]()
        packagesArray = defaultsData.stringArray(forKey: "packagesArray") ?? [String]()
    }

    
    func saveDefaultsData() {
        defaultsData.set(packageNamesArray, forKey: "packageNamesArray")
        defaultsData.set(packagesArray, forKey: "packagesArray")
    }
   
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewPackage" {
            let destination = segue.destination as? PackageDetailsViewController
            let index = tableView.indexPathForSelectedRow!.row
            destination?.packageItem = packagesArray[index]
            destination?.packageName = packageNamesArray[index]
           if let selectedPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedPath, animated: false)
            }
        }
    }
    
    
    @IBAction func unwindFromNewPackageViewController(segue: UIStoryboardSegue) {
        let sourceViewController = segue.source as! NewPackageViewController
        let newIndexPath = IndexPath(row: packagesArray.count, section: 0)
        packagesArray.append(sourceViewController.packageItem!)
        packageNamesArray.append(sourceViewController.packageName!)
        tableView.insertRows(at: [newIndexPath], with: .automatic)
        saveDefaultsData()
        }
    

    @IBAction func editBarButtonPressed(_ sender: UIBarButtonItem) {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            addButton.isEnabled = true
            editButton.title = "Edit"
        } else {
            tableView.setEditing(true, animated: true)
            addButton.isEnabled = false
            editButton.title = "Done"
        }
        
    }
}






extension PackageListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return packagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = packageNamesArray[indexPath.row]
        cell.detailTextLabel?.text = packagesArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            packagesArray.remove(at: indexPath.row)
            packageNamesArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveDefaultsData()
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let packageToMove = packagesArray[sourceIndexPath.row]
        let packageNameToMove = packageNamesArray[sourceIndexPath.row]
        packagesArray.remove(at: sourceIndexPath.row)
        packageNamesArray.remove(at: sourceIndexPath.row)
        packagesArray.insert(packageToMove, at: destinationIndexPath.row)
        packageNamesArray.insert(packageNameToMove, at: destinationIndexPath.row)
        saveDefaultsData()
    }
}



