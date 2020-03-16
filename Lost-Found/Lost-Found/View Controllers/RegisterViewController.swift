//
//  RegisterViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 23/08/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: LoginCoordinator?
    // UI Fields
    @IBOutlet private var userName: BottonBorderedTextField!
    @IBOutlet private var userEmail: BottonBorderedTextField!
    @IBOutlet private var userPassword: BottonBorderedTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // UI Textfield Placeholder color
        userName.attributedPlaceholder = NSAttributedString(string: "Username",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        userEmail.attributedPlaceholder = NSAttributedString(string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        userPassword.attributedPlaceholder = NSAttributedString(string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    // MARK: - Class Methods

    func checkRegisterFormParameters() -> Bool {

        var isFormComplete: Bool = true
        // Check password has at least 8 character
        var isPasswordSecure: Bool = true

        // User Name
        if let newUserName = self.userName.text, !newUserName.isEmpty {
            self.userName.setBorderBackgroundColor(colour: UIColor.lightGray)
        } else {
            print("Error: User Name required")
            self.userName.setBorderBackgroundColor(colour: UIColor.red)
            isFormComplete = false
        }

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
            if newUserPassword.count >= 8 {
                self.userPassword.setBorderBackgroundColor(colour: UIColor.lightGray)
            } else {
                isPasswordSecure = false
            }

        } else {
            print("Error: User Password required")
            self.userPassword.setBorderBackgroundColor(colour: UIColor.red)
            isFormComplete = false
        }

        if !isFormComplete {
            print("Woops! You missed a required argument")
            self.showCustomAlertMessage(message: "There are required fields empty.", type: .error)
            return false
        }
        if !isPasswordSecure {
            print("Password must be at least 8 character long")
            self.showCustomAlertMessage(message: "The password must contain at least 8 characters.", type: .error)
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

    @IBAction func registerButtonTapped(_ sender: Any) {

        if checkRegisterFormParameters() {

            //        TEST
            //        let user = "joseprueba"
            //        let userPass = "123321321"
            //        let userMail = "jose321@gmail.com"

            self.showHUD()
            self.delegate?.signUp(with: self.userName.text!,
                                  mail: self.userEmail.text!,
                                  password: self.userPassword.text!,
                                  loginResponse: { loginStatus in

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
                        self.showCustomAlertMessage(message: "Error creating the user",
                                                    type: .error)
                    } else if loginStatus == .emailInUse {
                        self.showCustomAlertMessage(message: "Error: Email in use",
                                                    type: .error)
                    }

                }
            })

        }

    }

}

// MARK: UITextFieldDelegate extension
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
}
