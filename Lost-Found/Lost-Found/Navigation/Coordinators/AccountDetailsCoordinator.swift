//
//  AccountDetailsCoordinator.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 06/11/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import Foundation
import UIKit

class AccountDetailsCoordinator: Coordinator {

    // MARK: Properties
    private var itemDisplayerModelController: ItemDisplayerModelController
    private var userModelController: UserModelController

    //Needs to be weak to avoid retain cycle, because the Main coordinator already owns the child
    weak var parentCoordinator: MainCoordinator?

    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    // MARK: Initialization

    init(navigationController: UINavigationController, userModelController: UserModelController,
         itemsData: ItemData) {
        self.navigationController = navigationController
        self.userModelController = userModelController

        // Brand new instance of itemModelController: we don't need it to be shared with the timeline
        // so we instantiate a new one
        self.itemDisplayerModelController = ItemDisplayerModelController(userMC: self.userModelController,
                                                                         itemsData: itemsData)
    }

    func start() {

        let accDetailsViewController: AccountDetailsViewController = UIStoryboard.init(storyboard:
            .account).instantiateViewController()
        accDetailsViewController.delegate = self

        // Inyect the modelController into the protocol used by the AddItemVC, so
        // we can achieve true incapsulation (the ViewController doesn't know the ModelController)
        accDetailsViewController.itemRetrieverProtocol = self.itemDisplayerModelController
        accDetailsViewController.itemRetrieverProtocol.setFetchDelegate(fetchDelegate: accDetailsViewController)
        accDetailsViewController.userManagerProtocol = self.userModelController
        navigationController.pushViewController(accDetailsViewController, animated: true)
    }

    // MARK: - Navigation Control

    // We go back to the timeline and empty the last child of the coordinator stack
    func navigateBackToTimeline() {
        parentCoordinator?.navigateBacktoRoot()
    }

    func navigatoToSettingsView() {
        let settingsViewController: UserOptionsViewController = UIStoryboard.init(
            storyboard: .account).instantiateViewController()
        settingsViewController.delegate = self
        settingsViewController.userManagerProtocol = self.userModelController
        settingsViewController.modalPresentationStyle = .fullScreen
        self.navigationController.present(settingsViewController, animated: true)
    }

    // -- ITEM DETAILS --
    //swiftlint:disable:next function_parameter_count
    func navigateToItemDetailView(name: String, itemIndex: Int, itemDetails: String, itemCategory: ItemCategories,
                                  itemSubcategory: ItemSubCategories, createdBy: String, dateOfCreation: String) {

        let itemDetailView: ItemViewController = UIStoryboard(storyboard: .main).instantiateViewController()
        itemDetailView.myItemsDelegate = self
        // View Set-Up for the item's attributes

        itemDetailView.itemRetrieverProtocol = self.itemDisplayerModelController
        itemDetailView.userDisplayerProtocol = self.userModelController
        itemDetailView.setUp(name: name, itemIndex: itemIndex, itemDetails: itemDetails, itemCategory: itemCategory,
                             itemSubcategory: itemSubcategory, createdBy: createdBy, dateOfCreation: dateOfCreation)
        self.navigationController.pushViewController(itemDetailView, animated: true)

    }

    func goBackToAccountView() {
        self.navigationController.popViewController(animated: true)
    }

    func navigateToAddItem() {
        self.parentCoordinator?.displayAddItemViewController()
    }
}
