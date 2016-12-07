//
//  Receipt.swift
//  keepr
//
//  Created by Jeremy Broutin on 12/6/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import Firebase

struct Receipt {
	
	let key: String
	var title: String!
	var date: String!
	var value: Double!
	var photoURL: String!
	var ref: FIRDatabaseReference?
	
	init(title: String, date: String, value: Double, photoURL: String, key: String = "") {
		self.key = key
		self.title = title
		self.date = date
		self.value = value
		self.photoURL = photoURL
		self.ref = nil
	}
	
	init(snapshot: FIRDataSnapshot) {
		key = snapshot.key
		let snapshotValue = snapshot.value as! [String: AnyObject]
		title = snapshotValue["title"] as! String
		value = snapshotValue["value"] as! Double
		/**
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd"
		date = dateFormatter.date(from: snapshotValue["date"] as! String) as NSDate!
		**/
		date = snapshotValue["date"] as! String
		photoURL = snapshotValue["photoURL"] as! String
		ref = snapshot.ref
	}
	
}
