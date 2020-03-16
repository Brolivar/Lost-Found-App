//
//  Extensions.swift
//  Pods-Example
//
//  Created by Jon Kent on 7/1/19.
//

import Foundation

extension NSObject: InitializableClass {}

internal extension UIView {

    @discardableResult func untransformed(_ block: () -> CGFloat) -> CGFloat {
        let transform = self.transform
        self.transform = .identity
        let value = block()
        self.transform = transform
        return value
    }

    func bringToFront() {
        self.superview?.bringSubviewToFront(self)
    }

    func untransform(_ block: () -> Void) {
        untransformed { () -> CGFloat in
            block()
            return 0
        }
    }
}

internal extension UIViewController {

    var activeViewController: UIViewController {
        switch self {
        case let navigationController as UINavigationController:
            return navigationController.visibleViewController?.activeViewController ?? self
        case let tabBarController as UITabBarController:
            return tabBarController.selectedViewController?.activeViewController ?? self
        case let splitViewController as UISplitViewController:
            return splitViewController.viewControllers.last?.activeViewController ?? self
        default:
            return presentedViewController?.activeViewController ?? self
        }
    }

    // Indicates if the menu is anywhere in the view hierarchy, even if covered by another view controller.
    @objc var isHidden: Bool {
        return presentingViewController == nil
    }
}

internal extension UIPanGestureRecognizer {

    var canSwitch: Bool {
        return !(self is UIScreenEdgePanGestureRecognizer)
    }

    var xTranslation: CGFloat {
        return view?.untransformed {
            return self.translation(in: view).x
            } ?? 0
    }

    var xVelocity: CGFloat {
        return view?.untransformed {
            return self.velocity(in: view).x
            } ?? 0
    }
}
