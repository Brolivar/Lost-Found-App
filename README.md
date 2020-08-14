# Lost-Found iOS App


<p align="center">
  <img width="300" height="300" src="resources/logo.jpg">
</p>


My Computer Science Final Project. An iOS App for uploading all kind of items you have lost/found. 


## :memo: Description 

This project was developed as my final's degree project, which was developed during approximately half a year, with the guidance of a senior iOS developer, from who I could learn (and apply) the newest, and most used patterns and structures (such as MVVM or Coordination Pattern).


### Features

:white_check_mark: "Infinite Scroll" timeline, ordered by distance towards the user.

:white_check_mark: The item info and thumbnails have each a different pagination, to optimize the usage of user's data.

:white_check_mark: The thumbnails, and item's image are cached in device to avoid redownloading (props to Kingfisher).

:white_check_mark: Tap any item to go to its single view, with all the info associated to it.

:white_check_mark: Authentication system with mail and password using Firebase Auth.

:white_check_mark: Create new items with its own images, location... and add it to the timeline.

:white_check_mark: Filter menu; capable of filterin items by its category (lost, found and adoption), subcategory (jewelry, pets, books...) and location.

:white_check_mark: User profile with its items created.

:white_check_mark: Real-time chat user to user, to contact with the item publisher directly and privately.

:white_check_mark: Push Notifications using Firebase Cloud Messaging.




### Upcoming / In progress



:black_square_button: Take away completely the "adoption" category (leaving just Lost and found categories in the app). This is intented to apart from publishing the lost & found app, publish another app just for pet adoption, based on the finished lost & found one.

:black_square_button: Final UI redesign; having a cleaner and smoother interface to fully satisfy the upcoming real users.

:black_square_button: Notify the user whenever a item from the corresponding category and subcategory is uploaded nearby (f.e lost electronic item uploaded near your found electronic item).




## :movie_camera: Getting Started 

To get a copy of the project up and running of your local machine, you will need a MacOS environment with  ```Xcode``` installed (latest version preferred).


### Installing

After the project is downloaded, to load it you just have to double click on the ```.xcworkspace``` file to launch the project with Xcode. Then choose the way you want to execute the application (for example, on the Iphone Simulator).

Consider it will take some time to get the project (and libraries) fully indexed.

NOTE: This is an old, un updated version, many of the functionalities (such as notifications, real-time chat) and UI redesign are not available here. New updated modules will be uploaded as the app is released to the App Store.

## :books: Libraries 

There were many libraries used in the development of this project:

- Simple side/slide menu control for iOS: [SideMenu](https://github.com/jonkykong/SideMenu)
- Tool to enforce Swift style and conventions: [Swiftlint](https://github.com/realm/SwiftLint)
- Codeless drop-in universal library allows to prevent issues of keyboard sliding up: [IQKeyboardManager](https://github.com/hackiftekhar/IQKeyboardManager)
- Flexible view and view controller presentation library for iOS: [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages)
- DSL to make Auto Layout easy on both iOS and OS X: [SnapKit v.5](https://github.com/SnapKit/SnapKit)
- A clean and lightweight progress HUD for your iOS and tvOS App: [SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD)
- Swift image slideshow with circular scrolling, timer and full screen viewer: [ImageSlideshow](https://github.com/zvonicek/ImageSlideshow)

- The databases, notifications, authentication and storage infrastructure backed by Google: [Firebase](https://firebase.google.com)
- GeoFire for Objective-C - Realtime location queries with Firebase: [Geofire](https://github.com/firebase/geofire-objc)
- A lightweight, pure-Swift library for downloading and caching images from the web: [Kingfisher](https://github.com/onevcat/Kingfisher)


## :busts_in_silhouette: Contributors 

* [Daniel Bolivar](https://github.com/potajedehabichuelas) - Daniel Bolivar Github Site


## :smirk_cat: Authors 
* **Jose Bolivar** - *Initial work* - [Lost&Found App](https://github.com/Brolivar/Lost-Found-Public)

## Acknowledgments
As always, great utility came from great sites:

* https://www.appcoda.com/
* https://swift.org/documentation/
* https://stackoverflow.com/
* https://nshipster.com
* https://medium.com/swift-programming
* https://www.raywenderlich.com


App Icons provided by:

* https://icons8.com/icons
* https://www.flaticon.com
* https://www.freepik.com

## :mag: License 

This application is released under MIT(see [LICENSE](https://github.com/Brolivar/Lost-Found-Public/blob/master/LICENSE)). Some of the used libraries are released under different licenses.


