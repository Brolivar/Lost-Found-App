//
//  Item.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 15/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

// Enum for storing the type of the item:
// lost -> An item that has been lost
// found -> An item that has been found
// adoption -> A pet looking for an owner

import Foundation

enum ItemCategories: String {
    case lost
    case found
    case adoption
}

enum ItemSubCategories: String, CaseIterable, CustomStringConvertible {
    case accessories
    case clothing
    case phones
    case computers
    case keysObject
    case vehicles
    case soundAudio
    case documentation
    case pets
    case people
    case others

    var description: String {
        switch self {
        case .accessories:
            return "Accessories"
        case .clothing:
            return "Clothing"
        case .phones:
            return "Phones"
        case .computers:
            return "Computers"
        case .keysObject:
            return "Keys"
        case .vehicles:
            return "Vehicles"
        case .soundAudio:
            return "Sound Audio"
        case .documentation:
            return "Documentation"
        case .pets:
            return "Pets"
        case .people:
            return "People"
        case .others:
            return "Others"
        }
    }
    var imageName: String {
        switch self {
        case .accessories:
            return "accessoriesSubC"
        case .clothing:
            return "clothingSubC"
        case .phones:
            return "phonesSubC"
        case .computers:
            return "computersSubC"
        case .keysObject:
            return "keysSubC"
        case .vehicles:
            return "vehiclesSubC"
        case .soundAudio:
            return "soundAudioSubC"
        case .documentation:
            return "documentationSubC"
        case .pets:
            return "petSubC"
        case .people:
            return "peopleSubC"
        case .others:
            return "othersSubC"
        }
    }

}

class Item {

    // MARK: - Properties
    var itemID: String
    var name: String
    var itemDetails: String     // Description of the Item
    var createdBy: String       // ID of the user that created the item
    var dateOfCreation: String

    var itemThumbnail: URL?          // Thumbnail image
    var itemImages: [URL] = []
    var itemCategory: ItemCategories        //  Lost, Found or Adoption
    var itemSubCategory: ItemSubCategories

    // Location
    var itemLatitude: Double
    var itemLongitude: Double

    // MARK: Initialization

    init?(itemID: String, name: String, thumbnail: URL?, itemDetails: String,
          itemCategory: ItemCategories, itemSubcategory: ItemSubCategories,
          itemLongitude: Double, itemLatitude: Double, createdBy: String,
          dateOfCreation: String) {

        // The name must not be empty
        guard !name.isEmpty else {
            return nil
        }

        // The itemDetails must not be empty
        guard !itemDetails.isEmpty else {
            return nil
        }

        self.itemID = itemID
        self.createdBy = createdBy
        self.dateOfCreation = dateOfCreation

        //Initialize stored properties
        self.name = name
        self.itemDetails = itemDetails
        self.itemThumbnail = thumbnail
        self.itemCategory = itemCategory
        self.itemSubCategory = itemSubcategory
        self.itemLongitude = itemLongitude
        self.itemLatitude = itemLatitude
    }

    func setThumbnail (newThumbnail: URL?) {
        self.itemThumbnail = newThumbnail
    }

    // Helper function to turn Item into Dictionary, to store in DB
    func toAnyObject() -> Any {
        return [
            "name": name,
            "itemDetails": itemDetails,
            "itemCategory": itemCategory.rawValue,
            "itemSubcategory": itemSubCategory.rawValue,
            "itemID": itemID,
            "createdBy": createdBy,
            "dateOfCreation": dateOfCreation
        ]
    }
}
