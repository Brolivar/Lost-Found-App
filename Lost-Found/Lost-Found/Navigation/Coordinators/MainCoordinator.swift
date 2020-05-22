//
//  MainCoordinator.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 18/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import CoreLocation

class MainCoordinator: NSObject, Coordinator, UINavigationControllerDelegate {

    // MARK: - Properties

    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    var itemDisplayerModelController: ItemDisplayerModelController
    var itemManagerModelController: ItemManagerModelController

    var userModelController: UserModelController
    var itemsData: ItemData

    var accountManager: AccountManager
//    var locationManager: LocationDelegate

    // MARK: Initialization

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController

        // Authentication
        let accountService = AccountService()
        self.accountManager = AccountManager(loginService: accountService)

        // Authentication
        //let locationManager: CLLocationManager = CLLocationManager()
        //self.locationManager = LocationDelegate(locationManager: locationManager)

        // Model
        self.itemsData = ItemData()
        self.userModelController = UserModelController(accManager: accountManager)
        self.itemDisplayerModelController = ItemDisplayerModelController(userMC: userModelController,
                                                                         itemsData: itemsData)
        self.itemManagerModelController = ItemManagerModelController(userMC: userModelController, itemsData: itemsData)

    }

    // When the MainCoordinator starts, it instantiates the child that manages the
    // Item Timeline, adding or displaying items.
    func start() {
        // In case we change ViewControllers, the MainCoordinator becomes the delegate
        navigationController.delegate = self
        navigationController.setNavigationBarHidden(true, animated: true)
        let child = ItemTimelineCoordinator(navigationController: navigationController,
                                            itemDisplayerModelController: self.itemDisplayerModelController,
                                            userModelController: self.userModelController)

        child.parentCoordinator = self
        childCoordinators.append(child)
        child.start()
    }

    // We navigate from any page to the FIRST SUB-COORDINATOR (WHICH IS THE ROOT OF THE PROJECT)
    // We don't need to remove the child-coordinator of the Timeline, since we are coming back to it
    func navigateBackToTimeline() {
        navigationController.popToRootViewController(animated: true)
        //childCoordinators.removeLast()
    }

    // We navigate from any page to the FIRST SUB-COORDINATOR (WHICH IS THE ROOT OF THE PROJECT)
    // In this version we are coming from a coordinator different than the ItemTimeLineCoordinator
    // and we need to remove the previous coordinator
    func navigateBacktoRoot() {
        navigationController.popToRootViewController(animated: true)
        childCoordinators.removeLast()
    }

    // Display the Slide Out Menu, and prepare to control its interactions
    func displaySlideMenuViewController() {
        let child = SlideMenuCoordinator(navigationController: navigationController, userMC: self.userModelController)
        child.parentCoordinator = self
        childCoordinators.append(child)
        child.start()
    }

    func displayAccountDetailsViewController() {
        let child = AccountDetailsCoordinator(navigationController: navigationController, userModelController:
            self.userModelController, itemsData: self.itemsData)
        child.parentCoordinator = self
        childCoordinators.append(child)
        child.start()
    }

    // Display the login Screen, and prepare to control its interactions
    func displaySignScreen() {
        let child = LoginCoordinator(navigationController: navigationController, loginManager: self.accountManager)
        child.parentCoordinator = self
        childCoordinators.append(child)
        child.start()
    }

    // Display the AddItemViewController, and prepare to control its interactions
    func displayAddItemViewController() {
        let child = AddItemCoordinator(navigationController: navigationController,
                                       itemManagerModelController: self.itemManagerModelController)
        child.parentCoordinator = self
        childCoordinators.append(child)
        child.start()
    }

    // Generic Child Terminating Method
    func childDidFinish(_ child: Coordinator?) {
        for (index, coordinator) in childCoordinators.enumerated() where coordinator === child {
            childCoordinators.remove(at: index)
            break
        }
    }

}
