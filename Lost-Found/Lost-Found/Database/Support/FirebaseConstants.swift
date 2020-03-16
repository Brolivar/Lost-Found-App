//
//  FirebaseConstants.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 08/10/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

struct FirebasePath {

    enum Items: String {
        case itemsLocation = ""
        func path() -> String {
            return "items/" + self.rawValue
        }
    }

    enum Users: String {
        case users
        func path() -> String {
            return self.rawValue
        }
    }

    // Firebase Storage for images/videos
    enum ItemStorage: String {
        case itemsStorageLocation = "Items/"
        case itemImages = "images/"

        func path() -> String {
            return self.rawValue
        }
    }

    enum Geolocation: String {
        case itemGeoLocation = "geolocs/"
        func path() -> String {
            return self.rawValue
        }
    }
}

struct FirebaseParams {

    struct Items {
        static let itemID = "itemID"
        static let itemCategory = "itemCategory"
        static let itemSubcategory = "itemSubcategory"
        static let name = "name"
        static let itemDetails = "itemDetails"
        static let createdBy = "createdBy"
        static let dateOfCreation = "dateOfCreation"
    }

    struct Login {
        static let email = "email"
        static let userID = "userID"
        static let username = "username"
        static let itemsCreated = "itemsCreated"
    }
}
