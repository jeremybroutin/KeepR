//
//  SettingsTableViewController.swift
//  keepr
//
//  Created by Jeremy Broutin on 12/7/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit
import Firebase

class SettingsTableViewController: UITableViewController {
	
	var delegate: RegionDelegate?
	let regions = ["US", "France", "UK"]
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return regions.count
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Select region"
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cellID")! as UITableViewCell
		cell.textLabel?.text = regions[indexPath.row]
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
		FIRAnalytics.setUserPropertyString(tableView.cellForRow(at: indexPath)?.textLabel?.text, forName: "manual_region")
		self.delegate?.fetchConfig()
	}
	
	override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
		tableView.cellForRow(at: indexPath)?.accessoryType = .none
	}
}
