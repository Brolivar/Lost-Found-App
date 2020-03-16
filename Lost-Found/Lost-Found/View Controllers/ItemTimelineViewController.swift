//
//  ItemTimelineViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 09/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import CoreLocation

//swiftlint:disable:next type_body_length
class ItemTimelineViewController: UIViewController {

    // MARK: Properties

    weak var delegate: TimelineNavigatorDelegate?
    @IBOutlet private var itemCollectionView: UICollectionView!

    // Filter Header reusable view
    @IBOutlet private var filterHeaderReusableView: UICollectionReusableView!

    @IBOutlet private var selectLocationToolTip: UIView!
    @IBOutlet private var refreshTimelineTooltip: UIView!

    @IBOutlet private var itemSearchBar: UISearchBar!

    // Filter Views (mostly to change layout on press)
    @IBOutlet private var filterLostItemView: UIView!
    @IBOutlet private var filterFoundItemView: UIView!
    @IBOutlet private var filterAdoptionItemView: UIView!
    @IBOutlet private var filterSubCategoryItemView: UIView!

    private var currentFetchedSubcategory: ItemSubCategories?

    // Protocol that contains all the model's functions
    var itemRetrieverProtocol: ItemDisplayerProtocol!
    var userManagerProtocol: UserManagerProtocol!
    var locationManager: CLLocationManager!

    // Refresh Control
    private let refreshControl = UIRefreshControl()
    // Refresh location (100m)
    private let refreshDistance: Double = 100

    // This var are neccesary to have one way to tell the timelineVC
    // that the filters have changed (after the previous VC has been dimissed)
    // and data needs to update.
    // Used for distance filter and subcategory (the ones that have a pop up presented)
    private var currentItemSearchRadius: Int?
    private var currentSelectedLatitude: Double?
    private var currentSelectedLongitude: Double?

    // Keeping track of which buttons are pressed and which are unpressed, and also
    // make the layout changes according
    private var isLostFilterActive: Bool = false
    private var isFoundFilterActive: Bool = false
    private var isAdoptionFilterActive: Bool = false
    private var isSubCategoryFilterActive: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        if let layout = itemCollectionView?.collectionViewLayout as? TimelineLayout {
            layout.delegate = self
        }

        self.itemCollectionView.delegate = self
        // Collection Reusable View Header
        self.itemCollectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind:
            UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CollectionReusableView")

        // - Item Search Bar Set-Up
        self.itemSearchBar.delegate = self

        // - Refresh Control Set-Up
        // Since iOS 10 CollectionV has its own refreshControl property
        if #available(iOS 10.0, *) {
            self.itemCollectionView.refreshControl = self.refreshControl
        } else {
            self.itemCollectionView.addSubview(refreshControl)
        }
        // Configure refresh control
        self.refreshControl.addTarget(self, action: #selector(refreshItemData(_:)), for: .valueChanged)
        refreshControl.tintColor = .black

        // - Item Pagination Set-Up
        self.itemCollectionView.prefetchDataSource = self
        self.currentItemSearchRadius = self.userManagerProtocol.getMaxLocationRadius()

        self.locationManager = CLLocationManager()
        // The minimun distance before a update event is triggered (50m)
        self.locationManager.delegate = self
        self.locationManager.distanceFilter = self.refreshDistance
        self.checkLocationServices(completion: {
            self.currentSelectedLatitude = self.userManagerProtocol.getCurrentUserLatitude()
            self.currentSelectedLongitude = self.userManagerProtocol.getCurrentUserLongitude()
        })
    }

    // MARK: Actions

    @IBAction func addItemTapped(_ sender: Any) {
        if self.userManagerProtocol.userLogged() {
            self.delegate?.navigateToAddItem()
        } else {
            self.showCustomAlertMessage(message: "You need to be logged in order to create an item", type: .error)
        }
    }

    // Call to the mainCoordinator to instantiate the menu and its interactions
    @IBAction func slideMenuTapped(_ sender: Any) {
        self.delegate?.navigateToSlideMenu()
    }

    // Refresh the collection View
    @objc private func refreshItemData(_ sender: Any) {
        self.showHUD()
        self.refreshPageData(deleteIDs: true)
        // UI reset
        self.itemSearchBar.text?.removeAll()
        self.deActivateAllFilters()

        // We have to reload our custom layouts cache (includes things like item's cells size...)
        if let layout = self.itemCollectionView.collectionViewLayout as? TimelineLayout {
            layout.reloadCache()
        }

        self.itemCollectionView.collectionViewLayout.invalidateLayout()

    }

    // MARK: - Filters
    // - Filter menu buttons
    // Change buttons layout to custom pressed state
    // Also, when a category filter button is pressed, the other deactivates (they are exclusive)
    // -> MODIFICATTION <-
    // - UNIQUE CASE -
    // 1. when a category filter is applied,
    // 2. then a search is made
    // 3. Finally the current filter is changed
    // In this particular case, we can't use the modelController copies of item keys of previous filters
    // (since it's getting filtered by a category we are not looking for from the start****)
    // ** not like the case when you search for a item, and then apply a category filter, and then change category
    // (because in that case you can reuse the keys of the firstly searched items, BUT THERE IS NO WAY TO DIFFERENCIATE
    // one CASE FROM ANOTHER, because they are the same operations in different order).
    //
    // -> SO: To solve this, for both of this cases, a custom query will be
    // made to search by string, and also by category
    // (it's a bit inneficient since in the second case we don't really need it, but there is no way to firmly tell
    // it a search was made in the first place or in the second)
    //  POSSIBLE Solution: Maybe in the item keys copies in the MC, we can
    // change it have a var like "lastSearchCategory"
    // to check that, or something like that

    // MARK: - Lost
    @IBAction func filterByLostTapped(_ sender: Any) {
        print("Filtering by lost items")
        if isLostFilterActive == false {
            // Set button and filter as active
            isLostFilterActive = true
            self.setFilterViewAsActive(filterView: self.filterLostItemView, categoryColor: lostColor)

            // Data fetch

            // Particular case: we cannot reuse previous (filter) keys because a category filter and a search have been
            // already applied.
            if (self.isFoundFilterActive || self.isAdoptionFilterActive) && (self.itemSearchBar.text != nil &&
                !self.itemSearchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty) {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategoryAndSequence(sequenceToFetch: self.itemSearchBar.text!,
                                                                       categoryToFetch: .lost, completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            // Case: subcategory filter is active: we filter using that
            } else if self.isSubCategoryFilterActive && currentFetchedSubcategory != nil {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategoryAndSubcategory(categoryToFetch: .lost,
                    subcategoryToFetch: self.currentFetchedSubcategory!, completion: {
                     self.hideHUD()
                     self.shouldShowRefreshToolTip()
                     self.itemRetrieverProtocol.fetchNewThumbnailPage()
                 })
            } else {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategory(itemCategory: .lost, completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            }
            // Deactivate rest of filter buttons
            self.setFilterViewAsInactive(filterView: self.filterFoundItemView)
            self.isFoundFilterActive = false
            self.setFilterViewAsInactive(filterView: self.filterAdoptionItemView)
            self.isAdoptionFilterActive = false

        } else if isLostFilterActive == true {
            isLostFilterActive = false
            self.setFilterViewAsInactive(filterView: self.filterLostItemView)
            self.refreshDataIfNoFilters()
        }
    }
    // MARK: - Found
    @IBAction func filterByFoundTapped(_ sender: Any) {
        print("Filtering by found items")
        if isFoundFilterActive == false {
            // Set button and filter as active
            isFoundFilterActive = true
            self.setFilterViewAsActive(filterView: self.filterFoundItemView, categoryColor: foundColor)

            // Particular case (list of filtered item keys cant be used)
            if (self.isLostFilterActive || self.isAdoptionFilterActive) && (self.itemSearchBar.text != nil &&
                !self.itemSearchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty) {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategoryAndSequence(sequenceToFetch: self.itemSearchBar.text!,
                                                                       categoryToFetch: .found, completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            // Case: subcategory filter is active: we filter using that
            } else if self.isSubCategoryFilterActive && currentFetchedSubcategory != nil {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategoryAndSubcategory(categoryToFetch: .found, subcategoryToFetch:
                    self.currentFetchedSubcategory!, completion: {
                     self.hideHUD()
                     self.shouldShowRefreshToolTip()
                     self.itemRetrieverProtocol.fetchNewThumbnailPage()
                 })
            } else {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategory(itemCategory: .found, completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            }

            // Deactivate rest of filter buttons
            self.setFilterViewAsInactive(filterView: self.filterLostItemView)
            self.isLostFilterActive = false
            self.setFilterViewAsInactive(filterView: self.filterAdoptionItemView)
            self.isAdoptionFilterActive = false

        } else if isFoundFilterActive == true {
            isFoundFilterActive = false
            self.setFilterViewAsInactive(filterView: self.filterFoundItemView)
            self.refreshDataIfNoFilters()
        }
    }
    // MARK: - Adoption
    @IBAction func filterByAdoptionTapped(_ sender: Any) {
        print("Filtering by adoption items")
        if isAdoptionFilterActive == false {
            // Set button and filter as active
            isAdoptionFilterActive = true
            self.setFilterViewAsActive(filterView: self.filterAdoptionItemView, categoryColor: adoptionColor)

            // Particular case (list of filtered item keys cant be used)
            if (self.isLostFilterActive || self.isFoundFilterActive) && (self.itemSearchBar.text != nil &&
                !self.itemSearchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty) {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategoryAndSequence(sequenceToFetch: self.itemSearchBar.text!,
                                                                       categoryToFetch: .adoption, completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            // Case: subcategory filter is active: we filter using that
            } else if self.isSubCategoryFilterActive && currentFetchedSubcategory != nil {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategoryAndSubcategory(categoryToFetch: .adoption,
                    subcategoryToFetch: self.currentFetchedSubcategory!, completion: {
                     self.hideHUD()
                     self.shouldShowRefreshToolTip()
                     self.itemRetrieverProtocol.fetchNewThumbnailPage()
                 })
            } else {
                self.showHUD()
                self.itemRetrieverProtocol.filterByCategory(itemCategory: .adoption, completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            }
            // Deactivate rest of filter buttons
            self.setFilterViewAsInactive(filterView: self.filterLostItemView)
            self.isLostFilterActive = false
            self.setFilterViewAsInactive(filterView: self.filterFoundItemView)
            self.isFoundFilterActive = false

        } else if isAdoptionFilterActive == true {
            isAdoptionFilterActive = false
            self.setFilterViewAsInactive(filterView: self.filterAdoptionItemView)
            self.refreshDataIfNoFilters()
        }
    }

    // if there are other filters active when we deactivate a category filter -> we keep that results
    func refreshDataIfNoFilters() {
        if self.isSubCategoryFilterActive && currentFetchedSubcategory != nil {
            // There is a subcategory filter active. We keep that filter results
            self.itemRetrieverProtocol.reloadCategoryFilteredItems()
            self.showHUD()
            self.itemRetrieverProtocol.filterBySubcategory(itemSubcategory: currentFetchedSubcategory!,
                                                           completion: {
                self.hideHUD()
                self.shouldShowRefreshToolTip()
                self.itemRetrieverProtocol.fetchNewThumbnailPage()
            })
        } else {
            self.refreshPageData(deleteIDs: true)
        }
    }
    // MARK: - Location
    // Select location, and distance radius
    @IBAction func filterByLocationTapped(_ sender: Any) {
        self.selectLocationToolTip.isHidden = true
        self.delegate?.navigateToLocationFilterView()
    }

    // MARK: - SubCategory
    // When we deactivate the subcategory filter, we don't just reload the timeline.
    // We need to consider if there are any other filters active (search, category, or both)
    // active to keep the timeline filtered by those active (and if none active just reload timeline
    @IBAction func filterBySubCategoryTapped(_ sender: Any) {
        //print("Filtering by subcategory")
        if isSubCategoryFilterActive == true {

            self.setFilterViewAsInactive(filterView: self.filterSubCategoryItemView)
            self.isSubCategoryFilterActive = false
            self.currentFetchedSubcategory = .none
            self.handleSubcategoryFilterDeActivation()

        } else {
            self.delegate?.displaySubCategoryFilterPopOver(subCategorySelectedDelegate: self)
        }
    }

    func handleSubcategoryFilterDeActivation () {

        // Search & Category filters are still active
        if (self.isFoundFilterActive || self.isAdoptionFilterActive || self.isLostFilterActive) &&
            (self.itemSearchBar.text != nil &&
            !self.itemSearchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty) {

            print("Subcategory filter DEACTIVATED, but still SEARCH and CATEGORY ACTIVE")

        // Category filter is still active
        } else if (self.isFoundFilterActive || self.isAdoptionFilterActive || self.isLostFilterActive) &&
        (self.itemSearchBar.text == nil ||
        self.itemSearchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty) {

            print("Subcategory filter DEACTIVATED, but still CATEGORY filter ACTIVE")

            // Depending of the filter, we go back and UPDATE the results for that filter
            if isLostFilterActive {
                self.isLostFilterActive = false
                self.filterByLostTapped((Any).self)
            } else if isFoundFilterActive {
                self.isFoundFilterActive = false
                self.filterByFoundTapped((Any).self)
            } else if isAdoptionFilterActive {
                self.isAdoptionFilterActive = false
                self.filterByAdoptionTapped((Any).self)
            }

        // Search filter is still active
        } else if (!self.isFoundFilterActive && !self.isAdoptionFilterActive && !self.isLostFilterActive) &&
        (self.itemSearchBar.text != nil &&
        !self.itemSearchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty) {
            print("Subcategory filter DEACTIVATED, but still SEARCH filter ACTIVE")
            self.refreshPageData(deleteIDs: true)

        // No other filter is active
        } else {
            print("Subcategory filter DEACTIVATED, Nothing  else active")
            self.refreshPageData(deleteIDs: true)
        }

    }

    @IBAction func setLocationTapped(_ sender: Any) {
        self.selectLocationToolTip.isHidden = true
        self.delegate?.navigateToLocationFilterView()
    }
    // MARK: - Private Methods

    private func setFilterViewAsActive(filterView: UIView, categoryColor: UIColor) {
        filterView.backgroundColor = categoryColor
        filterView.layer.borderWidth = 1
        filterView.layer.borderColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    }
    private func setFilterViewAsInactive(filterView: UIView) {
        filterView.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        filterView.layer.borderWidth = 0
    }

    // Shows or not the refresh tooltip, in case there are no items displayed
    private func shouldShowRefreshToolTip() {
        if self.itemRetrieverProtocol.itemsCount() == 0 {
            self.refreshTimelineTooltip.isHidden = false
        } else {
            self.refreshTimelineTooltip.isHidden = true
        }
    }

    private func deActivateAllFilters() {
        // Remove filter active states
        self.isLostFilterActive = false
        self.setFilterViewAsInactive(filterView: self.filterLostItemView)
        self.isFoundFilterActive = false
        self.setFilterViewAsInactive(filterView: self.filterFoundItemView)
        self.isAdoptionFilterActive = false
        self.setFilterViewAsInactive(filterView: self.filterAdoptionItemView)

        self.setFilterViewAsInactive(filterView: self.filterSubCategoryItemView)
        self.isSubCategoryFilterActive = false
        self.currentFetchedSubcategory = .none
    }

    // Here we "reset" all the page data, while also reloading the collection view
    // and tell the refresh control to stop refreshing
    private func refreshPageData(deleteIDs: Bool) {
        DispatchQueue.main.async {

            self.itemRetrieverProtocol.reloadItemPaging(deleteIDs: deleteIDs) {
                self.itemCollectionView.reloadData()
//                print("Restart pagination completed")
                self.refreshControl.endRefreshing()
                self.itemRetrieverProtocol.fetchNewItemPage(completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            }
        }

    }
    // MARK: - Public Methods

    // We reload data from here because the itemTimelineVC is not being
    // deinstantiated (it's the parent coordinator)
    // That's why we need to override viewWillAppear to reloadData()
    // (instead of viewDidLoad()
    override func viewWillAppear(_ animated: Bool) {

        super.viewWillAppear(animated)
        let updatedLongitude = self.userManagerProtocol.getCurrentUserLongitude()
        let updatedLatitude = self.userManagerProtocol.getCurrentUserLatitude()

        if self.currentItemSearchRadius != self.userManagerProtocol.getMaxLocationRadius() ||
        self.currentSelectedLongitude != updatedLongitude || self.currentSelectedLatitude != updatedLatitude {
            print("Distance filter updated. Refreshing...")

            self.currentSelectedLongitude = updatedLongitude
            self.currentSelectedLatitude = updatedLatitude

            self.currentItemSearchRadius = self.userManagerProtocol.getMaxLocationRadius()
            self.deActivateAllFilters()
            self.refreshPageData(deleteIDs: true)
        } else {
            if let layout = itemCollectionView?.collectionViewLayout as? TimelineLayout {
                layout.reloadCache()
            }
            self.itemCollectionView.delegate = self
            //self.itemCollectionView.reloadData()
            self.itemCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout Delegate
// We divide the rows to have always two columns of items
extension ItemTimelineViewController: UICollectionViewDelegateFlowLayout {

//    func collectionView(_ collectionView: UICollectionView,
//                        layout collectionViewLayout: UICollectionViewLayout,
//                        sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width = view.frame.size.width
//        return CGSize(width: width * 0.4, height: 170)//    }
}

// MARK: - UICollectionViewDelegate Delegate
extension ItemTimelineViewController: UICollectionViewDelegate {
    // Display detailed view for item
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        // Fetches the appropriate item for the data source layout.
        let name = itemRetrieverProtocol.getName(at: indexPath.row)
        let itemDetails = itemRetrieverProtocol.getItemDetails(at: indexPath.row)
        let itemCategory = itemRetrieverProtocol.getItemCategory(at: indexPath.row)
        let itemSubcategory = itemRetrieverProtocol.getItemSubcategory(at: indexPath.row)
        let dateOfCreation = itemRetrieverProtocol.getItemCreationDate(at: indexPath.row)
        let createdByUser = itemRetrieverProtocol.getItemCreatorID(at: indexPath.row)

        // We navigate to the item detailView (we pass the item Index in the array to locate it later
        self.delegate?.navigateToItemDetailView(name: name, itemIndex: indexPath.row, itemDetails: itemDetails,
                                                itemCategory: itemCategory, itemSubcategory: itemSubcategory,
                                                createdBy: createdByUser, dateOfCreation: dateOfCreation)
    }
}
// MARK: - UICollectionViewDataSource
// Cell dequeue and setup
extension ItemTimelineViewController: UICollectionViewDataSource {

    // Get number of sample items
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemRetrieverProtocol.totalCount()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    // Get each cell's photo and text
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell",
                                                            for: indexPath) as? ItemCollectionViewCell
        else {
            print("The dequeued cell is not an instance of ItemCollectionViewCell.")
            return UICollectionViewCell()
        }

        if isLoadingCell(for: indexPath) {
            cell.configure(with: .none)
        } else {
            let item: Item = itemRetrieverProtocol.getItem(at: indexPath.row)
            cell.configure(with: item )
            if item.itemCategory == .lost {
                cell.backgroundColor = lostColor
            } else if item.itemCategory == .found {
                cell.backgroundColor = foundColor
            } else if item.itemCategory == .adoption {
                cell.backgroundColor = adoptionColor
            }
        }

        // Cell SetUp Error Handling
        return cell

    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionHeader {

            let suplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
            withReuseIdentifier: "CollectionReusableView", for: indexPath) as UICollectionReusableView

            // Since we are using a custom layout, our Reusable Header View has to be
            // attached manually.
            suplementaryView.addSubview(self.filterHeaderReusableView)

            return suplementaryView

        } else {
            return UICollectionReusableView()
        }

    }

}

extension ItemTimelineViewController: TimeLineLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
//        if let image = self.itemRetrieverProtocol.getItemThumbnail(at: indexPath.item) {
//            print("height: ", image.size.height)
//            return image.size.height
//        } else {
//            return 0
//        }
        return 250
    }
}

// MARK: - ItemModelFetchDelegate Delegate
extension ItemTimelineViewController: ItemModelFetchDelegate {

    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?) {
        guard let newIndexPathsToReload = newIndexPathsToReload else {
//            print("WE ARE IN THE FIRST PAGE")
            itemCollectionView.reloadData()
            self.hideHUD()
            return
        }

        let indexPathsToReload = visibleIndexPathsToReload(intersecting: newIndexPathsToReload)
        itemCollectionView.reloadItems(at: indexPathsToReload)
    }
}

// MARK: - UICollectionViewDataSourcePrefetching Delegate
extension ItemTimelineViewController: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {

        if indexPaths.contains(where: isLoadingCell) {
            print("Getting new PAGE of items....")
            self.itemRetrieverProtocol.fetchNewItemPage(completion: {})

        } else if indexPaths.contains(where: isLoadingCellThumbnail) {
            print("Getting new PAGE of thumbnails...")
            self.itemRetrieverProtocol.fetchNewThumbnailPage()
        }
    }
}

// MARK: - ItemTimeLineViewController Delegate
private extension ItemTimelineViewController {

    // Allows to determine whether the cell at that index path is beyond the count
    // of the items we have received so far
    func isLoadingCell(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= self.itemRetrieverProtocol.itemsCount()
    }

    // Allows to determine whether the cell at that index path is beyond the count
    // of the items we have received so far
    func isLoadingCellThumbnail(for indexPath: IndexPath) -> Bool {
        return indexPath.row >= self.itemRetrieverProtocol.thumnailsCount()
    }

    // This method calculates the cells of the Collection that we need to reload when we receive
    // a new page. It calculates the intersection of the indexPaths passed with the visible ones.
    // (this is so we avoid refreshing cells that are not visible on screen)
    func visibleIndexPathsToReload(intersecting indexPaths: [IndexPath]) -> [IndexPath] {

        let indexPathsForVisibleRows = self.itemCollectionView.indexPathsForVisibleItems
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
}

    // MARK: - ItemTimeLineViewController Delegate
    extension ItemTimelineViewController: CLLocationManagerDelegate {

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

            if let currentCoordinates = locations.last?.coordinate {

                self.userManagerProtocol.setCurrentLocation(
                    userLatitude: currentCoordinates.latitude,
                    userLongitude: currentCoordinates.longitude)

                print("COORDINATES Updated to: ", currentCoordinates)
            }

        }

        // When the user accepts or refuses the permissions, we start retrieving location based items
        // or do show else
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {

            // When permissions updated, we execute again the function (this time with the updated status)
            // so we can decide what to show

            print("Permissions changed...")
            self.checkLocationServices(completion: {})
        }

        // Check user location permissions
        func checkLocationServices(completion: @escaping () -> Void) {

            if CLLocationManager.locationServicesEnabled() {
                print("Location services enabled")

                switch CLLocationManager.authorizationStatus() {
                case .authorizedWhenInUse:
                    self.selectLocationToolTip.isHidden = true

                    // We set the coordinates that we will use to
                    // make the location-based search
                    // Updated on reload
                    if let currentCoordinates = self.locationManager.location?.coordinate {
                        self.userManagerProtocol.setCurrentLocation(
                            userLatitude: currentCoordinates.latitude,
                            userLongitude: currentCoordinates.longitude)
                    }

                    // Load Pages
                    self.showHUD()
                    self.itemRetrieverProtocol.fetchNewItemPage(completion: {
                        self.itemRetrieverProtocol.fetchNewThumbnailPage()
                    })
                case .denied:
                    let userLat = self.userManagerProtocol.getCurrentUserLatitude()
                    let userLong = self.userManagerProtocol.getCurrentUserLongitude()
                    if userLat == nil && userLong == nil {
                        self.selectLocationToolTip.isHidden = false
                    }
                case .notDetermined:
                    locationManager.requestWhenInUseAuthorization()
                case .restricted:
                    let userLat = self.userManagerProtocol.getCurrentUserLatitude()
                    let userLong = self.userManagerProtocol.getCurrentUserLongitude()
                    if userLat == nil && userLong == nil {
                        self.selectLocationToolTip.isHidden = false
                    }
                case .authorizedAlways:
                     self.selectLocationToolTip.isHidden = true
                    // This never happends because info.plist is set that way
                    //self.locationManager.startUpdatingLocation()
                    // Load Pages
//                    self.showHUD()
//                    self.itemRetrieverProtocol.fetchNewItemPage(completion: {
//                        self.itemRetrieverProtocol.fetchNewThumbnailPage()
//                    })
                @unknown default:
                    print("Unknown authorization Status")
                }
            } else {
                print("Location servides are DISABLED")
                self.selectLocationToolTip.isHidden = false
                // Show alert to enable location permission ?? ->
                // No, the alert will be just when you login -> like wallapop
            }
        }
    }

// MARK: - ItemModelFetchDelegate Delegate
extension ItemTimelineViewController: UISearchBarDelegate {

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {

        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // Query to the model controller, to retrieve from
        if searchBar.text != nil {
            if searchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty {
                print("Only spaces")
                self.refreshPageData(deleteIDs: true)       // if there are only spaces, we reload the timeline
                self.deActivateAllFilters()
            } else {
                self.showHUD()
                self.itemRetrieverProtocol.fetchForItem(sequenceToFetch: searchBar.text!, completion: {
                    // Show refresh tool tip is items == 0
                    self.shouldShowRefreshToolTip()
                    self.hideHUD()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            }
        } else {    //If the search is nil, we just reload the timeline
            self.refreshPageData(deleteIDs: true)
            self.deActivateAllFilters()
        }

    }
}

// MARK: - SubcategorySelectedDelegate extension
// Manages the sub category selected in the pop-over
extension ItemTimelineViewController: SubcategorySelectedDelegate {
    func subcategorySelected(subcategory: ItemSubCategories) {

        if isSubCategoryFilterActive == false {
            self.isSubCategoryFilterActive = true
            self.setFilterViewAsActive(filterView: self.filterSubCategoryItemView, categoryColor: subCategoryColor)
            self.currentFetchedSubcategory = subcategory

            // CASE Whenever the categories filter are inactive
            if !self.isLostFilterActive && !self.isFoundFilterActive && !self.isAdoptionFilterActive {

                //print("Case only search filter active")

                self.showHUD()
                self.itemRetrieverProtocol.filterBySubcategory(itemSubcategory: subcategory, completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })

            // CASE whenever a category filter is active (but search is inactive)
            } else if (self.isLostFilterActive || self.isFoundFilterActive || self.isAdoptionFilterActive) &&
                (self.itemSearchBar.text == nil || self.itemSearchBar.text!.trimmingCharacters(in: .whitespaces)
                .isEmpty) {

                //print("Case category filters active but no search filter active")

                self.showHUD()
                self.itemRetrieverProtocol.filterBySubcategory(itemSubcategory: subcategory, completion: {
                    self.hideHUD()
                    self.shouldShowRefreshToolTip()
                    self.itemRetrieverProtocol.fetchNewThumbnailPage()
                })
            }

            // Particular case (list of filtered item keys cant be used)
//            if (self.isLostFilterActive || self.isFoundFilterActive) && (self.itemSearchBar.text != nil &&
//                !self.itemSearchBar.text!.trimmingCharacters(in: .whitespaces).isEmpty) {
        }
    }
    //swiftlint:disable:next file_length
}
