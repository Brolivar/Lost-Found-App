//
//  ItemDisplayerModelController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 15/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

/*

ItemDisplayer ModelController: this MC is used to paginate (and order by
 distance, filter and display items on the timeline and the itemDetailedView.

 */

import UIKit

// Manages reading of items, and its attributes
protocol ItemDisplayerProtocol: class {
    func itemsCount() -> Int
    func thumnailsCount() -> Int
    func totalCount() -> Int
    func getItem(at index: Int) -> Item
    func setFetchDelegate( fetchDelegate: ItemModelFetchDelegate)
  //  func loadSamples()
    func getName(at index: Int) -> String
    func getID(at index: Int) -> String
    func getItemThumbnail(at index: Int) -> URL?
    func getItemImages(at index: Int, completion: @escaping ([URL?]) -> Void)
    func getItemDetails(at index: Int) -> String
    func getItemCategory(at index: Int) -> ItemCategories
    func getItemSubcategory(at index: Int) -> ItemSubCategories
    func getItemCreatorID(at index: Int) -> String
    func getItemCreationDate(at index: Int) -> String
    func getItemLongitude(at index: Int) -> Double
    func getItemLatitude(at index: Int) -> Double
    func fetchNewItemPage(completion: @escaping () -> Void)
    func fetchNewThumbnailPage()
    func setThumbnailPage(from thumbnails: [String?: URL?])
    func calculateItemIndexPathsToReload(from newItems: [Item]) -> [IndexPath]
    func calculateThumbnailsIndexPathsToReload(from newItems: [String?: URL?]) -> [IndexPath]
    func reloadItemPaging(deleteIDs: Bool, completion: @escaping () -> Void)
    func reloadCategoryFilteredItems()
    func fetchForItem(sequenceToFetch: String, completion: @escaping () -> Void)
    func filterByCategory(itemCategory: ItemCategories, completion: @escaping () -> Void)
    func filterByCategoryAndSequence(sequenceToFetch: String, categoryToFetch: ItemCategories, completion:
        @escaping () -> Void)
    func filterBySubcategory(itemSubcategory: ItemSubCategories, completion: @escaping () -> Void)
    func filterByCategoryAndSubcategory(categoryToFetch: ItemCategories, subcategoryToFetch: ItemSubCategories,
                                        completion: @escaping () -> Void)
    // This could be made into a new class: for getting items of certain user
    func getByCurrentUserItems(completion: @escaping () -> Void)
}

protocol ItemModelFetchDelegate: class {
    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?)
}

class ItemDisplayerModelController {

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
// Manages the reading of Items, and item attributes
extension ItemDisplayerModelController: ItemDisplayerProtocol {

    // Returns the number of items
    func itemsCount() -> Int {
        return self.items.count
    }

    func thumnailsCount() -> Int {
        return self.numberOfThumbnails
    }

    func totalCount() -> Int {
        return self.totalItems
    }

    func getItem(at index: Int) -> Item {
        return self.items[index]
    }

    func setFetchDelegate( fetchDelegate: ItemModelFetchDelegate) {
        self.fetchDelegate = fetchDelegate
    }

    // Returns the name of the item

    func getName(at index: Int) -> String {
        return items[index].name
    }

    func getID(at index: Int) -> String {
        return items[index].itemID
    }

    func getItemImages(at index: Int, completion: @escaping ([URL?]) -> Void) {

        let itemID = items[index].itemID

        self.itemData.getItemImages(itemID: itemID, completionHandler: { images in
            completion(images)
        })
    }

    func getItemDetails(at index: Int) -> String {
        return items[index].itemDetails
    }

    func getItemThumbnail(at index: Int) -> URL? {
        return items[index].itemThumbnail
    }

    // Lost / Found / Adoption
    func getItemCategory(at index: Int) -> ItemCategories {
        return items[index].itemCategory
    }

    func getItemSubcategory(at index: Int) -> ItemSubCategories {
        return items[index].itemSubCategory
    }

    func getItemCreatorID(at index: Int) -> String {
        return items[index].createdBy
    }
    func getItemCreationDate(at index: Int) -> String {
        return items[index].dateOfCreation
    }

    func getItemLongitude(at index: Int) -> Double {
        return items[index].itemLongitude
    }
    func getItemLatitude(at index: Int) -> Double {
        return items[index].itemLatitude
    }

    // MARK: - Item Pagination
    // Retrieve new Page of Items Lighter Data (Name, Description, category...)
    func fetchNewItemPage(completion: @escaping () -> Void) {

        guard !isItemFetchInProgress else {
          return
        }
        self.isItemFetchInProgress = true
        let currentLongitude: Double? = self.userModelController.getCurrentUserLongitude()
        let currentLatitude: Double? = self.userModelController.getCurrentUserLatitude()
        let searchRadius: Int = self.userModelController.getMaxLocationRadius()

        if  currentLatitude != nil && currentLongitude != nil {

            // If we are in the first page: we retrieve ALL ITEM IDS sorted by location
            // in a radius of 20km
            if currentItemPage == 0 {
               // print("we are in the first item page, so we retrieve all the keys")
                self.itemData.fetchItemKeysAtLocation(radius: Double(searchRadius), latitude:
                    currentLatitude!, longitude: currentLongitude!, completion: { [weak self] itemKeys in

                        guard let weakself = self else { return }

                        // There are items in database
                        if !itemKeys.isEmpty {

                            weakself.itemIDsWithinRadius = itemKeys
                            weakself.paginatedItemIDsInRadius = itemKeys
                            weakself.totalItems = weakself.paginatedItemIDsInRadius.count
                            // On the first page we also retrieve the number of items on server
                            print("First page item load")

                            weakself.handleItemPage(completionHandler: {
                                completion()
                            })
                        } else {    // Case where there are no items in db
                            DispatchQueue.main.async {
                                print("Error: there are no items to load.")
                                weakself.isItemFetchInProgress = false
                                weakself.fetchDelegate?.onFetchCompleted(with: .none)
                                completion()
                            }
                        }
                })
                // Rest of pages

            } else {
                self.handleItemPage(completionHandler: {
                    completion()
                })
            }
        }
    }

    // Aux function to handle item pages
    func handleItemPage(completionHandler: @escaping () -> Void) {

            print("retrieving items...")

            // Load subset of item's details, by ID
            let firstPageIndex = self.currentItemPage * ItemDisplayerModelController.itemRefillThreshhold
            var lastPageIndex = self.currentItemPage * ItemDisplayerModelController.itemRefillThreshhold +
            ItemDisplayerModelController.itemRefillThreshhold

            if lastPageIndex > self.totalItems {
                lastPageIndex = self.totalItems
            }
            // print("FIRST INDEX: ", firstPageIndex, "LAST INDEX: ", lastPageIndex)
            let subsetOfItems = self.paginatedItemIDsInRadius[firstPageIndex..<lastPageIndex]

            self.itemData.fetchItemPage(itemIDs: subsetOfItems, completion: { [weak self] newItems in
                guard let weakself = self else { return }
                weakself.isItemFetchInProgress = false
                weakself.currentItemPage += 1
                weakself.items.append(contentsOf: newItems)

                if weakself.currentItemPage == 1 {
                    print("TOTAL ITEMS: ", weakself.totalCount())
                    weakself.fetchDelegate?.onFetchCompleted(with: .none)
                    completionHandler()
                } else {
                    let indexPathsToReload = self?.calculateItemIndexPathsToReload(from:
                        newItems)
                    weakself.fetchDelegate?.onFetchCompleted(with: indexPathsToReload)
                    completionHandler()
                }

            })
        }

    // MARK: - Thumbnail Pagination
    // Retrieve new page of items large data (thumbnail images)
    func fetchNewThumbnailPage() {

        guard !isThumbnailFetchInProgress else {
            return
        }

        self.isThumbnailFetchInProgress = true

        if !self.paginatedItemIDsInRadius.isEmpty {
            // Load subset of item's details,by ID
            var lastPageIndex = self.currentThumbnailPage * ItemDisplayerModelController.thumbnailRefillThreshhold +
                ItemDisplayerModelController.thumbnailRefillThreshhold

            if lastPageIndex > self.items.count {
                lastPageIndex = self.items.count
            }

            // print("FIRST THUMB INDEX: ", numberOfThumbnails, "LAST THUMB INDEX: ", lastPageIndex)
            let subsetOfThumbnails =
                self.paginatedItemIDsInRadius[self.numberOfThumbnails..<lastPageIndex]

            self.itemData.fetchNewThumbnailPage(thumbnailsID: subsetOfThumbnails, amount:
                ItemDisplayerModelController.thumbnailRefillThreshhold, completion: { [weak self] thumbnailPage in

                guard let weakself = self else { return }

                    if !thumbnailPage.isEmpty {

                        DispatchQueue.main.async {
                            weakself.currentThumbnailPage += 1
                            weakself.isThumbnailFetchInProgress = false
                            weakself.setThumbnailPage(from: thumbnailPage)

                            print("Loading more thumbnails...")

                            let indexPathsToReload = weakself.calculateThumbnailsIndexPathsToReload(from: thumbnailPage)
                            weakself.fetchDelegate?.onFetchCompleted(with: indexPathsToReload)

                        }

                    } else {
                        DispatchQueue.main.async {
                            print("Error: there are no thumbnails to load.")
                            weakself.isThumbnailFetchInProgress = false
                            weakself.fetchDelegate?.onFetchCompleted(with: .none)
                            return
                        }
                    }

            })

        } else {
            self.isThumbnailFetchInProgress = false
        }
    }

    // for each pair of ITEMID - URL retrieved from DB, sets each URL to its item object
    func setThumbnailPage(from thumbnails: [String?: URL?]) {
        for (keyItemID, thumbnailURL) in thumbnails {
            // If the id of the url match the item && the item doesn't have thumbnail set
            // (avoid the error when an image is retrieved twice)
            for item in self.items where item.itemID == keyItemID && item.itemThumbnail == .none {
                item.setThumbnail(newThumbnail: thumbnailURL)
                self.numberOfThumbnails += 1
            }
        }
    }

    // MARK: - Data Reload

    // This function calculates the index paths for the last page of ITEMS received
    // and use it to refresh the content that's changed, instead of reloading the whole
    // collectionView
    func calculateItemIndexPathsToReload(from newItems: [Item]) -> [IndexPath] {

        let startIndex = self.items.count - newItems.count
        let endIndex = startIndex + newItems.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0)}
    }

    // This function calculates the index paths for the last page of THUMBNAILS received
    // and use it to refresh the content that's changed, instead of reloading the whole
    // collectionView
    func calculateThumbnailsIndexPathsToReload(from newThumbnails: [String?: URL?]) -> [IndexPath] {
        let startIndex = self.numberOfThumbnails - newThumbnails.count
        let endIndex = startIndex + newThumbnails.count
        return (startIndex..<endIndex).map { IndexPath(row: $0, section: 0)}
    }

    // When the pull to refresh is activated, we restart the fetching with the new results
    // We reset all paging attributes:
    // and optionally the even the fetched itemIDs within radius
    func reloadItemPaging(deleteIDs: Bool, completion: @escaping () -> Void) {

        self.totalItems = 0
        self.currentItemPage = 0
        self.currentThumbnailPage = 0

        self.items.removeAll()
        self.numberOfThumbnails = 0
        self.paginatedItemIDsInRadius.removeAll()

        if deleteIDs == true {
            self.itemIDsWithinRadius.removeAll()
//            self.isItemFetchInProgress = false
//            self.isThumbnailFetchInProgress = false
            self.filteredByCategoryItemIDs.removeAll()
            self.filteredBySearchItemIDs.removeAll()
        }

        completion()
    }

    func reloadCategoryFilteredItems() {
        self.filteredByCategoryItemIDs.removeAll()
    }

    // MARK: - Item Filtering

    // Fetch in the current distance item with the sequence name or details
    // After fetching, the current set of used itemIDs is replaced by the itemsids
    // that contains the sequence.
    // Cases:
    // 1. There are no filters active: search using the original set of ids. (DONE)
    // 2. There are category or sub category filters active: search on filter set (DONE)
    //          - Technically the filteredByCategoryIDs array should be liberated when the
    //          category button is unpressed, but since we
    func fetchForItem(sequenceToFetch: String, completion: @escaping () -> Void) {

        if !self.itemIDsWithinRadius.isEmpty {

            var itemSetToUse: [String] = []

            // A category filter is not active
            if self.filteredByCategoryItemIDs.isEmpty {
                //print("Filter is inactive in SEARCH")
                itemSetToUse = self.itemIDsWithinRadius
            } else {    // A category filter is active -> we take the original item subset
                //print("Filter is active in SEARCH")
                itemSetToUse = self.filteredByCategoryItemIDs
            }
            self.itemData.fetchItemByString(sequenceToLook: sequenceToFetch, itemIDsInRadius:
               itemSetToUse, completion: { [weak self] itemsWithSequence in

                guard let weakself = self else { return }

                //print("received ", itemsWithSequence.count, "occurences")

                // We don't delete the original set of ordered IDs (so if we keep searching, it gets
                // applied to all the set of items (not the subset only)

                // Here we also delete the previous filtered itemIDS subset!!!!!!
                weakself.reloadItemPaging(deleteIDs: false, completion: {

                    weakself.paginatedItemIDsInRadius = itemsWithSequence
                    weakself.filteredBySearchItemIDs = itemsWithSequence

                    // There are items in database
                    if !itemsWithSequence.isEmpty {
                        weakself.isItemFetchInProgress = true

                        weakself.totalItems = weakself.paginatedItemIDsInRadius.count
                        // On the first page we also retrieve the number of items on server
//                        print("First page FILTERED item load")

                        weakself.handleItemPage(completionHandler: {
                            completion()
                        })
                    } else {
                        print("Error: there are no items to load.")
                        weakself.isItemFetchInProgress = false
                        weakself.isThumbnailFetchInProgress = false
                        weakself.fetchDelegate?.onFetchCompleted(with: .none)
                        weakself.filteredBySearchItemIDs.removeAll()
                        completion()
                    }

                })
            })
        } else {
            print("There are not items to search")
            completion()
        }
    }

    // MARK: - Category
    // When we apply a filter:
    // 1. There is another category filter active -> we filter using all keys within radius (original set)
    // 2. There is a subcategory filter active -> we filter through the filtered keys (filtered subset)
    // 3. There is a search active -> we filter through the filtered keys
    func filterByCategory(itemCategory: ItemCategories, completion: @escaping () -> Void) {

        if !self.itemIDsWithinRadius.isEmpty {

            var itemSetToUse: [String] = []

            if self.filteredBySearchItemIDs.isEmpty {
                //print("CATEGORY filter normally")
                itemSetToUse = itemIDsWithinRadius
            } else {
                //print("SEARCH FILTER ACTIVE")
                // Case when a search filter is active, and we select a category
                itemSetToUse = self.filteredBySearchItemIDs
            }

            self.itemData.fetchItemByCategory(fetchedCategory: itemCategory, itemIDsInRadius:
               itemSetToUse, completion: { [weak self] fetchedItems in

                    guard let weakself = self else { return }
                    //print("received ", fetchedItems.count, "occurences")

                    // We don't delete the original set of ordered IDs (so if we keep searching, it gets
                    // applied to all the set of items (not the subset only)
                    weakself.reloadItemPaging(deleteIDs: false, completion: {
                        weakself.paginatedItemIDsInRadius = fetchedItems
                        weakself.filteredByCategoryItemIDs = fetchedItems         // Fill the filtered set
                        // There are items in database
                        if !fetchedItems.isEmpty {
                            weakself.isItemFetchInProgress = true

                            weakself.totalItems = weakself.paginatedItemIDsInRadius.count
                            // On the first page we also retrieve the number of items on server
//                          print("First page FILTERED item load")

                            weakself.handleItemPage(completionHandler: {
                                completion()
                            })
                        } else {
                            print("Error: there are no items to load.")
                            weakself.isItemFetchInProgress = false
                            weakself.isThumbnailFetchInProgress = false
                            weakself.fetchDelegate?.onFetchCompleted(with: .none)
                            completion()
                        }

                    })
            })
        } else {
            print("There are not items to search")
            completion()
        }
    }

    func filterByCategoryAndSequence(sequenceToFetch: String, categoryToFetch: ItemCategories, completion:
        @escaping () -> Void) {

        if !self.itemIDsWithinRadius.isEmpty {
            self.itemData.fetchItemByStringAndCategory(sequenceToLook:
                sequenceToFetch, fetchedCategory: categoryToFetch, itemIDsInRadius:
                self.itemIDsWithinRadius, completion: { [weak self] fetchedItems in

                    guard let weakself = self else { return }
                    //print("received ", fetchedItems.count, "occurences")

                    // We don't delete the original set of ordered IDs (so if we keep searching, it gets
                    // applied to all the set of items (not the subset only)
                    weakself.reloadItemPaging(deleteIDs: false, completion: {
                        weakself.paginatedItemIDsInRadius = fetchedItems
                        weakself.filteredByCategoryItemIDs = fetchedItems         // Fill the filtered set
                        weakself.filteredBySearchItemIDs = fetchedItems

                        // There are items in database
                        if !fetchedItems.isEmpty {
                            weakself.isItemFetchInProgress = true

                            weakself.totalItems = weakself.paginatedItemIDsInRadius.count
                            // On the first page we also retrieve the number of items on server
    //                          print("First page FILTERED item load")

                            weakself.handleItemPage(completionHandler: {
                                completion()
                            })
                        } else {
                            print("Error: there are no items to load.")
                            weakself.isItemFetchInProgress = false
                            weakself.isThumbnailFetchInProgress = false
                            weakself.fetchDelegate?.onFetchCompleted(with: .none)
                            completion()
                        }
                })

            })
        } else {
            print("There are not items to search")
            completion()
        }
    }

    // MARK: - Subcategories
    func filterBySubcategory(itemSubcategory: ItemSubCategories, completion: @escaping () -> Void) {

        if !self.itemIDsWithinRadius.isEmpty {

            var itemSetToUse: [String] = []

            if self.filteredBySearchItemIDs.isEmpty && self.filteredByCategoryItemIDs.isEmpty {
                print("SUB CATEGORY filter normally")
                itemSetToUse = itemIDsWithinRadius
            } else if !self.filteredBySearchItemIDs.isEmpty {
                print("SUBCATEGORY - SEARCH FILTER ACTIVE")
                // Case when a search filter is active, and we select a category
                itemSetToUse = self.filteredBySearchItemIDs
            } else if !self.filteredByCategoryItemIDs.isEmpty {
                print("SUBCATEGORY - CATEGORY FILTER ACTIVE")
                // Case when a search filter is active, and we select a category
                itemSetToUse = self.filteredByCategoryItemIDs
            }

            self.itemData.fetchItemBySubcategory(fetchedSubcategory: itemSubcategory, itemIDsInRadius:
               itemSetToUse, completion: { [weak self] fetchedItems in

                    guard let weakself = self else { return }
                    //print("received ", fetchedItems.count, "occurences")

                    // We don't delete the original set of ordered IDs (so if we keep searching, it gets
                    // applied to all the set of items (not the subset only)
                    weakself.reloadItemPaging(deleteIDs: false, completion: {
                        weakself.paginatedItemIDsInRadius = fetchedItems
                        weakself.filteredByCategoryItemIDs = fetchedItems         // Fill the filtered set

                        // There are items in database
                        if !fetchedItems.isEmpty {
                            weakself.isItemFetchInProgress = true

                            weakself.totalItems = weakself.paginatedItemIDsInRadius.count
                            // On the first page we also retrieve the number of items on server
    //                          print("First page FILTERED item load")

                            weakself.handleItemPage(completionHandler: {
                                completion()
                            })
                        } else {
                            print("Error: there are no items to load.")
                            weakself.isItemFetchInProgress = false
                            weakself.isThumbnailFetchInProgress = false
                            weakself.fetchDelegate?.onFetchCompleted(with: .none)
                            completion()
                        }

                    })
            })
        } else {
            print("There are not items to search")
            completion()
        }
    }

    func filterByCategoryAndSubcategory(categoryToFetch: ItemCategories, subcategoryToFetch: ItemSubCategories,
                                        completion: @escaping () -> Void) {

        if !self.itemIDsWithinRadius.isEmpty {

            self.itemData.fetchByCategoryAndSubcategory(fetchedCategory:
                categoryToFetch, fetchedSubcategory: subcategoryToFetch, itemIDsInRadius:
                self.itemIDsWithinRadius, completion: { [weak self] fetchedItems in

                    guard let weakself = self else { return }
                    //print("received ", fetchedItems.count, "occurences")

                    // We don't delete the original set of ordered IDs (so if we keep searching, it gets
                    // applied to all the set of items (not the subset only)
                    weakself.reloadItemPaging(deleteIDs: false, completion: {
                        weakself.paginatedItemIDsInRadius = fetchedItems
                        weakself.filteredByCategoryItemIDs = fetchedItems         // Fill the filtered set
                        //weakself.filteredBySearchItemIDs = fetchedItems

                        // There are items in database
                        if !fetchedItems.isEmpty {
                            weakself.isItemFetchInProgress = true

                            weakself.totalItems = weakself.paginatedItemIDsInRadius.count
                            // On the first page we also retrieve the number of items on server
    //                          print("First page FILTERED item load")

                            weakself.handleItemPage(completionHandler: {
                                completion()
                            })
                        } else {
                            print("Error: there are no items to load.")
                            weakself.isItemFetchInProgress = false
                            weakself.isThumbnailFetchInProgress = false
                            weakself.fetchDelegate?.onFetchCompleted(with: .none)
                            completion()
                        }
                })

            })
        } else {
            print("There are not items to search")
            completion()
        }
    }

    // MARK: - Current User Items
    func getByCurrentUserItems(completion: @escaping () -> Void) {

        self.itemData.fetchItemCreatedByUserID(userID: self.userModelController.getUserID(),
            completion: { [weak self] userItems in

                guard let weakself = self else { return }
                print("RECEIVED ", userItems.count)

                weakself.reloadItemPaging(deleteIDs: false, completion: {
                    weakself.paginatedItemIDsInRadius = userItems

                    if !userItems.isEmpty {
                        weakself.isItemFetchInProgress = true
                        weakself.totalItems = weakself.paginatedItemIDsInRadius.count
                        weakself.handleItemPage(completionHandler: {
                            completion()
                        })
                    } else {
                       print("Error: there are no items to load.")
                       weakself.isItemFetchInProgress = false
                       weakself.isThumbnailFetchInProgress = false
                       weakself.fetchDelegate?.onFetchCompleted(with: .none)
                       completion()
                    }
                })
        })
    }
    //swiftlint:disable:next file_length
}
