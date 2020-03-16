//
//  AccountDetailsViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 06/11/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import CoreLocation

class AccountDetailsViewController: UIViewController {

    // MARK: - Properties
    // Delegate for navigation within the screens of AccDetails
    weak var delegate: AccountDetailsCoordinator?

    // Protocol that contains all the model's functions
    var itemRetrieverProtocol: ItemDisplayerProtocol!
    var userManagerProtocol: UserManagerProtocol!

    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var usernameIcon: UIImageView!
    @IBOutlet private var userLocationLabel: UILabel!
    @IBOutlet private var numberOfItemsLabel: UILabel!

    @IBOutlet private var userItemsCollectionView: UICollectionView!
    // MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()

        // UI Set-up
        self.usernameLabel.text = self.userManagerProtocol.getUsername()

        // Set map to item location
        let currentLatitude = self.userManagerProtocol.getCurrentUserLatitude()
        let currentLongitude =  self.userManagerProtocol.getCurrentUserLongitude()

        if currentLatitude != nil && currentLongitude != nil {
            self.convertLatLongToAddress(latitude: currentLatitude!, longitude: currentLongitude!,
                                         completion: { address in
                self.userLocationLabel.text = address
            })
        }

        self.userItemsCollectionView.delegate = self
        self.userItemsCollectionView.prefetchDataSource = self

        // Collection View Cell Set-Up
        let cellSize = CGSize(width: (view.frame.width / 2) - 30, height: 200)
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.minimumLineSpacing = 20.0
        layout.minimumInteritemSpacing = 5.0
        self.userItemsCollectionView.setCollectionViewLayout(layout, animated: true)

        self.userItemsCollectionView.reloadData()

        // Load Pages
        print("LOADING USER ITEMS......")
        self.showHUD()
        self.itemRetrieverProtocol.getByCurrentUserItems(completion: {
            self.hideHUD()
            self.numberOfItemsLabel.text = String(self.itemRetrieverProtocol.totalCount())
            //self.shouldShowRefreshToolTip()
            self.itemRetrieverProtocol.fetchNewThumbnailPage()
        })

    }

    // MARK: - Actions

    @IBAction func backButtonTapped(_ sender: Any) {
        self.delegate?.navigateBackToTimeline()
    }

    @IBAction func editButtonTapped(_ sender: Any) {
    }

    @IBAction func settingsButtonTapped(_ sender: Any) {
        self.delegate?.navigatoToSettingsView()
    }

    @IBAction func addItemButtonTapped(_ sender: Any) {
        if self.userManagerProtocol.userLogged() {
            self.delegate?.navigateToAddItem()
        } else {
            self.showCustomAlertMessage(message: "You need to be logged in order to create an item", type: .error)
        }
    }

    // MARK: - Methods

    func convertLatLongToAddress(latitude: Double, longitude: Double, completion: @escaping (String) -> Void) {

        let geoCoder = CLGeocoder()
        var finalAddress: String = ""

        let location = CLLocation(latitude: latitude, longitude: longitude)
        geoCoder.reverseGeocodeLocation(location, completionHandler: { (placemarks, _) -> Void in

            // Place details
            var placeMark: CLPlacemark!
            placeMark = placemarks?[0]

            if let postalCode = placeMark.postalCode {
                //print(postalCode)
                finalAddress = postalCode
                if let subLocality = placeMark.subLocality {
                    //print(subLocality)
                    finalAddress += ", " + subLocality
                    completion(finalAddress)
                }
            }

        })
    }
}
// MARK: - UICollectionViewDelegate extension
// Manages the Data Source of the cells.
extension AccountDetailsViewController: UICollectionViewDelegate {

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
// MARK: - UICollectionViewDataSource extension
// Manages the Data Source of the cells.
extension AccountDetailsViewController: UICollectionViewDataSource {

    // Get number of sample items
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemRetrieverProtocol.totalCount()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell",
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
}
// MARK: - ItemModelFetchDelegate Delegate
extension AccountDetailsViewController: ItemModelFetchDelegate {

    func onFetchCompleted(with newIndexPathsToReload: [IndexPath]?) {
        guard let newIndexPathsToReload = newIndexPathsToReload else {
//            print("WE ARE IN THE FIRST PAGE")
            userItemsCollectionView.reloadData()
            self.hideHUD()
            return
        }

        let indexPathsToReload = visibleIndexPathsToReload(intersecting: newIndexPathsToReload)
        userItemsCollectionView.reloadItems(at: indexPathsToReload)
    }
}
// MARK: - UICollectionViewDataSourcePrefetching Delegate
extension AccountDetailsViewController: UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {

        if indexPaths.contains(where: isLoadingCell) {
            print("Getting new PAGE of USER items....")
            self.itemRetrieverProtocol.fetchNewItemPage(completion: {})

        } else if indexPaths.contains(where: isLoadingCellThumbnail) {
            print("Getting new PAGE of USER thumbnails...")
            self.itemRetrieverProtocol.fetchNewThumbnailPage()
        }
    }
}

// MARK: - AccountDetailsViewController Delegate
private extension AccountDetailsViewController {

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

        let indexPathsForVisibleRows = self.userItemsCollectionView.indexPathsForVisibleItems
        let indexPathsIntersection = Set(indexPathsForVisibleRows).intersection(indexPaths)
        return Array(indexPathsIntersection)
    }
}
