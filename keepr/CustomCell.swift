//
//  CustomCell.swift
//  keepr
//
//  Created by Jeremy Broutin on 12/7/16.
//  Copyright © 2016 Jeremy Broutin. All rights reserved.
//

import UIKit

class CustomCell: UITableViewCell {
	
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var dateLabel: UILabel!
	@IBOutlet var valueLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
	
}
