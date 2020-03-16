//
//  ItemManagerModelController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 03/03/2020.
//  Copyright © 2020 Jose Bolivar Herrera. All rights reserved.
//

/*

ItemManager ModelController: this MC is used to add new items to the system, as
 well as the processes involved on it
 
 */
import Foundation
import UIKit

// Manages reading and writing of items, and its attributes
protocol ItemManagerProtocol {

    func selectedImagesCount() -> Int
    //swiftlint:disable:next function_parameter_count
    func createItem(name: String, itemImages: [UIImage], itemDetails: String, itemCategory: ItemCategories,
                    itemSubcategory: ItemSubCategories, itemLongitude: Double, itemLatitude: Double,
                    completion: @escaping () -> Void)
    func removeItem(at index: Int)
    func removeAllItems()
    func numberOfSelectedImages() -> Int
    func addSelectedImage(selectedImg: UIImage)
    func removeSelectedImage(at index: Int)
    func removeAllSelectedImages()
    func updateSelectedImage(selectedImg: UIImage, at index: Int)
    func getSelectedImage(at index: Int) -> UIImage
    func getAllSelectedImages() -> [UIImage]
//    func setThumbnailPage(from thumbnails: [String?: URL?])
}

class ItemManagerModelController {

    // MARK: - Properties
    private weak var fetchDelegate: ItemModelFetchDelegate?
    private var itemData: ItemData  // Reference to the Database handler class
    private var items: [Item] = []  // Array of items displayed
    // Number of Thumbnails currently displayed: used to calculate the index to be reloaded
    private var numberOfThumbnails: Int = 0

    // Reference to the userMC, mainly to obtain if there is a userLogged, and get its ID
    private var userModelController: UserModelController

    // All images present in the CollectionView in the Add Item View
    private var selectedImages: [UIImage] = []

    // Collection View Pagination
    // We have one bigger pagination for the item's lighter data (description, name, ...)
    // and another for the item's heavier data (images)
    private static let itemRefillThreshhold = 25
    private static let thumbnailRefillThreshhold = 10

    private var currentItemPage = 0
    private var currentThumbnailPage = 0

    // Location
    // We need various versions of the array with item IDS,
    // 1. One version that contains all original items in radius
    // 2. One changing version to make the pagination
    // 3. Three to keep the filtered versions (because its not the same doing a search in the original
    // set of items, that first enable a category filter, and then searching in that filtered subset
    private var itemIDsWithinRadius: [String] = []
    private var paginatedItemIDsInRadius: [String] = []
    // Filtered versions (these copies will allow us to optimize the number of fetches to the db
    private var filteredByCategoryItemIDs: [String] = []
    private var filteredBySearchItemIDs: [String] = []

    private var totalItems = 0
    private var isItemFetchInProgress = false
    private var isThumbnailFetchInProgress = false

    // MARK: - Initialization
    init(userMC: UserModelController, itemsData: ItemData) {
        self.userModelController = userMC
        self.itemData = itemsData
    }
}

// MARK: - ItemDisplayer Protocol
// Manages the write and reading of Items, and item attributes
extension ItemManagerModelController: ItemManagerProtocol {

    // Returns the number of items
    func selectedImagesCount() -> Int {
        return self.selectedImages.count
    }

    // Creates new item
    //swiftlint:disable:next function_parameter_count
    func createItem(name: String, itemImages: [UIImage], itemDetails: String, itemCategory: ItemCategories,
                    itemSubcategory: ItemSubCategories, itemLongitude: Double, itemLatitude: Double,
                    completion: @escaping () -> Void) {

        // Once we create an item, we generate its id composed by the user that created it + timestamp
        let uid = self.userModelController.getUserID()

        // We use one formatter to form the item ID (uses date's seconds)
        // and another to the items's dateOfCreation
        let now = Date()
        let formatter = DateFormatter()

        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMddHHmmss"

        let dateString = formatter.string(from: now)

        let itemID = uid + dateString

        //
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "HH-mm-dd-MM-yyyy"
        let dateOfCreation = dateFormatter.string(from: now)

        // Thumbnail compressed with less quality
        let thumbnailData = itemImages[0].jpegData(compressionQuality: 0.25)

        // Rest of the Item Images are saved normally (because they won't be downloaded until
        // accessing the item
        var itemImagesData: [Data] = []
        for child in itemImages {
            let imageData = child.jpegData(compressionQuality: 0.75)
            itemImagesData.append(imageData!)
        }

        let createdByUserID = self.userModelController.getUserID()

        // Now we have the thumbnailURL, we create the item
        guard let newItem = Item(itemID: itemID, name: name, thumbnail: .none,
                                 itemDetails: itemDetails,
                                 itemCategory: itemCategory, itemSubcategory: itemSubcategory,
                                 itemLongitude: itemLongitude, itemLatitude: itemLatitude,
                                 createdBy: createdByUserID, dateOfCreation: dateOfCreation)
            else {
                print("Failed to instantiate new item")
                return
        }
        print("New item image saved properly as URL")
        self.itemData.storeImages(itemID: itemID, imageData: itemImagesData)
        self.itemData.saveItem(newItem: newItem)

        self.itemData.storeThumbnail(itemID: itemID, imageData: thumbnailData!, completion: {
           // self.items.append(newItem)
            completion()
        })

    }
    // MARK: - Item Getters/Setters/Removers
    // Removes item from the Array
    func removeItem(at index: Int) {
        items.remove(at: index)
    }

    // Removes all items from the Array
    func removeAllItems() {
        self.items.removeAll()
    }

    // Adds a NEW Image to the array
    func addSelectedImage(selectedImg: UIImage) {
        selectedImages.append(selectedImg)
    }

    func numberOfSelectedImages() -> Int {
        return selectedImages.count
    }

    // UPDATES the current selected image of the array
    func updateSelectedImage(selectedImg: UIImage, at index: Int) {
        self.selectedImages[index] = selectedImg
    }

    // Removes the imaged added by the user
    func removeSelectedImage(at index: Int) {
        self.selectedImages.remove(at: index)
    }

    func removeAllSelectedImages() {
        self.selectedImages.removeAll()
    }

    func getSelectedImage(at index: Int) -> UIImage {
        return selectedImages[index]
    }

    func getAllSelectedImages() -> [UIImage] {
        return self.selectedImages
    }

//    // for each pair of ITEMID - URL retrieved from DB, sets each URL to its item object
//    func setThumbnailPage(from thumbnails: [String?: URL?]) {
//        for (keyItemID, thumbnailURL) in thumbnails {
//            // If the id of the url match the item && the item doesn't have thumbnail set
//            // (avoid the error when an image is retrieved twice)
//            for item in self.items where item.itemID == keyItemID && item.itemThumbnail == .none {
//                item.setThumbnail(newThumbnail: thumbnailURL)
//                self.numberOfThumbnails += 1
//            }
//        }
//    }
}
