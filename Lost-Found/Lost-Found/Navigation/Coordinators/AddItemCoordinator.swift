//
//  AddItemCoordinator.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 25/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

// Protocol in charge of navigation and comunication from and towards the AddItemview
protocol AddItemNavigatorDelegate: class {
    func navigateBackToTimeline()
    func displayCategoryPopOver(categorySelectedDelegate: CategorySelectedDelegate)
    func displaySubCategoryPopOver(subcategorySelectedDelegate: SubcategorySelectedDelegate)
}

// Protocol to communicate category selected in the AddCategoryVC to AddItemVC
protocol CategorySelectedDelegate: class {
    func categorySelected(category: ItemCategories)
}

protocol SubcategorySelectedDelegate: class {
    func subcategorySelected(subcategory: ItemSubCategories)
}

class AddItemCoordinator: Coordinator {

    // MARK: Properties
    private var itemManagerModelController: ItemManagerModelController

    //Needs to be weak to avoid retain cycle, because the Main coordinator already owns the child
    weak var parentCoordinator: MainCoordinator?

    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    // MARK: Initialization

    init(navigationController: UINavigationController, itemManagerModelController: ItemManagerModelController) {
        self.navigationController = navigationController
        self.itemManagerModelController = itemManagerModelController
    }

    func start() {

        let addItemVc: AddItemViewController = UIStoryboard.init(storyboard: .main).instantiateViewController()
        addItemVc.delegate = self

        // Inyect the modelController into the protocol used by the AddItemVC, so
        // we can achieve true incapsulation (the ViewController doesn't know the ModelController)
        addItemVc.itemManagerProtocol = self.itemManagerModelController

        navigationController.pushViewController(addItemVc, animated: true)
        //Present category selector as well after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
            self.displayCategoryPopOver(categorySelectedDelegate: addItemVc)
        })
    }

    // MARK: Finalization

    //    func didFinishAdding() {
    //        parentCoordinator?.childDidFinish(self)
    //    }

}

// MARK: addItemNavigatorDelegate
// Manages Navigation from and towards addItemViewController
extension AddItemCoordinator: AddItemNavigatorDelegate {

    //  Display the popover to select the item's category
    func displayCategoryPopOver(categorySelectedDelegate: CategorySelectedDelegate) {
        let popOverViewController: AddCategoryViewController = UIStoryboard.init(
            storyboard: .main).instantiateViewController()
        popOverViewController.delegate = self
        popOverViewController.categorySelectedDelegate = categorySelectedDelegate
        self.navigationController.present(popOverViewController, animated: true)
    }

    //  Display the popover to select the item's subcategory
    func displaySubCategoryPopOver(subcategorySelectedDelegate: SubcategorySelectedDelegate) {
        let popOverViewController: SelectSubCategoryViewController = UIStoryboard.init(
            storyboard: .main).instantiateViewController()
        popOverViewController.delegate = self
        popOverViewController.subcategorySelectedDelegate = subcategorySelectedDelegate
        self.navigationController.present(popOverViewController, animated: true)
    }

    // We go back to the timeline and empty the last child of the coordinator stack
    func navigateBackToTimeline() {
        parentCoordinator?.navigateBacktoRoot()
    }

    func navigateToTimelineAfterAddition() {
        parentCoordinator?.navigateBacktoRoot()

    }

}
