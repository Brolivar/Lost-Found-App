//
//  AccountService.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 19/09/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import Firebase

protocol LoginServiceProtocol {
    func signUp(with username: String, mail: String, password: String,
                loginResponse: @escaping (LoginResponse) -> Void)
    func login(with mail: String, password: String,
               loginResponse: @escaping (LoginResponse) -> Void)

    func loginWithCredentials(with credentials: AuthCredential, loginResponse: @escaping (LoginResponse) -> Void)
    func userLogged() -> Bool
    func signOut()
    func storeCredentials(userId: String, userName: String, userMail: String)

    // GET - SET
    func getCurrentUserID() -> String
    func getUsername(completion: @escaping (String) -> Void)
    func getCurrentUserMail() -> String
    func getUsernameByID(userID: String, completion: @escaping (String) -> Void)
}
// All possible responses for signing up, as well as signing in
enum LoginResponse {
    // Sign in
    case invalidEmail
    case emailInUse
    case loginError
    case loginValid
    // Login
    case wrongPassword
}

// In this object we log the new users, along with its attributes to
// the db (firebase)
class AccountService {

    // MARK: - Stored Properties
    private let usersRef = Database.database().reference(withPath: FirebasePath.Users.users.path())

    // MARK: - Class Methods

    // Method STILL NOT USED
    func checkCredentials(userID: String) -> Bool {
        //let newUsersRef = self.usersRef.child(userID)
        var exists = false

        usersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.hasChild(userID) {
                exists = true
                print("El usuario tiene su objeto propio en firebase")
            } else {
                exists = false      // not really neccessary
                print("El usuario no tiene objeto propio en firebase")
            }
        })
        return exists
    }

}

// MARK: - LoginServiceProtocol implementation
extension AccountService: LoginServiceProtocol {

    func signUp(with username: String, mail: String, password: String,
                loginResponse: @escaping (LoginResponse) -> Void) {
            // After checking empty fields, we create the user
            Auth.auth().createUser(withEmail: mail,
            password: password) { [weak self] _, error in
                guard self != nil else { return }

                if error != nil {
                    if let errCode = AuthErrorCode(rawValue: error!._code) {
                        switch errCode {
                        case .invalidEmail:
                            print("Invalid Email")
                            loginResponse(.invalidEmail)
                        case .emailAlreadyInUse:
                            print("Email already in use.")
                            loginResponse(.emailInUse)
                        default:
                            print("Create User Error: \(errCode)")
                            loginResponse(.loginError)
                        }
                    }
                } else {
                    print("Sign in succesful")
                    // We still need to authenticathe the new user, so we
                    // call sign in
                    Auth.auth().signIn(withEmail: mail, password: password)

                    let userID = Auth.auth().currentUser!.uid
                    // We create a table in the DB with all the extra info, like username
                    self?.storeCredentials(userId: userID, userName: username,
                                                    userMail: mail)

                    loginResponse(.loginValid)
                }
            }
    }

    func storeCredentials(userId: String, userName: String, userMail: String) {

        // Create a child reference
        // The key value is the user's FIREBASE ID
        let newUser = User(usId: userId, uName: userName, uMail: userMail)
        let newUsersRef = self.usersRef.child(userId)

        // Set Value expects a Dictionary, so a helper function is called
        // to turn it into dictionary
        newUsersRef.setValue(newUser.toAnyObject())
    }

    func loginWithCredentials(with credentials: AuthCredential, loginResponse: @escaping (LoginResponse) -> Void) {

        Auth.auth().signIn(with: credentials) { [weak self] _, error in

            guard self != nil else { return }

            if error != nil {
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    switch errCode {
                    case .invalidEmail:
                        print("Invalid Email")
                        loginResponse(.invalidEmail)
                    case .emailAlreadyInUse:
                        print("Email already in use.")
                        loginResponse(.emailInUse)
                    default:
                        print("Create User Error: \(errCode)")
                        loginResponse(.loginError)
                    }
                }
            } else {
                print("Google Sign in succesful")
                //let userID = Auth.auth().currentUser!.uid

                // We create a table in the DB with all the extra info, like username
//                self?.storeCredentials(userId: userID, userName: username,
//                                                userMail: mail)

                loginResponse(.loginValid)
            }
        }

    }

    func login(with mail: String, password: String, loginResponse: @escaping (LoginResponse) -> Void) {

        Auth.auth().signIn(withEmail: mail,
                           password: password) { [weak self] _, error in

            guard self != nil else { return }

            if error != nil {
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    switch errCode {
                    case .wrongPassword:
                        print("Wrong password.")
                        loginResponse(.wrongPassword)
                    case .invalidEmail:
                        print("Invalid email.")
                        loginResponse(.invalidEmail)
                    default:
                        print("Login User Error: \(errCode)")
                        loginResponse(.loginError)
                    }
                }
            } else {
                print("Login successful")
                // let userID = Auth.auth().currentUser!.uid
                // We check the credentials stored in firebase DB
                //self?.checkCredentials(userID: userID)
                loginResponse(.loginValid)
            }
        }
    }

    func userLogged() -> Bool {
        if Auth.auth().currentUser != nil {
            return true
        } else {
            return false
        }
    }

    func getCurrentUserID() -> String {
        if Auth.auth().currentUser != nil {
            return Auth.auth().currentUser!.uid
        } else {
            return ""
        }
    }

    func getCurrentUserMail() -> String {
        if (Auth.auth().currentUser?.email) != nil {
            return (Auth.auth().currentUser?.email)!
        } else {
            return ""
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }

    // MARK: - Get/Sets

    func getUsername(completion: @escaping (String) -> Void) {
        let userID = Auth.auth().currentUser?.uid

        self.usersRef.child(userID!).child(FirebaseParams.Login.username).observeSingleEvent(of: .value,
                                                    with: { (snapshot) in
            if let username = snapshot.value as? String {
                completion(username)
            }
        })
    }

    func getUsernameByID(userID: String, completion: @escaping (String) -> Void) {

        self.usersRef.child(userID).child(FirebaseParams.Login.username).observeSingleEvent(of: .value,
                                                    with: { (snapshot) in
            if let username = snapshot.value as? String {
                completion(username)
            }
        })
    }

}
