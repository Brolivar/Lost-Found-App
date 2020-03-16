//
//  UserModelController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 24/09/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import Foundation
import CoreLocation

// Protocol that will be used for reading the user info
protocol UserDisplayerProtocol: class {
    func userLogged() -> Bool
    func getUsername() -> String
    func getUserID() -> String
    func getCurrentUserLatitude() -> Double?
    func getCurrentUserLongitude() -> Double?
    func getMaxLocationRadius() -> Int
    func getUsernameByID(userID: String, completion: @escaping (String) -> Void)
}

// Protocol that will be used for reading/or writing user info
protocol UserManagerProtocol: UserDisplayerProtocol {
    func signOutUser()
    func updateLoggedUser(completion: @escaping () -> Void)
    func setCurrentLocation(userLatitude: Double, userLongitude: Double)
    func setMaxLocationRadius(newRadius: Int)
}

class UserModelController {

    // MARK: - Properties
//    private var userInfo: User?
    private var accountManager: AccountManager
    //private let locationManager: CLLocationManager

    // location
    private var currentUserLatitude: Double?
    private var currentUserLongitude: Double?
    // Max radius for item retrieval (20km)
    private var maxLocationRadius: Int = 20

    init(accManager: AccountManager) {
        self.accountManager = accManager
    }
}

// MARK: - UserDisplayerProtocol
extension UserModelController: UserDisplayerProtocol {

    func userLogged() -> Bool {
        return self.accountManager.userLogged()
    }
    func getUsername() -> String {
        return self.accountManager.getUserName()
    }
    func getUserID() -> String {
        return self.accountManager.getCurrentUserID()
    }

    func getCurrentUserLatitude() -> Double? {
        return self.currentUserLatitude
    }

    func getCurrentUserLongitude() -> Double? {
        return self.currentUserLongitude
    }

    func getMaxLocationRadius() -> Int {
        return self.maxLocationRadius
    }

    func getUsernameByID(userID: String, completion: @escaping (String) -> Void) {
        self.accountManager.retrieveUsernameByID(userID: userID, completionHandler: { username in
            completion(username)
        })
    }

}

// MARK: - UserManagerProtocol
extension UserModelController: UserManagerProtocol {

    func signOutUser() {
        self.accountManager.signOutUser()
    }

    func updateLoggedUser(completion: @escaping () -> Void) {
        self.accountManager.updateLoggedUser(completionHandler: {
            completion()
        })
    }

    func setCurrentLocation(userLatitude: Double, userLongitude: Double) {
        self.currentUserLatitude = userLatitude
        self.currentUserLongitude = userLongitude
    }

    func setMaxLocationRadius(newRadius: Int) {
        self.maxLocationRadius = newRadius
    }

}
