//
//  LocationFilterViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 30/10/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol HandleMapSearch {
    func centerOnSearch(placemark: MKPlacemark)
}
class LocationFilterViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet private var distanceSlider: UISlider!
    @IBOutlet private var sliderValueLabel: UILabel!
    @IBOutlet private var mapKitView: MKMapView!
    @IBOutlet private var markerImage: UIImageView!

    @IBOutlet var topBarView: UIView!
//    @IBOutlet var locationSearchBar: UISearchBar!
    // Delegate for navigation within the screens of the Timeline, using the ItemManagerCoordinator
    weak var delegate: TimelineNavigatorDelegate?
    var userManagerProtocol: UserManagerProtocol!

    // Location configuration
    private var regionRadius: CLLocationDistance = 40000 // Center radius to 40 km
    private var circleRadius: CLLocationDistance = 20000 // Circle radius to 20 km (by default distance)
    private var locationManager: CLLocationManager!

    // Search bar
    private var resultSearchController: UISearchController?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.distanceSlider.value = Float(userManagerProtocol.getMaxLocationRadius())
        self.sliderValueLabel.text = "\(Int(userManagerProtocol.getMaxLocationRadius())) Km"
        // Map Set up
        self.mapKitView.delegate = self

        // Set map to item location
        let currentLatitude = self.userManagerProtocol.getCurrentUserLatitude()
        let currentLongitude = self.userManagerProtocol.getCurrentUserLongitude()

        if currentLatitude != nil && currentLongitude != nil {
            self.centerMapOnLocation(location: CLLocation(latitude: currentLatitude!, longitude: currentLongitude!))

            if CLLocationManager.locationServicesEnabled() {
                self.mapKitView.showsUserLocation = true
            }
        }

        // - Search bar
        // This code below could be implemented in the coordinator, but since its an embeded component inside
        // the current viewcontroller, it's convinient to have it configured here

        let locationSearchTable: LocationSearchTable = UIStoryboard(storyboard: .main).instantiateViewController(
            identifier: "LocationSearchTable")

        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable

        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"

        //navigationItem.titleView = resultSearchController?.searchBar
        self.topBarView.addSubview(resultSearchController!.searchBar)

        resultSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true

        //This passes along a handle of the mapView from the main View Controller onto the locationSearchTable.
        locationSearchTable.mapView = mapKitView

        locationSearchTable.handleMapSearch = self

    }

    // MARK: - Actions
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func saveLocationButtonTapped(_ sender: Any) {
        // Set new location
        let newLatitude = self.mapKitView.centerCoordinate.latitude
        let newLongitude = self.mapKitView.centerCoordinate.longitude
        self.userManagerProtocol.setCurrentLocation(userLatitude: newLatitude, userLongitude: newLongitude)

        // Set new distance filter
        let newRadius = self.distanceSlider.value
        //print("SETTING DISTANCE TO: ", newRadius)
        self.userManagerProtocol.setMaxLocationRadius(newRadius: Int(newRadius))

        dismiss(animated: true)
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let currentValue = Int(sender.value)
        self.circleRadius = CLLocationDistance(currentValue * 1000)       // Conversion from km to m
        //print("Distance filter changed to: ", currentValue)
        DispatchQueue.main.async {
            self.sliderValueLabel.text = "\(currentValue) Km"
            self.updateOverlayCircleRadius()
        }
    }

    // MARK: - Methods

    func updateOverlayCircleRadius() {
        self.mapKitView.removeOverlays(mapKitView.overlays)
        //  Region radius updated to circle radius + 1 km
        self.regionRadius = self.circleRadius * 2
        let centerLoc = CLLocation(latitude: mapKitView.centerCoordinate.latitude,
                                   longitude: mapKitView.centerCoordinate.longitude)
        self.centerMapOnLocation(location: centerLoc)
        let circle = MKCircle(center: mapKitView.centerCoordinate, radius: self.circleRadius)
        self.mapKitView.addOverlay(circle)
    }

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: self.regionRadius,
                                                  longitudinalMeters: self.regionRadius)
        self.mapKitView.setRegion(coordinateRegion, animated: true)

        // Set circle around anotation
        self.addRadiusCircle(location: location)
    }

    func addRadiusCircle(location: CLLocation) {
        let circle = MKCircle(center: location.coordinate, radius: self.circleRadius)
        self.mapKitView.addOverlay(circle)
    }
}

// MARK: - MKMapViewDelegate extension
extension LocationFilterViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            circle.fillColor = UIColor(red: 0, green: 0, blue: 255, alpha: 0.1)
            circle.lineWidth = 1
            return circle
        } else {
            return MKPolylineRenderer()
        }
    }

    // When the user stop scrolling through the map, the marker has full color again (indicating that
    // the location is selected
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        self.markerImage.alpha = 1
        //print("The location selected is: ", mapView.centerCoordinate)
        let centerLoc = CLLocation(latitude: mapView.centerCoordinate.latitude,
                                   longitude: mapView.centerCoordinate.longitude)
        self.addRadiusCircle(location: centerLoc)

    }
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.markerImage.alpha = 0.5
        self.mapKitView.removeOverlays(mapKitView.overlays)
    }
}

// MARK: - HandleMapSearch delegate
extension LocationFilterViewController: HandleMapSearch {
    func centerOnSearch(placemark: MKPlacemark) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        self.mapKitView.setRegion(region, animated: true)
    }
}
