//
//  SelectCategoryViewCell.swift
//  Lost-Found
//
//  Created by Brolivar on 04/11/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

class SelectCategoryViewCell: UICollectionViewCell {

    // MARK: - Properties

    @IBOutlet var subcategoryImage: UIImageView!
    @IBOutlet var subcategoryLabel: UILabel!

    // MARK: - Initialization
    func configure(with subcategoryName: ItemSubCategories) {
//
        self.subcategoryLabel.text = subcategoryName.description
        self.subcategoryImage.image = UIImage(named: subcategoryName.imageName)
    }
}
