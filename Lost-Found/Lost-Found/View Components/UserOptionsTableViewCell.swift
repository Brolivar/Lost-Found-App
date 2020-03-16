//
//  UserOptionsTableViewCell.swift
//  Lost-Found
//
//  Created by Brolivar on 06/11/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

class UserOptionsTableViewCell: UITableViewCell {

    // MARK: - Properties
    @IBOutlet private var optionLabel: UILabel!

    // MARK: - Initialization
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    func configure(with optionName: String) {
        self.optionLabel.text = optionName
    }
}
