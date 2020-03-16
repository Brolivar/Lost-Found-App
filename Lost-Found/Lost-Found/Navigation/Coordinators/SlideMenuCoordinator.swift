//
//  SlideMenuCoordinator.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 24/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import SideMenu

class SlideMenuCoordinator: Coordinator {

    // MARK: Properties

    //Needs to be weak to avoid retain cycle, because the Main coordinator already owns the child
    weak var parentCoordinator: MainCoordinator?

    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    private var userModelController: UserModelController

    // MARK: Initialization

    init(navigationController: UINavigationController, userMC: UserModelController) {
        self.navigationController = navigationController
        self.userModelController = userMC
    }

    func start() {

        // Define the menu

        let menu: SlideMenuViewController = UIStoryboard.init(storyboard: .main).instantiateViewController()
        menu.delegate = self
        menu.userManagerProtocol = self.userModelController

        let slideNav = UISideMenuNavigationController(rootViewController: menu)

        slideNav.presentDuration = 0.6
        slideNav.dismissDuration = 0.6
        slideNav.leftSide = true
        slideNav.menuWidth = 280.0
        slideNav.presentationStyle = .viewSlideOutMenuIn

        // Prevent the status bar from turning black
        slideNav.statusBarEndAlpha = 0
        slideNav.isNavigationBarHidden = true

        self.navigationController.present(slideNav, animated: true)

    }

    // Display the login Screen PoPOver
    func displaySignScreen() {
        self.navigationController.dismiss(animated: false, completion: nil)
        self.parentCoordinator?.displaySignScreen()
    }

    func displayAccountDetailsView() {
        self.navigationController.dismiss(animated: true, completion: nil)
        self.parentCoordinator?.displayAccountDetailsViewController()
    }
    // MARK: Finalization

    func didCloseMenu() {
        parentCoordinator?.childDidFinish(self)
    }

    func dismissMenu() {
        self.navigationController.dismiss(animated: true, completion: nil)
    }

}
