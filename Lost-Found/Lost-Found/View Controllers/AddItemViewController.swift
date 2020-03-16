//
//  AddItemViewController.swift
//  Lost-Found
//
//  Created by Brolivar on 18/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import MapKit

class AddItemViewController: UIViewController {

    // MARK: Properties
    // Image CollectionView
    @IBOutlet private var addImageCollectionView: UICollectionView!

    // Delegate for navigation within the screens of AddItem, using the AddItemViewController
    weak var delegate: AddItemNavigatorDelegate?

    // Protocol that contains all the model's functions
    var itemManagerProtocol: ItemManagerProtocol!

    // Collection View which will contain all item's categories,
    // to select it
    // UI Item properties
    @IBOutlet private var itemName: BottonBorderedTextField!
    @IBOutlet private var itemDetails: UITextView!
    @IBOutlet private var curtainView: UIView!

    // UI Properties Border View
    @IBOutlet private var itemDetailsBorder: UIView!

    // Item category
    @IBOutlet private var categoryIcon: UIImageView!
    @IBOutlet private var subcategoryIcon: UIImageView!
    private var itemCategorySelected: ItemCategories!
    private var itemSubCategorySelected: ItemSubCategories!

    // AddImage CollectionView
    private var selectedImageCellIndex: Int!
    private var maxNumberOfImages: Int = 6
    private let placeholderImages: Int = 1

    @IBOutlet private var imageCollectionHeight: NSLayoutConstraint!
    let regionRadius: CLLocationDistance = 2000 // Center radius to 2 km
    let circleRadius: CLLocationDistance = 1500 // Circle radius to 1.5km
    var locationManager: CLLocationManager!
    @IBOutlet private var mapMarkerImage: UIImageView!

    // Map View
    @IBOutlet private var itemMapView: MKMapView!
    //private var currentLocAnnotation: MKPointAnnotation!

    // MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()

        // Map view
        self.locationManager = CLLocationManager()
        //self.currentLocAnnotation = MKPointAnnotation()

        self.itemMapView.delegate = self

        if let currentLocation = self.locationManager.location {
            if CLLocationManager.locationServicesEnabled() {
                self.itemMapView.showsUserLocation = true
                self.centerMapOnLocation(location: currentLocation)
            }
        } else {
            print("No current loc to show")
        }
//
//        let mapTapRecognizer = UITapGestureRecognizer(target: self, action: "setItemLocation:")
//        mapTapRecognizer.delegate = self
//        self.itemMapView.addGestureRecognizer(mapTapRecognizer)
    }

    // MARK: Actions
    // We navigate back to the timeline and empty the child coordinator stack
    @IBAction func backButtonTapped(_ sender: Any) {
        self.itemManagerProtocol.removeAllSelectedImages()
        self.delegate?.navigateBackToTimeline()
    }

    // We display again the popover using the middle button of the nav bar
    @IBAction func selectCategoryTapped(_ sender: Any) {
        self.delegate?.displayCategoryPopOver(categorySelectedDelegate: self)
    }

    @IBAction func selectSubcategoryTapped(_ sender: Any) {
        if self.itemCategorySelected == .adoption {         // adoption only have 1 sub category (pets)
            self.delegate?.displayCategoryPopOver(categorySelectedDelegate: self)
        } else {
            self.delegate?.displaySubCategoryPopOver(subcategorySelectedDelegate: self)
        }
    }

    // Check if fields are empty and add new item to the model
    @IBAction func addItemTapped(_ sender: Any) {

        var isFormComplete: Bool = true

        if let newItemName = self.itemName.text, !newItemName.isEmpty {
            self.itemName.setBorderBackgroundColor(colour: UIColor.lightGray)
        } else {
            print("Error: Item Name required")
            self.itemName.setBorderBackgroundColor(colour: UIColor.red)
            isFormComplete = false
        }

        if let newItemDetails = self.itemDetails.text, !newItemDetails.isEmpty {
            self.itemDetailsBorder.backgroundColor = UIColor.lightGray
        } else {
            print("Error: Item Details required")
            self.itemDetailsBorder.backgroundColor = UIColor.red
            isFormComplete = false
        }

        // The categorySelected ALWAYS have a value (form only available when selected)
        if self.itemCategorySelected == nil {
            print("Error: Item Category not selected")
            isFormComplete = false
        }

        if !isFormComplete {
            print("Woops! You missed a required argument")
            self.showCustomAlertMessage(message: "There are required fields missing", type: .error)
            return
        }

        if itemManagerProtocol.numberOfSelectedImages() == 0 {
            print("Woops! At least one image is required")
            self.showCustomAlertMessage(message: "You need to add at least one image.", type: .error)
            return
        }

        self.showHUD()

        let itemLatitude: Double = self.itemMapView.centerCoordinate.latitude
        let itemLongitude: Double = self.itemMapView.centerCoordinate.longitude

        self.itemManagerProtocol.createItem(name: self.itemName.text!,
                                            itemImages: self.itemManagerProtocol.getAllSelectedImages(),
                                            itemDetails: self.itemDetails.text,
                                            itemCategory: self.itemCategorySelected,
                                            itemSubcategory: self.itemSubCategorySelected,
                                            itemLongitude: itemLongitude,
                                            itemLatitude: itemLatitude,
                                            completion: {

                // After adding the item, we hide the hud and move forward
                self.hideHUD()
                self.showCustomAlertMessage(message: "Item created successfully", type: .success)

                // Just Right before returning to the TL, we empty all the selected
                // images from the model
                self.itemManagerProtocol.removeAllSelectedImages()

                self.delegate?.navigateBackToTimeline()
        })

    }

}

// MARK: - UITextFieldDelegate extension
extension AddItemViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - CategorySelectedDelegate extension
// Manages the category selected in the pop-over
extension AddItemViewController: CategorySelectedDelegate {

    func categorySelected(category: ItemCategories) {
        self.itemCategorySelected = category
        // Change the item category icon in the right corner
        switch category {
        case ItemCategories.adoption:
            categoryIcon.image = UIImage(named: "adoptionItemIcon@2x")
        case ItemCategories.lost:
            categoryIcon.image = UIImage(named: "lostItemIcon@2x")
        case ItemCategories.found:
            categoryIcon.image = UIImage(named: "foundItemIcon@2x")
        }

        // if the category is adoption, the subcategory is automatically pet
        if category != .adoption {
            self.delegate?.displaySubCategoryPopOver(subcategorySelectedDelegate: self)
        } else {
            self.subcategorySelected(subcategory: .pets)
        }

    }
}

// MARK: - CategorySelectedDelegate extension
// Manages the category selected in the pop-over
extension AddItemViewController: SubcategorySelectedDelegate {

    func subcategorySelected(subcategory: ItemSubCategories) {
        self.itemSubCategorySelected = subcategory
        print("THE SELCTED CATEGORY IS: ", subcategory)

        // SETUP AN ICON NEXT TO THE SUB C LABLE
        self.subcategoryIcon.image = UIImage(named: subcategory.imageName)

        self.curtainView.isHidden = true    // QUITAR Y PONERLO DESPUES
    }

}
// MARK: - UICollectionViewDelegate extension
extension AddItemViewController: UICollectionViewDelegate,
UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    // Code functionality got from:
    // swiftlint:disable:next line_length
    // https://stackoverflow.com/questions/41717115/how-to-uiimagepickercontroller-for-camera-and-photo-library-in-the-same-time-in
    // Manages the CollectionView Functionality
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        self.selectedImageCellIndex = indexPath.row
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if self.selectedImageCellIndex < self.maxNumberOfImages {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
                self.openCamera()
            }))

            alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
                self.openGallery()
            }))
        }

        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))

        // All the images added by the user can be deleted
        // The last one is always the sample "Add Picture" Placeholder Image
        if self.selectedImageCellIndex != itemManagerProtocol.selectedImagesCount() {
            alert.addAction(UIAlertAction.init(title: "Delete", style: .destructive, handler: { _ in

                self.itemManagerProtocol.removeSelectedImage(at: indexPath.row)

                if self.itemManagerProtocol.selectedImagesCount() >= self.maxNumberOfImages
                - self.placeholderImages {
                    // Deletions when at MAX IMAGE LIMIT (we just reload the data to instantiate the placeholder)
                    self.addImageCollectionView.reloadData()
                } else {
                    // Regular deletions
                    self.addImageCollectionView.deleteItems(at: [indexPath])
                }
                // AddImageCollectionView now resizes whenever a cell is added/deleted
                self.view.setNeedsLayout()
            }))
        }

        self.present(alert, animated: true, completion: nil)
    }

    // Open the camera for taking a picture directly
    // NOTE: The openCamera() and openGallery() methods could have been implemented in the AddItemCoordinator,
    // but as we are not changing views, just displaying the imagepicker, I didn't see it necessary
    func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    // Open the user's gallery for selecting the picture
    func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) {

            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.",
                                           preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - ImagePicker delegate
    // Here we create the cell, and set the selected image as a parameter
    // We also add another cell to the collectionView
    // Code partially got from:
    // https://stackoverflow.com/questions/43402895/cropping-an-image-with-imagepickercontroller-in-swift
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo
        info: [UIImagePickerController.InfoKey: Any]) {

        // Image cropped by the rectangle
        if let pickedImage = info[.editedImage] as? UIImage {
            self.updateImageDataSource(pickedImage: pickedImage)
        }
        // Original image
        else if let pickedImage = info[.originalImage] as? UIImage {
            self.updateImageDataSource(pickedImage: pickedImage)
            print("------------ ANIDIENDO IMAGEN DE: ", pickedImage.size.height)
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func updateImageDataSource(pickedImage: UIImage) {
        //imageViewPic.contentMode = .scaleToFill
        // We update the DataSource
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
            self.addImageCollectionView.performBatchUpdates({
                let indexPath = IndexPath(row: self.selectedImageCellIndex, section: 0)

                // Click placeholder image -> ADD NEW CELL
                if self.selectedImageCellIndex == (self.itemManagerProtocol.selectedImagesCount()) {
                    // Adding LAST IMAGE below limit
                    if self.itemManagerProtocol.selectedImagesCount() >= self.maxNumberOfImages -
                        self.placeholderImages {
                        self.itemManagerProtocol.addSelectedImage(selectedImg: pickedImage)
                        // Reload the item (change placeholder -> New Image)
                        self.addImageCollectionView.reloadItems(at: [indexPath])
                    // Rest of New Images
                    } else {
                        self.itemManagerProtocol.addSelectedImage(selectedImg: pickedImage)
                        self.addImageCollectionView.insertItems(at: [indexPath])
                    }

                    // AddImageCollectionView now resizes whenever a cell is added/deleted
                    self.view.setNeedsLayout()

                // REPLACE EXISTING CELL
                } else if self.selectedImageCellIndex < self.itemManagerProtocol.selectedImagesCount() {
                    //Replacing existing image
                    self.itemManagerProtocol.updateSelectedImage(selectedImg: pickedImage,
                                                                 at: self.selectedImageCellIndex!)
                    // We need to reload just the replaced item
                    self.addImageCollectionView.reloadItems(at: [indexPath])
                }

            }, completion: nil)
        })
    }
}

// MARK: - UICollectionViewDataSource extension
// Manages the Data Source of the cells.
extension AddItemViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Mientras no el numero de celdas actuales no sea mayor o igual que el numero max de imagenes
        // dejamos un placeholder (celda extra)
        if self.itemManagerProtocol.selectedImagesCount() >= self.maxNumberOfImages {
            return itemManagerProtocol.selectedImagesCount()
        } else {
            return itemManagerProtocol.selectedImagesCount() + self.placeholderImages
        }
    }

    // Creating, configuring and returning appropiate cell for given item
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Image Cell",
                                                            for: indexPath) as? AddImageCollectionViewCell
            else {
                print("The dequeued cell is not an instance of AddImageCollectionViewCell.")
                return UICollectionViewCell()
        }
        // Avoid out of index errors (cause numbersOfItemsInSection + 1 is not in the model cause
        // it's a placeholder
        if indexPath.row < itemManagerProtocol.selectedImagesCount() {
            let selectedImg = itemManagerProtocol.getSelectedImage(at: indexPath.row)
            cell.setSelectedImage(selectedImg: selectedImg)
        } else {
            //Placeholder Image
            cell.setSelectedImage(selectedImg: UIImage(named: "addImage@2x")!)
        }
        return cell
    }
}

// MARK: - UICollectionViewFlowLayout extension
// Manages the interface and animations
// code got from:
// swiftlint:disable:next line_length
// https://stackoverflow.com/questions/42437966/how-to-adjust-height-of-uicollectionview-to-be-the-height-of-the-content-size-of
extension AddItemViewController: UICollectionViewDelegateFlowLayout {

    // AddImageCollectionView now resizes whenever a cell is added/deleted
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let height = self.addImageCollectionView.collectionViewLayout.collectionViewContentSize.height
        self.imageCollectionHeight.constant = height
        self.view.layoutIfNeeded()
    }
}

// MARK: - CLLocationManagerDelegate extension

extension AddItemViewController: CLLocationManagerDelegate {

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: self.regionRadius,
                                                  longitudinalMeters: self.regionRadius)
        self.itemMapView.setRegion(coordinateRegion, animated: true)

        // Set circle around anotation
      //  self.addRadiusCircle(location: location)
    }

    func addRadiusCircle(location: CLLocation) {
        // print("setting circle to: ", location.coordinate)
        let circle = MKCircle(center: location.coordinate, radius: self.circleRadius)
        self.itemMapView.addOverlay(circle)
    }
}

// MARK: - MKMapViewDelegate extension
extension AddItemViewController: MKMapViewDelegate {

    // Custom Circle view around annotation
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
       // print("CURRENT REGION IS: ", mapView.centerCoordinate)
        //self.currentLocAnnotation.coordinate = mapView.centerCoordinate
        self.mapMarkerImage.alpha = 1
        print("The location selected is: ", mapView.centerCoordinate)

    }
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        self.mapMarkerImage.alpha = 0.5
    }
    //swiftlint:disable:next file_length
}
