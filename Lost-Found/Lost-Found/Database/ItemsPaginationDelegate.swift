//
//  ItemsPaginationData.swift
//  Lost-Found
//
//  Created by Brolivar on 20/10/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import Foundation
import Firebase
import GeoFire

class ItemPagination {

    // MARK: - Properties
    private let itemsRef = Database.database().reference(withPath: FirebasePath.Items.itemsLocation.path())
    private let storage = Storage.storage()

    // Geofire references
    var geoFireRef: DatabaseReference
    var geoFire: GeoFire?

    init(geoFireRef: DatabaseReference) {
        self.geoFireRef = geoFireRef
        self.geoFire = GeoFire(firebaseRef: geoFireRef)
    }
    // MARK: - Methods

    // Function to retrieve the numbers of total items in the system
    // Currently it won't be used anymore, since we will use geofire
    // query to count the number of item in a given radius

    func getTotalItems(completionHandler: @escaping (Int) -> Void) {

        self.itemsRef.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            let itemsCount = snapshot.childrenCount
            completionHandler(Int(itemsCount))
        })
    }

    /******** ******** ******** ******** ******** ******** ********
     Retrieve a new page of items (without thumbnails)
     GEOFIRE CHANGE:
      - All the paging structure have to be changed, since geofire can't limite a query to (pageAmount)
     to obtain just the first (pageAmount) items, now we obtain all item keys within radius.

     - This operation is less or more efficient that the last, because with the previous structure
     you had also to get the total number of items (to initialize the collectionView with the number of total cells)

     -  This way we just iterate in each page through the itemID array, querying the next (pageAmount) items
    by ID. After retrieving we keep advancing retrieving pages until the end.

    - This also syncronices nicely with the thumbnail paging, because we can use the same ID to query the thumbnails of
     each page, instead of having to keep track the last key in each query (which also returned the thumbnail
     disordered, so it was tricky to figure out.

     ******* ******** ******** ******** ******** ******** ********/
    func retrieveAllKeysInLocation(radius: Double, latitude: Double, longitude: Double, completion: @escaping
        ([String]) -> Void) {

        let searchLocation: CLLocation = CLLocation(latitude: CLLocationDegrees(latitude), longitude:
            CLLocationDegrees(longitude))

        //print("Search location is: .... ", searchLocation)

            // Query to filter by location, with 20km maximum
        let locationQuery = self.geoFire?.query(at: searchLocation, withRadius: radius)

        // Pair of ItemID and the distance towards the user
        var itemKeysDistance: [String: Double] = [:]
        // Array that will the final, ordered by distance, items
        var itemKeys: [String] = []

        locationQuery?.observe(.keyEntered, with: { (key, location) in
            //print("KEY: ", key, " and location: ", location.coordinate)
            let distanceFromUser = searchLocation.distance(from: location)

            itemKeysDistance[key] = distanceFromUser
        })

        locationQuery?.observeReady {
            print("All item keys loaded. There are: ", itemKeysDistance.count, " items in radius")
            locationQuery?.removeAllObservers()

            // Order keys by distance
            let sortedKeys = itemKeysDistance.sorted { $0.1 < $1.1 }

            for itemPair in sortedKeys {
                itemKeys.append(itemPair.key)
            }
            completion(itemKeys)
        }
    }

    // Given a subset of all the item keys in the radius retrieved in "retrieveAllKeysInLocation:"
    // -> We get the item details for the subset.
    // -> Since Geofire doesn't support pagination, this is the only way to paginate the results, by
    // getting the item details just
    func retrieveItemPageByID(itemIDs: ArraySlice<String>, completion: @escaping ([Item]) -> Void) {

        var items: [Item] = [Item]()

        for itemID in itemIDs {

            let itemRef = self.itemsRef.child(itemID)

            itemRef.observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
                guard let weakself = self else { return }

                let itemDict = snapshot.value as? [String: String?]

                weakself.retrieveItem(itemDictionary: itemDict!, completion: { newItem in
                     items.append(newItem)
                     //print(newItem.name, " added")

                    if items.count == itemIDs.count {
                        completion(items)
                    }

                })
            })
        }

    }

    //swiftlint:disable:next cyclomatic_complexity
    func retrieveSubcategoryFromString(subcategory: String) -> ItemSubCategories {
        let itemSubcategory: ItemSubCategories

        switch subcategory {
        case "accessories":
            itemSubcategory = .accessories
        case "clothing":
            itemSubcategory = .clothing
        case "phones":
            itemSubcategory = .phones
        case "computers":
            itemSubcategory = .computers
        case "keysObject":
            itemSubcategory = .keysObject
        case "vehicles":
            itemSubcategory = .vehicles
        case "soundAudio":
            itemSubcategory = .soundAudio
        case "documentation":
            itemSubcategory = .documentation
        case "pets":
            itemSubcategory = .pets
        case "people":
            itemSubcategory = .people
        case "others":
            itemSubcategory = .others
        default:
        print("Error: incorrect subcategory")
            itemSubcategory = .others       // unknown category will be automatically changed to others
        }
        return itemSubcategory
    }
    // Given an NSDictionary, returns the complete item with the thumbnail
    func retrieveItem(itemDictionary: [String: String?], completion: @escaping (Item) -> Void) {

        let itemID = itemDictionary[FirebaseParams.Items.itemID] as? String ?? ""
        let itemName = itemDictionary[FirebaseParams.Items.name] as? String ?? ""
        let itemDetails = itemDictionary[FirebaseParams.Items.itemDetails] as? String ?? ""
        let category = itemDictionary[FirebaseParams.Items.itemCategory] as? String ?? ""
        let subcategory = itemDictionary[FirebaseParams.Items.itemSubcategory] as? String ?? ""
        let createdBy = itemDictionary[FirebaseParams.Items.createdBy] as? String ?? ""
        let dateOfCreation = itemDictionary[FirebaseParams.Items.dateOfCreation] as? String ?? ""

        let itemCategory: ItemCategories

        switch category {
        case "adoption":
            itemCategory = .adoption
        case "lost":
            itemCategory = .lost
        case "found":
            itemCategory = .found
        default:
            print("Error: incorrect category")
            return
        }

        let itemSubcategory: ItemSubCategories = self.retrieveSubcategoryFromString(subcategory: subcategory)
        // Retrieve location
        self.geoFire?.getLocationForKey(itemID, withCallback: { (location, error) in

            if error != nil {
                print("An error occurred getting the location for: \(itemID)")
                return
            } else if location?.coordinate.latitude != nil && location?.coordinate.longitude != nil {

                if let newItem: Item = Item(itemID: itemID, name: itemName, thumbnail: .none,
                                            itemDetails: itemDetails, itemCategory: itemCategory,
                                            itemSubcategory: itemSubcategory,
                                            itemLongitude: (location?.coordinate.longitude)!,
                                            itemLatitude: (location?.coordinate.latitude)!,
                                            createdBy: createdBy, dateOfCreation: dateOfCreation) {
                    completion(newItem)
                } else {
                    print("Error retrieving item")
                    return
                }
            }
        })
    }

    // Retrieve a whole page of thumbnails of @amount, and starting on @lastThumbnailKey
    // We hold a pair of itemID and URL, to be able to search the item object for each thumbnail
    func retrieveThumbnailPage(thumbnailsID: ArraySlice<String>, amount: Int, completion: @escaping ([String?: URL?])
        -> Void) {

        var itemImages: [String?: URL?] = [:]

        for thumbID in thumbnailsID {
            self.getItemThumbnail(itemID: thumbID, completionHandler: { imageURL, thumbID in
                itemImages[thumbID] = imageURL
                // When all the thumbnails URLS are added to the page we escape
                   // TODO: Is this a good escape condition ??
                   // If any image can't be retrieved by some reason (f.e download error)
                   // The rest won't be retrieved also (because we dont escape)
                   // How to solve this?
                if itemImages.count == thumbnailsID.count {
                    print("All ", itemImages.count, " thumbnails downloaded in the FIRST PAGE")
                    completion(itemImages)
                }
            })
        }
    }

    // Gets the thumbnail of an image (thumbnail = image[0] of the item)
    func getItemThumbnail(itemID: String, completionHandler: @escaping (URL?, String) -> Void) {

        // Create a reference to the image we are going to download
        let downloadRef = storage.reference(
            withPath: FirebasePath.ItemStorage.itemsStorageLocation.path() + "\(itemID)/"
                + "\(itemID).jpeg")

        // Download using the URL and Kingfisher to cache and save the img

        downloadRef.downloadURL(completion: { url, error in
            if let error = error {
                //Handle any errors
                print("Error downloading item image: ", error.localizedDescription)
                completionHandler(.none, itemID)     // In case of error the img is not added
            } else {
                // Get download URL
                let imgUrl = url
                //print("Item URL dowloaded: ", imgUrl!)
                completionHandler(imgUrl, itemID)
            }
        })
    }
}
