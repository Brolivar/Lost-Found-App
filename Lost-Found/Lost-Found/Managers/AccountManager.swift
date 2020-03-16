//
//  AccountManager.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 19/09/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//
import CoreLocation
import Firebase

class AccountManager {

    var loggedUser: User?
    private let loginService: LoginServiceProtocol

    // MARK: - Initialization
    init(loginService: LoginServiceProtocol) {
        self.loginService = loginService

        if self.loginService.userLogged() && loggedUser?.userID == nil {
            print("Updating user's details")
            self.updateLoggedUser {
                print("User's details updated")
            }
        }
    }

    // MARK: - Class Methods

    func signUp(with username: String, mail: String, password: String,
                loginResult: @escaping (LoginResponse) -> Void) {

        self.loginService.signUp(with: username, mail: mail, password: password,
                                 loginResponse: { [weak self] loginError in

            guard let weakself = self else { return }

            // In case login is successful, we store the user properties, so the UserMC can retrieve it
            if loginError == .loginValid {
                let uid = weakself.getCurrentUserID()
                weakself.loggedUser = User(usId: uid, uName: username, uMail: mail)
            }
            loginResult(loginError)
        })
    }

    func loginWithCredentials(credentials: AuthCredential, loginResult: @escaping (LoginResponse)
        -> Void) {

        self.loginService.loginWithCredentials(with: credentials,
            loginResponse: { loginError in

            // In case login is successful, we store the user properties, so the UserMC can retrieve it
            if loginError == .loginValid {
                //let uid = weakself.getCurrentUserID()
                //weakself.loggedUser = User(usId: uid, uName: username, uMail: mail)
            }
            loginResult(loginError)
        })
    }

    func storeGoogleCredentials(name: String, mail: String) {
        let uid = self.getCurrentUserID()
        self.loginService.storeCredentials(userId: uid, userName: name, userMail: mail)
        self.loggedUser = User(usId: uid, uName: name, uMail: mail)
    }

    func login(mail: String, password: String,
               loginResult: @escaping (LoginResponse) -> Void) {

        self.loginService.login(with: mail, password: password, loginResponse: { loginError in

            if loginError == .loginValid {
                let uid = self.getCurrentUserID()
                // We get the username of the user, in order to create the loggedUser Object that
                // will be used by the UserMC

                self.loginService.getUsername(completion: { username in
                    self.loggedUser = User(usId: uid, uName: username, uMail: mail)
                })
            }
            loginResult(loginError)
        })
    }
    // Get the currentUser ID using the object Auth
    // to secure that: currentLoged user in the UserMC is the same
    func getCurrentUserID() -> String {
        return self.loginService.getCurrentUserID()
    }

    func userLogged() -> Bool {
        return self.loginService.userLogged()
    }

    func signOutUser() {
        self.loginService.signOut()
    }

    // Whenever the App is closed, the object self.loggedUser become empty, so
    // if it's open again while the login persists, the object has to update again
    func updateLoggedUser(completionHandler: @escaping () -> Void) {
        let uid = self.loginService.getCurrentUserID()
        let mail = self.loginService.getCurrentUserMail()
        self.loginService.getUsername(completion: { username in
            self.loggedUser = User(usId: uid, uName: username, uMail: mail)
            completionHandler()
        })
    }

    func getUserName() -> String {
        if self.loggedUser != nil {
            return self.loggedUser!.username
        } else {
            return ""
        }
    }

    func retrieveUsernameByID(userID: String, completionHandler: @escaping (String) -> Void) {

        self.loginService.getUsernameByID(userID: userID, completion: { username in
            completionHandler(username)
        })
    }
}
