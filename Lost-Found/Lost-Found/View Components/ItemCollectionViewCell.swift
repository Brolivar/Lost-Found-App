//
//  ItemCollectionViewCell.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 10/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import Kingfisher

class ItemCollectionViewCell: UICollectionViewCell {

    // MARK: Properties

    @IBOutlet private var itemImage: UIImageView!
    @IBOutlet private var itemNameLabel: UILabel!
    @IBOutlet var itemActivityIndicator: UIActivityIndicatorView!

    // MARK: Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func configure(with item: Item?) {

        self.itemImage.kf.indicatorType = .activity
        self.itemImage.layer.cornerRadius = 5
        self.itemImage.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        if let item = item {
            self.itemNameLabel.text = item.name
            self.itemImage.kf.setImage(with: item.itemThumbnail)
            self.itemNameLabel.alpha = 1
            self.itemActivityIndicator.stopAnimating()
            self.itemActivityIndicator.hide()
            self.itemActivityIndicator.alpha = 0
        } else {
            self.itemNameLabel.alpha = 0
            self.itemActivityIndicator.startAnimating()
        }
    }

}
