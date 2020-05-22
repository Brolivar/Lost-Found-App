//
//  LocationSearchTable.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 31/10/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import MapKit

class LocationSearchTable: UITableViewController {

    // MARK: - Properties

    private var matchingItems: [MKMapItem] = []
    var mapView: MKMapView?
    var handleMapSearch: HandleMapSearch?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Methods

    // Convert placemark to custom address
    func parseAddress(selectedItem: MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil ||
            selectedItem.thoroughfare != nil) &&
            (selectedItem.subAdministrativeArea != nil ||
                selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil
            && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format: "%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
}
// MARK: - UISearchResultsUpdating Delegate
extension LocationSearchTable: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
        let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()

        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}
// MARK: - LocationSearchTable extensions
extension LocationSearchTable {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // Configure cell
        let selectedItem = matchingItems[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = matchingItems[indexPath.row].placemark
        handleMapSearch?.centerOnSearch(placemark: selectedItem)
        self.dismiss(animated: true)
    }
}
