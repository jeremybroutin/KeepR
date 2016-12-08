//
//  EditViewController.swift
//  keepr
//
//  Created by Jeremy Broutin on 12/6/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit
import Firebase

class EditViewController: UIViewController, UITextFieldDelegate {
	
	var ref: FIRDatabaseReference!
	var storage: FIRStorage!
	var storageRef: FIRStorageReference!
	
	var image: UIImage!
	var delegate: SnackBarDelegate!
	var receipt: Receipt!
	var isNew: Bool = true
	
	@IBOutlet weak var bannerView: GADBannerView!
	@IBOutlet var imageView: UIImageView!
	@IBOutlet var titleTxtField: UITextField!
	@IBOutlet var valueTxtField: UITextField!
	@IBOutlet var dateLabel: UILabel!
	@IBOutlet var userInfoLabel: UILabel!
	@IBOutlet var saveButton: UIBarButtonItem!
	@IBOutlet var snackLabel: UILabel!
	
	@IBOutlet var spaceSnackToView: NSLayoutConstraint!
	@IBOutlet var BottomToView: NSLayoutConstraint!
	@IBOutlet var BottomToSnack: NSLayoutConstraint!
	// MARK: - App Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		ref = FIRDatabase.database().reference()
		storage = FIRStorage.storage()
		storageRef = storage.reference(forURL: "gs://keepr-50442.appspot.com")
		
		// Firebase AdMob
		
		// bannerView.adUnitID = "ca-app-pub-9663491524442751/3415003821"
		// test id below
		bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
		bannerView.rootViewController = self
		bannerView.load(GADRequest())
		
		titleTxtField.delegate = self
		valueTxtField.delegate = self
		
		// Set UI for creation of new receipt or edition of existing one
		
		if let image = image {
			imageView.image = image
			let dateFormatter = DateFormatter()
			dateFormatter.dateStyle = .medium
			dateLabel.text = " \(dateFormatter.string(from: NSDate() as Date))"
		}
		else if let receipt = receipt {
				
				// set the appropriate flag
				isNew = false
				
				// add receipt info
				titleTxtField.text = receipt.title
				valueTxtField.text = String(receipt.value)
				dateLabel.text = receipt.date
				
				// download image from Firebase
				let userStorageRef = storageRef.child(receipt.photoURL)
				downloadImage(userStorageRef: userStorageRef)
		}
		
		// Tap gesture recognizer to hide keyboard
		
		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(EditViewController.hideKeyboard))
		tapGesture.cancelsTouchesInView = true
		view.addGestureRecognizer(tapGesture)
		
		// Notifications for keyboard display
		NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(EditViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
		
		// Hide snackbar
		self.delegate.updateConstraintsForSnackBar(shouldShow: false, spacingCons: spaceSnackToView, snackToBottom: BottomToSnack, viewToBottom: BottomToView)
	}
	
	// MARK: - IBActions
	
	@IBAction func save(_ sender: UIBarButtonItem) {
		if isNew {
			createNewFirebaseObject()
		} else {
			updateFirebaseObject(receipt: receipt)
		}
		let _ = navigationController?.popViewController(animated: true)
	}
	
	
	@IBAction func cancel(_ sender: UIBarButtonItem) {
		let _ = navigationController?.popViewController(animated: true)
	}
	
	// MARK: - Textfield delegate methods
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		if !(titleTxtField.text?.isEmpty)! && !(valueTxtField.text?.isEmpty)! {
			saveButton.isEnabled = true
		}
	}
	
	// MARK: - Deal with Keyboard
	
	// hide action for tap gesture recognizer
	func hideKeyboard() {
		view.endEditing(true)
	}
	
	// move view up when keyboard is displayed
	func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			// static value 64 for frame origin
			// TODO: should be calculated dynamically
			if self.view.frame.origin.y == 64.0{
				self.view.frame.origin.y -= keyboardSize.height
			}
		}
	}
	
	// move view back down when keyboard is dismissed
	func keyboardWillHide(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			if self.view.frame.origin.y != 64.0{
				self.view.frame.origin.y += keyboardSize.height
			}
		}
	}
	
	// MARK: - Firebase Storage Helpers
	
	func downloadImage(userStorageRef: FIRStorageReference) {
		userStorageRef.data(withMaxSize: 2*1024*1024) { (data, error) -> Void in
			if let error = error {
				self.showSnackMessage(with: error.localizedDescription, inLabel: self.snackLabel)
			} else {
				if let data = data {
					self.imageView.image = UIImage(data: data)
				} else {
					self.showSnackMessage(with: "No image data found.", inLabel: self.snackLabel)
				}
			}
		}
		
	}
	
	// MARK: - Firebase Database Helpers
	
	func createNewFirebaseObject() {
		// Prepare Receipt object
		let photoURL = FIRAuth.auth()!.currentUser!.uid + "/\(Int(Date.timeIntervalSinceReferenceDate)).jpg"
		
		guard let title = titleTxtField.text, title != titleTxtField.placeholder && !title.isEmpty else {
			delegate.showSnackMessage(with: "Please add a title to your receipt.", inLabel: snackLabel)
			return
		}
		guard let value = Double(valueTxtField.text!) else {
			delegate.showSnackMessage(with: "Please add a value to your receipt.", inLabel: snackLabel)
			return
		}
		guard let date = dateLabel.text else { return }
		guard let imageData = UIImageJPEGRepresentation(image, 0.8) else { return }
		
		// Save receipt image file to storage (in user_id/ top directory)
		
		let metadata = FIRStorageMetadata()
		metadata.contentType = "image/jpeg"
		self.storageRef.child(photoURL)
			.put(imageData, metadata: metadata) { (metadata, error) in
				if let error = error {
					print("Error uploading: \(error)")
					self.showSnackMessage(with: "Upload to database failed.", inLabel: self.snackLabel)
					DispatchQueue.main.async {
						FIRAnalytics.logEvent(withName: "store_receipt_failed", parameters: nil)
					}
					return
				}
				
				// Save receipt info in dict to database (users/user_id/key:dict)
				
				let userID = FIRAuth.auth()?.currentUser?.uid
				let key = self.ref.child("users").childByAutoId().key
				let receipt: [String:Any] = [
					"title": title,
					"value": value,
					"date": date,
					"photoURL": photoURL
				]
				let childUpdates = ["/users/\(userID!)/\(key)/": receipt]
				self.ref.updateChildValues(childUpdates)
				
				DispatchQueue.main.async {
					FIRAnalytics.logEvent(withName: "store_receipt_success", parameters: nil)
				}
		}
	}
	
	func updateFirebaseObject(receipt: Receipt){
		let userID = FIRAuth.auth()?.currentUser?.uid
		let key = receipt.key
		
		guard let title = titleTxtField.text, title != titleTxtField.placeholder && !title.isEmpty else {
			showSnackMessage(with: "Please add a title to your receipt.", inLabel: snackLabel)
			return
		}
		guard let value = Double(valueTxtField.text!) else {
			showSnackMessage(with: "Please add a value to your receipt.", inLabel: snackLabel)
			return
		}
		guard let date = dateLabel.text else { return }
		
		let updatedReceipt: [String:Any] = [
			"title": title,
			"value": value,
			"date": date,
			"photoURL": receipt.photoURL
		]
		let childUpdates = ["/users/\(userID!)/\(key)/": updatedReceipt]
		self.ref.updateChildValues(childUpdates)
		FIRAnalytics.logEvent(withName: "update_receipt", parameters: nil)
	}
	
	// MARK: - SnackBar
	
	func showSnackMessage(with message: String, inLabel label: UILabel) {
		// Update snack content
		label.text = message
		
		// Display Snack
		view.layoutIfNeeded()
		UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
			self.delegate.updateConstraintsForSnackBar(shouldShow: true, spacingCons: self.spaceSnackToView, snackToBottom: self.BottomToSnack, viewToBottom: self.BottomToView)
			self.view.layoutIfNeeded()
		}) { (finished) in
			UIView.animate(withDuration: 0.5, delay: 1.5, options: [], animations: {
				self.delegate.updateConstraintsForSnackBar(shouldShow: false, spacingCons: self.spaceSnackToView, snackToBottom: self.BottomToSnack, viewToBottom: self.BottomToView)
				self.view.layoutIfNeeded()
			}, completion: nil)
		}
	}
}
