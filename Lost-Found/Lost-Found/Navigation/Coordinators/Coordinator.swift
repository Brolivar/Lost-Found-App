//
//  Coordinator.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 18/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

// Protocol responsible of managing the ViewController Navigation
protocol Coordinator: AnyObject {

    // The main coordinator can handle another sub coordinators
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    func start()         //Method that sets, passes value and push the next ViewController

}
