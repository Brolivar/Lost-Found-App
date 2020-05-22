//
//  AlertMessage.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 18/09/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import SwiftMessages

protocol AlertMessage: class {
    func showAlertError(title: String?, message: String?, handler: (() -> Void)?)
    func showAlertMessage(title: String?, message: String?, highlightedTitle: Bool, actions: [UIAlertAction])

    // SwiftMessages Library custom messages
    func showCustomAlertMessage(message: String, type: Theme)
}

extension AlertMessage where Self: UIViewController {

    func showAlertMessage(title: String?, message: String?, highlightedTitle: Bool=false, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)

        let titleFont: [NSAttributedString.Key: Any]
        if highlightedTitle {
            titleFont = [NSAttributedString.Key.font: UIFont(name: "Avenir-Heavy", size: 17.0)!]
        } else {
            titleFont = [NSAttributedString.Key.font: UIFont(name: "Avenir-Medium", size: 17.0)!]
        }
        let messageFont = [NSAttributedString.Key.font: UIFont(name: "Avenir Medium", size: 14.0)!]

        if let alertTitle = title {
            let titleAttrString = NSMutableAttributedString(string: alertTitle, attributes: titleFont)
            alert.setValue(titleAttrString, forKey: "attributedTitle")
        }

        if let alertMessage = message {
            let messageAttrString = NSMutableAttributedString(string: alertMessage, attributes: messageFont)
            alert.setValue(messageAttrString, forKey: "attributedMessage")
        }

        alert.view.tintColor = UIColor.black

        for action in actions {
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }

    func showAlertError(title: String?, message: String?, handler: (() -> Void)?=nil) {
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)

        let titleFont = [NSAttributedString.Key.font: UIFont(name: "Avenir-Medium", size: 17.0)!]
        let messageFont = [NSAttributedString.Key.font: UIFont(name: "Avenir Medium", size: 14.0)!]

        if let alertTitle = title {
            let titleAttrString = NSMutableAttributedString(string: alertTitle, attributes: titleFont)
            alert.setValue(titleAttrString, forKey: "attributedTitle")
        }

        if let alertMessage = message {
            let messageAttrString = NSMutableAttributedString(string: alertMessage, attributes: messageFont)
            alert.setValue(messageAttrString, forKey: "attributedMessage")
        }

        alert.view.tintColor = UIColor.black
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            handler?()
        }))
        self.present(alert, animated: true, completion: nil)
    }

    // Swift Custom Messages
    func showCustomAlertMessage(message: String, type: Theme) {
        let formErrorView = MessageView.viewFromNib(layout: .statusLine)
        formErrorView.configureTheme(type)
        formErrorView.configureDropShadow()
        formErrorView.layer.opacity = 0.9

        formErrorView.configureContent(body: message)
        formErrorView.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20,
                                                           bottom: 20, right: 20)

        (formErrorView.backgroundView as? CornerRoundingView)?.cornerRadius = 10

        // Show the message.
        SwiftMessages.show(view: formErrorView)
    }

}
