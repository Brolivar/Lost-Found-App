//
//  AddImageCollectionViewCell.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 07/08/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

class AddImageCollectionViewCell: UICollectionViewCell {

    // MARK: Properties
    @IBOutlet private var selectedImage: UIImageView!

    func setSelectedImage(selectedImg: UIImage) {
        self.selectedImage.image = selectedImg
    }

}
