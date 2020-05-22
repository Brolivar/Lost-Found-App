//
//  ProgressHUD.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 18/09/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import SVProgressHUD

protocol UIActivityHUD: class {
    func showHUD(status: String?, dimBackground: Bool, containerView: UIView?)
    func configureHUD(backgroundColor: UIColor, ringRadius: CGFloat?, ringThickness: CGFloat?, ringColor: UIColor?)
    func hideHUD()
}

// MARK: - GPMessageViewProtocol default implementation for UIViewController subclasses

extension UIActivityHUD where Self: UIViewController {

    func configureHUD(backgroundColor: UIColor, ringRadius: CGFloat?=nil,
                      ringThickness: CGFloat?=nil, ringColor: UIColor?=nil) {
        SVProgressHUD.setBackgroundColor(backgroundColor)

        if let ringColor = ringColor {
            SVProgressHUD.setForegroundColor(ringColor)
        }

        if let radius = ringRadius {
            SVProgressHUD.setRingNoTextRadius(radius)
        }

        if let thickness = ringThickness {
            SVProgressHUD.setRingThickness(thickness)
        }
    }

    func showHUD(status: String?=nil, dimBackground: Bool=false, containerView: UIView?=nil) {
        SVProgressHUD.setContainerView(containerView ?? self.view)
        SVProgressHUD.show(withStatus: status)
        SVProgressHUD.setDefaultMaskType(dimBackground ? .black : .clear)
    }

    func hideHUD() {
        SVProgressHUD.dismiss()
        //On Hide - reset style
        SVProgressHUD.setDefaultStyle(.light)
        // Default values
        SVProgressHUD.setRingThickness(2.0)
        SVProgressHUD.setRingNoTextRadius(24.0)
    }
}
