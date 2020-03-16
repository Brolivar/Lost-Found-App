//
//  UserOptionsViewController.swift
//  Lost-Found
//
//  Created by Brolivar on 06/11/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

enum UserOptions: String, CaseIterable, CustomStringConvertible {
    case notifications
    case disclaimer
    case logout
    var description: String {
        switch self {
        case .notifications: return "Notifications"
        case .logout: return "Logout"
        case .disclaimer: return "Disclaimer"
        }
    }
}

class UserOptionsViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet var userOptionsTableView: UITableView!

    // Delegate for navigation within the screens of AccDetails
    weak var delegate: AccountDetailsCoordinator?
    var userManagerProtocol: UserManagerProtocol!
    private var listOfOptions: [String] = []

    // MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()

        for option in UserOptions.allCases {
            listOfOptions.append(option.description)
        }

        self.userOptionsTableView.delegate = self
        self.userOptionsTableView.dataSource = self
    }
    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Methods

    func logoutUser() {
        if self.userManagerProtocol.userLogged() {
            self.userManagerProtocol.signOutUser()
            self.showCustomAlertMessage(message: "Signed out successfully", type: .success)
            self.dismiss(animated: true, completion: {
                self.delegate?.navigateBackToTimeline()
            })
        } else {
            self.showCustomAlertMessage(message: "You are not signed up", type: .error)
        }
    }
}

// MARK: - UITableViewDelegate extension
extension UserOptionsViewController: UITableViewDelegate {
}

// MARK: - UITableViewDataSource extension
extension UserOptionsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.listOfOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OptionCell", for: indexPath) as?
            UserOptionsTableViewCell
        else {
             print("The dequeued cell is not an instance of UserOptionsTableViewCell.")
             return UITableViewCell()
        }
        // Configure cell
        let selectedItem = self.listOfOptions[indexPath.row]
        cell.configure(with: selectedItem)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = self.listOfOptions[indexPath.row]

        if selectedItem == "Logout" {
            print("Login out...")
            self.logoutUser()
        }
    }
}
