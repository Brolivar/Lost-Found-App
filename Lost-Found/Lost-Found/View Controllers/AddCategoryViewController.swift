//
//  AddCategoryViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 25/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import os.log

class AddCategoryViewController: UIViewController {

    // Delegate for navigation within the screens of AddItem, using the AddItemViewController
    weak var delegate: AddItemNavigatorDelegate?
    // Delegate for communication with the AddItemVC
    weak var categorySelectedDelegate: CategorySelectedDelegate?
    @IBOutlet private var dismissView: UIView!

    // MARK: - Actions
    // Select category buttons : dismiss, go back to coordinator and inform AddItemViewController
    // of the selected category
    @IBAction func lostButtonTapped(_ sender: Any) {
        dismiss(animated: true)
        self.categorySelectedDelegate?.categorySelected(category: .lost)
    }

    @IBAction func foundButtonTapped(_ sender: Any) {
        dismiss(animated: true)
        self.categorySelectedDelegate?.categorySelected(category: .found)
    }

    @IBAction func adoptionButtonTapped(_ sender: Any) {
        dismiss(animated: true)
        self.categorySelectedDelegate?.categorySelected(category: .adoption)
    }

    // MARK: - Methods

    // Dismiss view when touching outside the view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.view == self.dismissView {
            dismiss(animated: true)
        }
    }
}
