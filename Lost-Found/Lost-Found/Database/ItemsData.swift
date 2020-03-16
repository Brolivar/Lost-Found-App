//
//  ItemsData.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 20/08/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import Firebase
import Foundation
import GeoFire

class ItemData {

    // MARK: - Properties
    private let itemsRef = Database.database().reference(withPath: FirebasePath.Items.itemsLocation.path())
    private let usersRef = Database.database().reference(withPath: FirebasePath.Users.users.path())
    private let storage = Storage.storage()

    // Geofire references
    var geoFireRef: DatabaseReference
    var geoFire: GeoFire?

    private var itemPaginationManager: ItemPagination?

    init() {
        self.geoFireRef = Database.database().reference().child(FirebasePath.Geolocation.itemGeoLocation.path())
        self.geoFire = GeoFire(firebaseRef: geoFireRef)

        self.itemPaginationManager = ItemPagination(geoFireRef: geoFireRef)
    }
    // MARK: Class Methods

    func saveItem(newItem: Item) {

        let itemID = newItem.itemID
        let newItemRef = self.itemsRef.child(itemID)

        // Set Value expects a Dictionary, so a helper function is called
        // to turn it into dictionary

        //newItemRef.setValue(newItem.toAnyObject())
        newItemRef.setValue(newItem.toAnyObject(), withCompletionBlock: { error, _ in

            if error != nil {
                print("Error saving item in database")
                return
            }
            print("Setting item with long: ", newItem.itemLongitude, " and lat: ", newItem.itemLatitude)
            self.geoFire?.setLocation(CLLocation(latitude: newItem.itemLatitude, longitude:
                newItem.itemLongitude), forKey: itemID)
        })

        // Once we save the item, we add to the user, so whenever we have to retrieve
        // the childs of that user, we do it more efficient
        let createdByUserID = newItem.createdBy
        let savePath = createdByUserID + "/" + FirebaseParams.Login.itemsCreated
        self.usersRef.child(savePath).child(itemID).setValue(itemID)
    }

    // We store the thumbnail on its Firebase Storage Reference, and we get it back through closure
    func storeThumbnail(itemID: String, imageData: Data, completion: @escaping () -> Void) {

        // STORE THUMBNAIL
        let uploadRef = storage.reference(
            withPath: FirebasePath.ItemStorage.itemsStorageLocation.path() +
                "\(itemID)/" + "\(itemID).jpeg")

        // Upload from data in memory version

        // upload metadata contains info such as file type or size
        let uploadMetadata = StorageMetadata.init()
        uploadMetadata.contentType = "image/jpeg"
        uploadRef.putData(imageData, metadata: uploadMetadata) { (downloadMeta, error) in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                return
            } else {
                // It is not neccesary to return the URL now since we use server queries to get each item
                // URL
                print("Uploaded with medatada size of: ", downloadMeta?.size ?? 0)
                completion()
            }
        }
    }

    // We store the images of the item to the Firebase Storage reference
    func storeImages(itemID: String, imageData: [Data]) {

        var imageIndex = 0

        for child in imageData {

            let uploadRef = storage.reference(
                withPath: FirebasePath.ItemStorage.itemsStorageLocation.path() +
                    "\(itemID)/" + FirebasePath.ItemStorage.itemImages.path() +
                    "\(itemID)_\(imageIndex)")

            // upload metadata contains info such as file type or size
            let uploadMetadata = StorageMetadata.init()
            uploadMetadata.contentType = "image/jpeg"

            uploadRef.putData(child, metadata: uploadMetadata) { (_, error) in
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    return
                }
            }
            print("Image number: ", imageIndex, " uploaded")
            imageIndex += 1

        }

    }

    func downloadImageWithIndex(imgRef: StorageReference, imgIndex: Int,
                                completion: @escaping (URL?, Int) -> Void) {
        let insertIndex = imgIndex

        imgRef.downloadURL(completion: { url, error in
            if let error = error {
                //Handle any errors
                print("Error downloading item image: ", error.localizedDescription)
                completion(url, insertIndex)
            } else {
                // Get download URL
                completion(url, insertIndex)

            }
        })
    }

    // Get all the images from a specific item
    func getItemImages(itemID: String, completionHandler: @escaping ([URL?]) -> Void) {

        // Create a reference to the image we are going to download
        let downloadRef = storage.reference( withPath: FirebasePath.ItemStorage.itemsStorageLocation.path()
            + "\(itemID)/" + FirebasePath.ItemStorage.itemImages.path())

        var itemImagesURL: [Int: URL?] = [:]

        // We retrieve all images using listAll
        downloadRef.listAll(completion: { result, error in

            if let error = error {
                print("Error listing item images: ", error.localizedDescription)
                return
            }

            itemImagesURL.reserveCapacity(result.items.count)

            // We download every image's url
            for index in 0 ..< result.items.count {

                self.downloadImageWithIndex(imgRef: result.items[index], imgIndex: index,
                                            completion: { (url, insertIndex) in
                    itemImagesURL[insertIndex] = url

                    // All the urls of the item's images are retrieved -> we escape
                    // TODO: Is this a good escape condition ??
                    // If any image can't be retrieved by some reason (f.e download error)
                    // The rest won't be retrieved also (because we dont escape)
                    // How to solve this?
                    if itemImagesURL.count == result.items.count {
                        let urlSorted = itemImagesURL.sorted(by: { $1.key > $0.key })

                        // IS THERE A WAY TO GET THE VALUES OF URLSorted (I cant get it using urlSorted.values)
                        var imgsSorted: [URL?] = []

                        for urlDict in urlSorted {
                            imgsSorted.append(urlDict.value)
                        }

                        //print("VALUES ", itemImages)
                        print("Item's Images download finished.")
                        completionHandler(imgsSorted)

                    }
                })

            }

        })  // list all
    }

    // Pagination Functions
    func fetchItemKeysAtLocation(radius: Double, latitude: Double, longitude: Double, completion: @escaping
    ([String]) -> Void) {
        self.itemPaginationManager?.retrieveAllKeysInLocation(radius: radius, latitude: latitude, longitude:
            longitude, completion: { itemKeys in
            completion(itemKeys)
        })
    }

    func fetchItemPage(itemIDs: ArraySlice<String>, completion: @escaping ([Item]) -> Void) {
        self.itemPaginationManager?.retrieveItemPageByID(itemIDs: itemIDs, completion: { newItems in
            completion(newItems)
        })
    }

    // fetch a new page of thumbnails: returning a dictionary pair of URL, and the ItemID associated
    func fetchNewThumbnailPage(thumbnailsID: ArraySlice<String>, amount: Int, completion: @escaping ([String?: URL?])
        -> Void) {
        self.itemPaginationManager?.retrieveThumbnailPage(thumbnailsID: thumbnailsID, amount: amount,
        completion: { thumbnailPage in

            completion(thumbnailPage)
        })
    }

    // Give an array of itemIDs (item keys in the given radius, ordered by distance towards the user)
    // We search for accurrences with the given string, in the item name or details
    // RETURN: We return an array of itemIDs which contains the sequence
    func fetchItemByString(sequenceToLook: String, itemIDsInRadius: [String], completion: @escaping
        ([String]) -> Void) {
        var itemsWithSequence: [String] = []
        var iterationIndex = 0

        for itemID in itemIDsInRadius {

            self.itemsRef.child(itemID).observeSingleEvent(of: .value, with: { (snapshot) in
                iterationIndex += 1
                let itemDict = snapshot.value as? [String: String?]
                let itemID = itemDict?[FirebaseParams.Items.itemID] as? String ?? ""
                let itemName = itemDict?[FirebaseParams.Items.name] as? String ?? ""
                let itemDetails = itemDict?[FirebaseParams.Items.itemDetails] as? String ?? ""

                if itemName.localizedCaseInsensitiveContains(sequenceToLook) ||
                    itemDetails.localizedCaseInsensitiveContains(sequenceToLook) {
                    itemsWithSequence.append(itemID)
                }
                if iterationIndex == itemIDsInRadius.count {
                    //print("FINISHING AND RETURNING ", itemsWithSequence.count, " ocurrences")
                    completion(itemsWithSequence)
                }
            })

        }
    }

    func fetchItemByCategory(fetchedCategory: ItemCategories, itemIDsInRadius: [String], completion: @escaping
    ([String]) -> Void) {
        var itemsWithSequence: [String] = []
        var iterationIndex = 0

        for itemID in itemIDsInRadius {

            self.itemsRef.child(itemID).observeSingleEvent(of: .value, with: { (snapshot) in
                iterationIndex += 1
                let itemDict = snapshot.value as? [String: String?]
                let itemID = itemDict?[FirebaseParams.Items.itemID] as? String ?? ""
                let itemCategory = itemDict?[FirebaseParams.Items.itemCategory] as? String ?? ""

                if itemCategory == fetchedCategory.rawValue {
                    itemsWithSequence.append(itemID)
                }
                if iterationIndex == itemIDsInRadius.count {
                    //print("FINISHING AND RETURNING ", itemsWithSequence.count, " ocurrences")
                    completion(itemsWithSequence)
                }
            })

        }
    }

    // Fetch By Category and string

    func fetchItemByStringAndCategory(sequenceToLook: String,
                                      fetchedCategory: ItemCategories,
                                      itemIDsInRadius: [String],
                                      completion: @escaping ([String]) -> Void) {
        var itemsWithSequence: [String] = []
        var iterationIndex = 0

        for itemID in itemIDsInRadius {

            self.itemsRef.child(itemID).observeSingleEvent(of: .value, with: { (snapshot) in
                iterationIndex += 1
                let itemDict = snapshot.value as? [String: String?]
                let itemID = itemDict?[FirebaseParams.Items.itemID] as? String ?? ""
                let itemName = itemDict?[FirebaseParams.Items.name] as? String ?? ""
                let itemDetails = itemDict?[FirebaseParams.Items.itemDetails] as? String ?? ""
                let itemCategory = itemDict?[FirebaseParams.Items.itemCategory] as? String ?? ""

                if (itemName.localizedCaseInsensitiveContains(sequenceToLook)
                    || itemDetails.localizedCaseInsensitiveContains(sequenceToLook))
                    && itemCategory == fetchedCategory.rawValue {

                    itemsWithSequence.append(itemID)
                }
                if iterationIndex == itemIDsInRadius.count {
                    //print("FINISHING AND RETURNING ", itemsWithSequence.count, " ocurrences")
                    completion(itemsWithSequence)
                }
            })

        }
    }

    func fetchItemBySubcategory(fetchedSubcategory: ItemSubCategories, itemIDsInRadius: [String], completion: @escaping
    ([String]) -> Void) {
        var itemsWithSequence: [String] = []
        var iterationIndex = 0

        for itemID in itemIDsInRadius {

            self.itemsRef.child(itemID).observeSingleEvent(of: .value, with: { (snapshot) in
                iterationIndex += 1
                let itemDict = snapshot.value as? [String: String?]
                let itemID = itemDict?[FirebaseParams.Items.itemID] as? String ?? ""
                let itemSubcategory = itemDict?[FirebaseParams.Items.itemSubcategory] as? String ?? ""

                if itemSubcategory == fetchedSubcategory.rawValue {
                    itemsWithSequence.append(itemID)
                }
                if iterationIndex == itemIDsInRadius.count {
                    //print("FINISHING AND RETURNING ", itemsWithSequence.count, " ocurrences")
                    completion(itemsWithSequence)
                }
            })

        }
    }

    func fetchByCategoryAndSubcategory(fetchedCategory: ItemCategories,
                                       fetchedSubcategory: ItemSubCategories,
                                       itemIDsInRadius: [String], completion:
                                        @escaping ([String]) -> Void) {
        var itemsWithSequence: [String] = []
        var iterationIndex = 0

        for itemID in itemIDsInRadius {

            self.itemsRef.child(itemID).observeSingleEvent(of: .value, with: { (snapshot) in
                iterationIndex += 1
                let itemDict = snapshot.value as? [String: String?]
                let itemID = itemDict?[FirebaseParams.Items.itemID] as? String ?? ""
                let itemSubcategory = itemDict?[FirebaseParams.Items.itemSubcategory] as? String ?? ""
                let itemCategory = itemDict?[FirebaseParams.Items.itemCategory] as? String ?? ""

                if itemCategory == fetchedCategory.rawValue && itemSubcategory == fetchedSubcategory.rawValue {
                    itemsWithSequence.append(itemID)
                }
                if iterationIndex == itemIDsInRadius.count {
                    //print("FINISHING AND RETURNING ", itemsWithSequence.count, " ocurrences")
                    completion(itemsWithSequence)
                }
            })

        }
    }

    func fetchItemCreatedByUserID(userID: String, completion: @escaping ([String])
        -> Void) {

        var itemIDs: [String] = []
        // First we retrieve from the user folder in the db, the items that
        // belong to him, and then we access and save each item
        let savePath = userID + "/" + FirebaseParams.Login.itemsCreated

        print("lets go")
        self.usersRef.child(savePath).observeSingleEvent(of: .value, with: { (snapshot) in
            let enumerator = snapshot.children

            if snapshot.childrenCount != 0 {
                while let itemRest = enumerator.nextObject() as? DataSnapshot {
                    if let itemID = itemRest.value as? String {
                        itemIDs.append(itemID)
                        if itemIDs.count == snapshot.childrenCount {
                            print("retrieving user item IDS finished with ", itemIDs.count)
                            completion(itemIDs)
                        }
                    }
                }
            } else {    // chilren == 0
                completion(itemIDs)
            }

        })
    }
}
