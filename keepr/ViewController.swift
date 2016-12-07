//
//  ViewController.swift
//  keepr
//
//  Created by Jeremy Broutin on 12/6/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit
import Firebase

protocol RegionDelegate {
	func fetchConfig()
	func changeColors()
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	var ref: FIRDatabaseReference!
	var remoteConfig: FIRRemoteConfig!
	
	let navBarColorConfigKey = "navBar_color"
	let yellowColor = UIColor(red:1.00, green:0.76, blue:0.03, alpha:1.0)
	let blueColor = UIColor(red:0.13, green:0.59, blue:0.95, alpha:1.0)
	let purpleColor = UIColor(red:0.40, green:0.23, blue:0.72, alpha:1.0)
	
	@IBOutlet var addFloatingButton: UIButton!
	@IBOutlet var snackLabel: UILabel!
	@IBOutlet var snackCloseButton: UIButton!
	@IBOutlet var spacingSnackButton: NSLayoutConstraint!
	@IBOutlet var bottomToLayoutButton: NSLayoutConstraint!
	@IBOutlet var bottomToLayoutSnack: NSLayoutConstraint!
	@IBOutlet var tableView: UITableView!
	@IBOutlet var infoLabel: UILabel!
	
	var receipts = [Receipt]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.delegate = self
		tableView.dataSource = self
		
		// Firebase remote config
		remoteConfig = FIRRemoteConfig.remoteConfig()
		// Enable developer mode to test witout limit
		let remoteConfigSettings = FIRRemoteConfigSettings(developerModeEnabled: true)
		remoteConfig.configSettings = remoteConfigSettings!
		// Set default values
		remoteConfig.setDefaultsFromPlistFileName("RemoteConfigDefaults")
		fetchConfig()
		
		// Anonymous login
		if FIRAuth.auth()?.currentUser == nil {
			FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
				if let error = error {
					self.infoLabel.text = error.localizedDescription
					UIView.animate(withDuration: 2, delay: 0, options: .curveEaseIn, animations: {
						self.infoLabel.alpha = 1
					}, completion: { (_) in
						self.infoLabel.alpha = 0
					})
				} else {
					self.infoLabel.text = ""
				}
			})
		}
		
		// Firebase database
		ref = FIRDatabase.database().reference()
		let userID = FIRAuth.auth()?.currentUser?.uid
		let userRef = ref.child("users").child("\(userID!)")
		
		// Listen for changes in object database
		userRef.observe(.value, with: { snapshot in
			
			var newReceipts: [Receipt] = []
			
			for item in snapshot.children {
				let receipt = Receipt(snapshot: item as! FIRDataSnapshot)
				newReceipts.append(receipt)
			}
			
			self.showSnackMessage(with: "Receipts list updated.")
			
			self.receipts = newReceipts
			self.tableView.reloadData()
			
		})
		
		// Set the floating button
		addFloatingButton.layer.masksToBounds = false
		addFloatingButton.layer.shadowColor = UIColor.darkGray.cgColor
		addFloatingButton.layer.shadowRadius = 1.5
		addFloatingButton.layer.shadowOpacity = 0.5
		addFloatingButton.layer.shadowOffset = CGSize(width: 0, height: 3)
		
		// Hide Snack bar
		updateConstraintsForSnackBar(shouldShow: false)
	}
	
	func showSnackMessage(with message: String) {
		// Update snack content
		snackLabel.text = message
		
		// Display Snack
		view.layoutIfNeeded()
		UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
			self.updateConstraintsForSnackBar(shouldShow: true)
			self.view.layoutIfNeeded()
		}) { (finished) in
			UIView.animate(withDuration: 0.5, delay: 2, options: [], animations: {
				self.updateConstraintsForSnackBar(shouldShow: false)
				self.view.layoutIfNeeded()
			}, completion: nil)
		}
	}
	
	func updateConstraintsForSnackBar(shouldShow show: Bool) {
		if show {
			spacingSnackButton.constant = 10
			spacingSnackButton.priority = UILayoutPriorityDefaultHigh+1
			bottomToLayoutSnack.priority = UILayoutPriorityDefaultHigh+2
			bottomToLayoutButton.constant = 50
		} else {
			spacingSnackButton.constant = view.frame.size.height
			spacingSnackButton.priority = UILayoutPriorityDefaultHigh-1
			bottomToLayoutSnack.priority = UILayoutPriorityDefaultHigh-2
			bottomToLayoutButton.constant = 10
		}
	}

	@IBAction func add(_ sender: UIButton) {
		let picker = UIImagePickerController()
		picker.delegate = self
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			picker.sourceType = .camera
		} else {
			picker.sourceType = .photoLibrary
		}
		
		present(picker, animated: true, completion:nil)
	}
	
	@IBAction func goToSettings(_ sender: UIBarButtonItem) {
		let vc = storyboard?.instantiateViewController(withIdentifier: "settingsVC") as! SettingsTableViewController
		vc.delegate = self
		navigationController?.pushViewController(vc, animated: true)
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		dismiss(animated: true, completion: nil)
		
		// Open editor view controller
		guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else { return }
		let vc = storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditViewController
		vc.image = image
		navigationController?.pushViewController(vc, animated: true)
	}

}

extension ViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let vc = storyboard?.instantiateViewController(withIdentifier: "editVC") as! EditViewController
		vc.receipt = receipts[indexPath.row]
		navigationController?.pushViewController(vc, animated: true)
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	private func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			let receipt = receipts[indexPath.row]
			receipt.ref?.removeValue()
		}
	}
	
	
}

extension ViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return receipts.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cellID") as! CustomCell
		cell.titleLabel.text = receipts[indexPath.row].title
		cell.dateLabel.text = receipts[indexPath.row].date
		cell.valueLabel.text = "$\(String(receipts[indexPath.row].value))"
		cell.accessoryType = .disclosureIndicator
		return cell
	}
}


extension ViewController: RegionDelegate {
	func fetchConfig(){
		if remoteConfig[navBarColorConfigKey].stringValue == "yellow" {
			navigationController?.navigationBar.barTintColor = yellowColor
			addFloatingButton.setImage(UIImage(named:"addButtonYellow"), for: .normal)
			snackCloseButton.tintColor = yellowColor
		}
		else if remoteConfig[navBarColorConfigKey].stringValue == "blue" {
			navigationController?.navigationBar.barTintColor = blueColor
			addFloatingButton.setImage(UIImage(named:"addButtonBlue"), for: .normal)
			snackCloseButton.tintColor = blueColor
		}
		else if remoteConfig[navBarColorConfigKey].stringValue == "purple" {
			navigationController?.navigationBar.barTintColor = purpleColor
			addFloatingButton.setImage(UIImage(named:"addButtonPurple"), for: .normal)
			snackCloseButton.tintColor = purpleColor
		}
		var expirationDuration = 3600
		if remoteConfig.configSettings.isDeveloperModeEnabled {
			expirationDuration = 0
		}
		remoteConfig.fetch(withExpirationDuration: TimeInterval(expirationDuration)) { (status, error) -> Void in
			if status == .success {
				self.remoteConfig.activateFetched()
			} else {
				self.showSnackMessage(with: error!.localizedDescription)
				
			}
			self.changeColors()
		}
		
	}
	
	func changeColors(){
		// Get config value
		if remoteConfig[navBarColorConfigKey].stringValue == "yellow" {
			navigationController?.navigationBar.barTintColor = yellowColor
			addFloatingButton.setImage(UIImage(named:"addButtonYellow"), for: .normal)
			snackCloseButton.tintColor = yellowColor
		}
		else if remoteConfig[navBarColorConfigKey].stringValue == "blue" {
			navigationController?.navigationBar.barTintColor = blueColor
			addFloatingButton.setImage(UIImage(named:"addButtonBlue"), for: .normal)
			snackCloseButton.tintColor = blueColor
		}
		else if remoteConfig[navBarColorConfigKey].stringValue == "purple" {
			navigationController?.navigationBar.barTintColor = purpleColor
			addFloatingButton.setImage(UIImage(named:"addButtonPurple"), for: .normal)
			snackCloseButton.tintColor = purpleColor
		}
	}
}
