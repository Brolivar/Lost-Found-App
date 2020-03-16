//
//  LoginViewController.swift
//  Lost-Found
//
//  Created by Brolivar on 21/08/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import GoogleSignIn
import FacebookLogin
import Firebase

class SignScreenViewController: UIViewController {

    // MARK: Properties
    weak var delegate: LoginCoordinator?
    var facebookloginButton: FBLoginButton = FBLoginButton()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure Google login APIs
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self

        // Configure FB login
        facebookloginButton.permissions = ["email", "public_profile"]
        facebookloginButton.delegate = self
    }

    // MARK: - Actions

    @IBAction func cancelButtonTapped(_ sender: Any) {
        self.delegate?.didCloseSignScreen()
    }

    // Call the Coordinator to navigate to the register with mail screen
    @IBAction func mailRegisterButtonTapped(_ sender: Any) {
        self.delegate?.goToMailRegisterScreen()
    }

    // Navigate to the login screen
    @IBAction func mailLoginButtonTapped(_ sender: Any) {
        self.delegate?.goToMailLoginScreen()
    }

    // Google login
    @IBAction func googleLoginButtonTapped(_ sender: Any) {
        print("Google login..")

        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().signIn()
    }

    // Facebook login
    @IBAction func facebookLoginButtonTapped(_ sender: Any) {
        // We use our custom button, so we trigger the event this way
        self.facebookloginButton.sendActions(for: .touchUpInside)
    }
}

// MARK: - GIDSignInDelegate Delegate
extension SignScreenViewController: GIDSignInDelegate {

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {

        if let error = error {
            print("Login error with Google: ", error.localizedDescription)
            return
        }

        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                        accessToken: authentication.accessToken)

        // After receiving the credentials, we login into the system
        self.showHUD()
        self.delegate?.loginWithCredentials(with: credential,
            loginResponse: { loginStatus in

                DispatchQueue.main.async {
                    self.hideHUD()

                    if loginStatus == .loginValid {
                        self.showCustomAlertMessage(message: "Login Successful",
                                                    type: .success)

                        // We store rest of the info in the server
                        let username = user.profile.givenName
                        let email = user.profile.email

                        if email != nil {
                            // TODO: Develop a way to theck if the user with the mail has already an account
                            // so in case he do, not override his username, and more importantly
                            // HIS OWNED ITEMS
                            // or just make the query to modify the username
                            //self.delegate?.storeGoogleCredentiales(name: username ?? "", mail: email!)
                            self.delegate?.goBackToTimeline()
                            return
                        } else {
                            print("Error getting google credentials")
                            self.delegate?.goBackToTimeline()
                            return
                        }

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
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
    }

}

// MARK: - LoginButtonDelegate Delegate
extension SignScreenViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
    }

    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {

        if let error = error {
            print("Error: Facebook login returned with error: ", error.localizedDescription)
            return
        }

        if AccessToken.current?.tokenString != nil {
            let credential = FacebookAuthProvider.credential(withAccessToken: AccessToken.current!.tokenString)

            // After receiving the credentials, we login into the system
            self.showHUD()
            self.delegate?.loginWithCredentials(with: credential,
                loginResponse: { loginStatus in

                    DispatchQueue.main.async {
                        self.hideHUD()

                        if loginStatus == .loginValid {
                            self.showCustomAlertMessage(message: "Login Successful",
                                                        type: .success)
                            // Still missing the same
                            // process as google login:
                            // If new user -> store fb username as username and mail
                            // If already registered -> just retrieve stored details
                            self.delegate?.goBackToTimeline()
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
        } else {
            print("Error: Facebook login token invalid.")
            return
        }

    }

}
