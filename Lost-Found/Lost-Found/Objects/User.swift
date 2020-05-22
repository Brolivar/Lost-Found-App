//
//  User.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 23/09/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import Foundation

// Object that will contain the current logged user data
// that will be EVENTUALLY retrieved using a User Model Controller
class User {

    // MARK: - Properties

    var userID: String
    var username: String
    var email: String

    init(usId: String, uName: String, uMail: String) {
        self.userID = usId
        self.username = uName
        self.email = uMail
    }

    // Helper function to turn User into Dictionary, to store in DB
    func toAnyObject() -> Any {
        return [
            "userID": self.userID,
            "username": self.username,
            "email": self.email
        ]
    }
}
