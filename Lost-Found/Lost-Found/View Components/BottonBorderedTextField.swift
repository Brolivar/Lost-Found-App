//
//  BottonBorderedTextField.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 19/08/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import SnapKit

class BottonBorderedTextField: UITextField {

    // MARK: Properties
    var bottonBorder = UIView()

    // MARK: Initialization

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.addSubview(bottonBorder)
        bottonBorder.backgroundColor = .lightGray

        bottonBorder.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(1.0)
            make.trailing.leading.equalTo(self)
            make.bottom.equalTo(self)
        }

    }

    // MARK: Class Functions
    func setBorderBackgroundColor(colour: UIColor) {
        self.bottonBorder.backgroundColor = colour
    }

}
