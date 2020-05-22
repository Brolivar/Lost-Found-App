//
//  StoryBoardIdentifiable.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 18/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

/*
 * This protocol provides with the StoryboardIdentifier of the conforming ViewController to avoid hardcoding
 * its String value. It also includes a UIStoryboard extension to simplify UIViewController instantiation
 */

protocol StoryboardIdentifiable {
    static var storyboardIdentifier: String { get }
}

extension StoryboardIdentifiable where Self: UIViewController {
    static var storyboardIdentifier: String {
        return String(describing: self)
    }
}

extension UIStoryboard {
    func instantiateViewController<T: UIViewController>() -> T {
        guard let viewController = self.instantiateViewController(withIdentifier: T.storyboardIdentifier) as? T else {
            fatalError("Error: Couldn't instantiate view controller with identifier \(T.storyboardIdentifier) ")
        }
        return viewController
    }
}
