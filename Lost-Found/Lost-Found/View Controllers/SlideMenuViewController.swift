//
//  SlideMenuViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 24/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

class SlideMenuViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: SlideMenuCoordinator?

    var userManagerProtocol: UserManagerProtocol!

    // UI Labels that change depending of the user auth state
    @IBOutlet private var userTextLabel: UILabel!
    @IBOutlet private var lowerTextLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.userManagerProtocol.userLogged() {
            self.userTextLabel.text = self.userManagerProtocol.getUsername()
            self.userTextLabel.font = UIFont.systemFont(ofSize: 22.0)
            self.lowerTextLabel.text = "Go to profile"
            self.lowerTextLabel.font = UIFont.italicSystemFont(ofSize: 16.0)
        }
    }

    // Empty the child[] slot with the SlideMenuViewController in the MainCoordinator
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.didCloseMenu()
    }

    // Call the coordinator to present the login Screen
    // If the user is logged -> go to account details\
    // If not -> go to loggin screen
    @IBAction func loginButtonTapped(_ sender: Any) {

        if self.userManagerProtocol.userLogged() {
            delegate?.displayAccountDetailsView()
        } else {
            delegate?.displaySignScreen()
        }
    }

    // To be deleted in the future from here: kept in menu just for testing
    @IBAction func signOutButton(_ sender: Any) {
        if self.userManagerProtocol.userLogged() {
            self.userManagerProtocol.signOutUser()
            self.showCustomAlertMessage(message: "Signed out successfully", type: .success)
            self.delegate?.dismissMenu()
        } else {
            self.showCustomAlertMessage(message: "You are not signed up", type: .error)
        }
    }

}
