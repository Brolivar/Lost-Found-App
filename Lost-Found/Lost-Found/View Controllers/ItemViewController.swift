//
//  ItemViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 16/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import Kingfisher
import ImageSlideshow
import MapKit
import MessageUI
import FacebookShare

class ItemViewController: UIViewController {

    // MARK: Properties

    // Delegate for navigation within the screens of the Timeline, using the ItemManagerCoordinator
    weak var delegate: TimelineNavigatorDelegate?
    // We need another delegate when the item is accesses from the account details panel
    weak var myItemsDelegate: AccountDetailsCoordinator?

    var itemRetrieverProtocol: ItemDisplayerProtocol!
    var userDisplayerProtocol: UserDisplayerProtocol!

    @IBOutlet private var itemNameLabel: UILabel!
    //@IBOutlet private var itemImage: UIImageView!
    // Image Slider
    @IBOutlet private var itemImageSlideshow: ImageSlideshow!

    @IBOutlet private var itemDetails: UITextView!
    @IBOutlet private var itemCategoryLabel: UILabel!
    @IBOutlet private var itemCategoryImage: UIImageView!
    @IBOutlet private var itemSubcategoryImage: UIImageView!

    @IBOutlet private var mapKitView: MKMapView!
    @IBOutlet private var locationLabel: UILabel!

    // Creation time and user
    @IBOutlet private var creationTimeLabel: UILabel!
    @IBOutlet private var createdByUsername: UILabel!

    private let regionRadius: CLLocationDistance = 1500 // Center radius to 1.5 km
    private let circleRadius: CLLocationDistance = 400 // Circle radius to 400m
    private var locationManager: CLLocationManager!

    // Public Variables to get/set the outlet values
    var itemNm: String = ""
    var itemDtls: String = ""

    // Category Label and img
    var itemCtgrLbl: String = ""
    var itemCtgrImg: String = ""
    var itemSbCtgrImg: String = ""
    var itemCrtdBy: String = ""
    var itemDateOfCrtn: String = ""

   // var itemImagesURL: [URL] = []
    var itemIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isTranslucent = true
        //navigationItem.title = itemNm
        self.itemNameLabel.text = itemNm
        self.itemDetails.text = itemDtls

        self.itemCategoryLabel.text = itemCtgrLbl
        self.itemCategoryImage.image = UIImage(named: itemCtgrImg)
        if itemSbCtgrImg != "" {
            self.itemSubcategoryImage.image = UIImage(named: itemSbCtgrImg)
        }

        // Set Item date of creation and using our date extension to print the "created X time ago"
        let itemDateFormatter = DateFormatter()
        itemDateFormatter.timeZone = TimeZone.current
        itemDateFormatter.dateFormat = "HH-mm-dd-MM-yyyy"
        let date = itemDateFormatter.date(from: itemDateOfCrtn)
        self.creationTimeLabel.text = date?.timeAgoDisplay()
        // Image Slide Show: PageControl, Gestures and content mode

        self.itemImageSlideshow.pageIndicatorPosition = .init(horizontal: .right(padding: 2.0), vertical: .bottom)

        self.itemImageSlideshow.circular = false

        // Gesture to make the image go full screen
        let fullScreenGesture = UITapGestureRecognizer(target: self, action:
            #selector(ItemViewController.didTapImage))
        itemImageSlideshow.addGestureRecognizer(fullScreenGesture)

        self.itemImageSlideshow.activityIndicator = DefaultActivityIndicator()
        self.itemImageSlideshow.contentScaleMode = .scaleToFill

        self.itemRetrieverProtocol.getItemImages(at: itemIndex, completion: { [weak self] imagesURLs in

            guard let weakself = self else { return }

            var imageSource: [InputSource] = []

            for image in imagesURLs {
                if let imgURL = image {
                    imageSource.append(KingfisherSource(url: imgURL))
                } else {
                    // If the URL is empty, we set an error image
                    print("Woops! The image couldn't be loaded.")
                    imageSource.append(ImageSource(image: #imageLiteral(resourceName: "404Error")))
                }
            }

            weakself.itemImageSlideshow.setImageInputs(imageSource)

        })

        // Map Set up
        self.mapKitView.delegate = self
        // Set map to item location
        let currentLatitude = self.itemRetrieverProtocol.getItemLatitude(at: itemIndex)
        let currentLongitude =  self.itemRetrieverProtocol.getItemLongitude(at: itemIndex)
        self.centerMapOnLocation(location: CLLocation(latitude: currentLatitude, longitude: currentLongitude))

        self.convertLatLongToAddress(latitude: currentLatitude, longitude: currentLongitude, completion: { address in
            self.locationLabel.text = address
        })

        self.userDisplayerProtocol.getUsernameByID(userID: itemCrtdBy, completion: { createdBy in
            self.createdByUsername.text = createdBy
        })
    }

    // MARK: Initialization
    //swiftlint:disable:next function_parameter_count
    func setUp(name: String, itemIndex: Int, itemDetails: String, itemCategory: ItemCategories,
               itemSubcategory: ItemSubCategories, createdBy: String, dateOfCreation: String) {

        guard !name.isEmpty else {
            print("Unable to read item's label")
            return
        }

        guard !itemDetails.isEmpty else {
            print("Unable to read item's description")
            return
        }

        switch itemCategory {
        case ItemCategories.adoption:
            itemCtgrLbl = "Adoption Item"
            itemCtgrImg = "adoptionItemIcon@2x"

        case ItemCategories.lost:
            itemCtgrLbl = "Lost Item"
            itemCtgrImg = "lostItemIcon@2x"

        case ItemCategories.found:
            itemCtgrLbl = "Found Item"
            itemCtgrImg = "foundItemIcon@2x"
        }

        // We display the PET ICON just if the CATEGORY IS NOT ADOPTION
        // This is: because every pet is not for adoption
        // BUT EVERY adoption item IS A PET
        if  itemCategory != .adoption {
            self.itemSbCtgrImg = itemSubcategory.imageName
        }
        // Assign to stored variables

        self.itemNm = name
        self.itemDtls = itemDetails
        self.itemIndex = itemIndex
        self.itemDateOfCrtn = dateOfCreation
        self.itemCrtdBy = createdBy
    }

    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: Any) {
        if self.delegate != nil {
            print("BACK TO TIMELINE")
            self.delegate?.navigateBackToTimeline()
        } else if self.myItemsDelegate != nil {
            print("BACK TO SETTINGS")
            self.myItemsDelegate?.goBackToAccountView()
        }
    }

    @objc func didTapImage() {
        self.itemImageSlideshow.presentFullScreenController(from: self)
    }

    // Social Share buttons

    @IBAction func shareGmailTapped(_ sender: Any) {

        let emailTitle: String = "Check this " + itemCtgrLbl
        var messageBody = "Check the " + itemNm + " which was found neaby."

        // The message changes depending of category
        if self.itemCtgrLbl == "Found Item" && self.locationLabel.text != nil {
            messageBody = "Check this item which was found in " + self.locationLabel.text! + " "
                + (self.creationTimeLabel.text ?? "")
        } else if self.itemCtgrLbl == "Lost Item" {
            messageBody = "Check this item which was lost in " + self.locationLabel.text! + " "
                + (self.creationTimeLabel.text ?? "")
        } else if self.itemCtgrLbl == "Adoption Item" {
            messageBody = "This litle friend is looking for a owner in " + self.locationLabel.text! + " "
                + (self.creationTimeLabel.text ?? "")
        }

        let mailComposser: MFMailComposeViewController = MFMailComposeViewController()
        mailComposser.mailComposeDelegate = self
        mailComposser.setSubject(emailTitle)
        mailComposser.setMessageBody(messageBody, isHTML: false)

        // Share currently displayed image
        let imageData: Data?
        if let image = self.itemImageSlideshow.currentSlideshowItem?.imageView.image {
            imageData = image.pngData()!
            mailComposser.addAttachmentData(imageData!, mimeType: "image/png", fileName: "itemImage.png")
        }
        mailComposser.modalPresentationStyle = .fullScreen
        self.present(mailComposser, animated: true, completion: nil)
    }
    @IBAction func shareFacebookTapped(_ sender: Any) {
        let shareContent = ShareLinkContent()
         // shareContent.contentURL = URL.init(string: "")! //here will be the future app link
         shareContent.quote = "Check the " + itemNm + " which was found neaby."
         ShareDialog(fromViewController: self, content: shareContent, delegate: self).show()
    }
    @IBAction func shareWhatsappTapped(_ sender: Any) {

        // Text needs to be URL encoded.
        var message: String = "Check the " + itemNm + " which was found neaby."

        // The message changes depending of category
        if self.itemCtgrLbl == "Found Item" && self.locationLabel.text != nil {
            message = "Check this item which was found in " + self.locationLabel.text! + " "
                + (self.creationTimeLabel.text ?? "")
        } else if self.itemCtgrLbl == "Lost Item" {
            message = "Check this item which was lost in " + self.locationLabel.text! + " "
                + (self.creationTimeLabel.text ?? "")
        } else if self.itemCtgrLbl == "Adoption Item" {
            message = "This litle friend is looking for a owner in " + self.locationLabel.text! + " "
                + (self.creationTimeLabel.text ?? "")
        }
        // Right know, whatsapp only allows image share OR text share, but not both, so we choose text share
        // and in the future a link to the app
        let urlWhats = "whatsapp://send?text=\(message)"

        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
            if let whatsappURL = NSURL(string: urlString) {
                if UIApplication.shared.canOpenURL(whatsappURL as URL) {
                    UIApplication.shared.open(whatsappURL as URL)
                } else {
                    print("please install Whatsapp")
                }
            }
        }
    }

    // Open chat
    @IBAction func chatButtonTapped(_ sender: Any) {
    }
    // MARK: - Methods

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: self.regionRadius,
                                                  longitudinalMeters: self.regionRadius)
        self.mapKitView.setRegion(coordinateRegion, animated: true)

        // Set circle around anotation
        self.addRadiusCircle(location: location)
    }

    func addRadiusCircle(location: CLLocation) {
        //print("setting circle to: ", location.coordinate)
        let circle = MKCircle(center: location.coordinate, radius: self.circleRadius)
        self.mapKitView.addOverlay(circle)
    }

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

extension ItemViewController: SharingDelegate {
    func sharer(_ sharer: Sharing, didCompleteWithResults results: [String: Any]) {
        if sharer.shareContent.pageID != nil {
            print("Share: Success")
        }
    }
    func sharer(_ sharer: Sharing, didFailWithError error: Error) {
        print("Share: Fail")
    }
    func sharerDidCancel(_ sharer: Sharing) {
        print("Share: Cancel")
    }
}
// MARK: - MKMapViewDelegate extension
extension ItemViewController: MKMapViewDelegate {

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

}

// MARK: - MFMailComposeViewControllerDelegate extension
extension ItemViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        switch result {
        case .cancelled:
            print("Mail cancelled")
        case .saved:
            print("Mail saved")
        case .sent:
            print("Mail sent")
        case .failed:
            print("Mail sent failure")
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
}
