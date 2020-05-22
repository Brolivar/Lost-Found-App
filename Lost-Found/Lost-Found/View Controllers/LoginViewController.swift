//
//  LoginViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 23/08/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: LoginCoordinator?

    @IBOutlet private var userEmail: BottonBorderedTextField!
    @IBOutlet var userPassword: BottonBorderedTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
  // UI Textfield Placeholder color
      userEmail.attributedPlaceholder = NSAttributedString(string: "Email",
          attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
      userPassword.attributedPlaceholder = NSAttributedString(string: "Password",
          attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    // MARK: - Class Methods

    func checkLoginFormParameters() -> Bool {
        var isFormComplete: Bool = true

        // User Email
        if let newUserEmail = self.userEmail.text, !newUserEmail.isEmpty {
            self.userEmail.setBorderBackgroundColor(colour: UIColor.lightGray)
        } else {
            print("Error: User Email required")
            self.userEmail.setBorderBackgroundColor(colour: UIColor.red)
            isFormComplete = false
        }

        // User Password
        if let newUserPassword = self.userPassword.text, !newUserPassword.isEmpty {
            self.userPassword.setBorderBackgroundColor(colour: UIColor.lightGray)
        } else {
            print("Error: User Password required")
            self.userPassword.setBorderBackgroundColor(colour: UIColor.red)
            isFormComplete = false
        }

        if !isFormComplete {
            print("Woops! You missed a required argument")
            self.showCustomAlertMessage(message: "There are required fields empty.",
                                        type: .error)
            return false
        }
        return true
    }

    // MARK: - Actions

    @IBAction func backButtonTapped(_ sender: Any) {
        // Close Keyboard before moving on
        self.view.endEditing(true)
        self.delegate?.goBackToLoginScreen()
    }

    @IBAction func loginButtonTapped(_ sender: Any) {

        if checkLoginFormParameters() {

            self.showHUD()
            self.delegate?.login(with: self.userEmail.text!,
                                 password: self.userPassword.text!, loginResponse: { loginStatus in

                    DispatchQueue.main.async {
                        self.hideHUD()

                        if loginStatus == .loginValid {
                            self.showCustomAlertMessage(message: "Login Successful",
                                                        type: .success)
                            self.delegate?.goBackToTimeline()
                            return

                        } else if loginStatus == .invalidEmail {
                            self.showCustomAlertMessage(message: "Error: Invalid Email",
                                                        type: .error)
                        } else if loginStatus == .loginError {
                            self.showCustomAlertMessage(message: "Error: Invalid Credentials",
                                                        type: .error)
                        } else if loginStatus == .wrongPassword {
                            self.showCustomAlertMessage(message: "Error: Wrong password",
                                                        type: .error)
                        }
                    }
            })
        }   // if

    }

}

// MARK: UITextFieldDelegate extension
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
}
