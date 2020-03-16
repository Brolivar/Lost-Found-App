//
//  ItemTimeLineCoordinator
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 18/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

// Protocol of the Item for the navigation from and towards the ItemTimeLine
protocol TimelineNavigatorDelegate: class {
    //swiftlint:disable:next function_parameter_count
    func navigateToItemDetailView(name: String, itemIndex: Int, itemDetails: String,
                                  itemCategory: ItemCategories, itemSubcategory: ItemSubCategories,
                                  createdBy: String, dateOfCreation: String)
    func navigateBackToTimeline()
    func navigateToSlideMenu()
    func navigateToAddItem()
    func navigateToLocationFilterView()
    func displaySubCategoryFilterPopOver(subCategorySelectedDelegate: SubcategorySelectedDelegate)
}

class ItemTimelineCoordinator: Coordinator {

    // MARK: Properties
    private var itemDisplayerModelController: ItemDisplayerModelController
    private var userModelController: UserModelController
    //private var locationManager: LocationDelegate

    //Needs to be weak to avoid retain cycle, because the Main coordinator already owns the child
    weak var parentCoordinator: MainCoordinator?

    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    // MARK: Initialization

    init(navigationController: UINavigationController, itemDisplayerModelController: ItemDisplayerModelController,
         userModelController: UserModelController) {
        self.navigationController = navigationController
        self.itemDisplayerModelController = itemDisplayerModelController
        self.userModelController = userModelController
    }

    func start() {

        let timeLineVc: ItemTimelineViewController = UIStoryboard(storyboard: .main).instantiateViewController()

        timeLineVc.delegate = self

        // Inyect the modelController into the protocol used by the TimeLineController, so
        // we can achieve true incapsulation (the ViewController doesn't know the ModelController)
        timeLineVc.itemRetrieverProtocol = self.itemDisplayerModelController
        timeLineVc.itemRetrieverProtocol.setFetchDelegate(fetchDelegate: timeLineVc)
        timeLineVc.userManagerProtocol = self.userModelController
        //timeLineVc.locationManager = self.locationManager

        navigationController.pushViewController(timeLineVc, animated: true)

    }

    // MARK: Finalization

//    func didFinishAdding() {
//        parentCoordinator?.childDidFinish(self)
//    }

}

// MARK: ItemTimelineViewControllerDelegate
// Manages Navigation from ItemTimeLineViewController (to addItem/DetailItem Views
extension ItemTimelineCoordinator: TimelineNavigatorDelegate {

    // -- ITEM DETAILS --
    //swiftlint:disable:next function_parameter_count
    func navigateToItemDetailView(name: String, itemIndex: Int, itemDetails: String, itemCategory: ItemCategories,
                                  itemSubcategory: ItemSubCategories, createdBy: String, dateOfCreation: String) {

        let itemDetailView: ItemViewController = UIStoryboard(storyboard: .main).instantiateViewController()
        itemDetailView.delegate = self
        // View Set-Up for the item's attributes
        itemDetailView.itemRetrieverProtocol = self.itemDisplayerModelController
        itemDetailView.userDisplayerProtocol = self.userModelController
        itemDetailView.setUp(name: name, itemIndex: itemIndex, itemDetails: itemDetails, itemCategory: itemCategory,
                             itemSubcategory: itemSubcategory, createdBy: createdBy, dateOfCreation: dateOfCreation)
        self.navigationController.pushViewController(itemDetailView, animated: true)

    }

    // -- BACK TO TIMELINE --
    func navigateBackToTimeline() {
        navigationController.popToRootViewController(animated: true)
    }

    /**
     We don't instantiate the SlideMenu Controller because it already
     contains enough functionality to have it's own coordinator:
     We call the parent, and make it instantiate the menuCoordinator, which will receive
     the navigation request to the rest of the screens (Messages, Account...)
    **/
    func navigateToSlideMenu() {
        parentCoordinator?.displaySlideMenuViewController()
    }

    func navigateToAddItem() {
        parentCoordinator?.displayAddItemViewController()
    }

    func navigateToLocationFilterView() {
        let locationFilterView: LocationFilterViewController = UIStoryboard(storyboard:
            .main).instantiateViewController()
        locationFilterView.delegate = self
        locationFilterView.userManagerProtocol = self.userModelController

        self.navigationController.present(locationFilterView, animated: true)
    }
    //  Display the popover to select the item's subcategory
    func displaySubCategoryFilterPopOver(subCategorySelectedDelegate: SubcategorySelectedDelegate) {

        let popOverViewController: SelectSubCategoryViewController = UIStoryboard.init(
            storyboard: .main).instantiateViewController()
        popOverViewController.delegate = self
        popOverViewController.subcategorySelectedDelegate = subCategorySelectedDelegate
        self.navigationController.present(popOverViewController, animated: true)
    }

}
