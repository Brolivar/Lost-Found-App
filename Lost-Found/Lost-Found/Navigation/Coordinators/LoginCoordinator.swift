//
//  LoginCoordinator.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 22/08/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit
import Firebase

/// The VC in charge of gathering login data must start login action through this protocol
protocol LoginPresenterDelegate: class {
    func signUp(with username: String, mail: String, password: String, loginResponse: @escaping (LoginResponse) -> Void)
    func login(with mail: String, password: String, loginResponse: @escaping (LoginResponse) -> Void)
}

class LoginCoordinator: Coordinator {

    // MARK: Properties

    //Needs to be weak to avoid retain cycle, because the Main coordinator already owns the child
    weak var parentCoordinator: MainCoordinator?
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    private let accountManager: AccountManager

    // MARK: Initialization

    init(navigationController: UINavigationController, loginManager: AccountManager) {
        self.navigationController = navigationController
        self.accountManager = loginManager
    }

    func start() {
        let signScreenViewController: SignScreenViewController = UIStoryboard.init(
            storyboard: .register).instantiateViewController()
        signScreenViewController.delegate = self
        self.navigationController.pushViewController(signScreenViewController, animated: false)
    }

    // MARK: Termination

    // We go back to the timeline and empty the last child of the coordinator stack
    func didCloseSignScreen() {
        parentCoordinator?.navigateBacktoRoot()
    }

    // MARK: Navigation

    func goToMailRegisterScreen() {
        let registerViewController: RegisterViewController = UIStoryboard.init(
            storyboard: .register).instantiateViewController()
        registerViewController.delegate = self
        self.navigationController.present(registerViewController, animated: true)
    }

    func goToMailLoginScreen() {
        let loginViewController: LoginViewController = UIStoryboard.init(
            storyboard: .register).instantiateViewController()
        loginViewController.delegate = self
        self.navigationController.present(loginViewController, animated: true)
    }

    func goBackToLoginScreen() {
        self.navigationController.dismiss(animated: true, completion: nil)
    }

    func goBackToTimeline() {
        self.navigationController.dismiss(animated: true, completion: nil)
        self.parentCoordinator?.navigateBacktoRoot()
    }

}

// MARK: - LoginPresenterDelegate Protocol
extension LoginCoordinator: LoginPresenterDelegate {
    func signUp(with username: String, mail: String, password: String,
                loginResponse: @escaping (LoginResponse) -> Void) {
        self.accountManager.signUp(with: username, mail: mail, password: password,
                                  loginResult: { loginState in
            loginResponse(loginState)
        })
    }

    func login(with mail: String, password: String, loginResponse: @escaping (LoginResponse) -> Void) {
        self.accountManager.login(mail: mail, password: password, loginResult: { loginState in
            loginResponse(loginState)
        })
    }

    // Google login, using firebase credentials
    func loginWithCredentials(with credentials: AuthCredential, loginResponse: @escaping (LoginResponse) -> Void) {
        self.accountManager.loginWithCredentials(credentials: credentials,
                                            loginResult: { loginState in
            loginResponse(loginState)
        })
    }

    // After autenticating with google, we need to store rest of user info: username,... in the db)
    func storeGoogleCredentiales(name: String, mail: String) {
        self.accountManager.storeGoogleCredentials(name: name, mail: mail)
    }
}
