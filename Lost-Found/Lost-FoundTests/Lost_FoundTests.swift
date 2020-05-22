//
//  Lost_FoundTests.swift
//  Lost-FoundTests
//
//  Created by Jose Bolivar Herrera on 09/07/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import XCTest
@testable import Lost_Found

class LostFoundTests: XCTestCase {

    // MARK: Item class Tests
    // Confirm that the Item initializer returns a Item object when passed valid parameters.
    func testItemInitializationSucceeds() {
//
//        let lostJacket = Item.init(name: "Brown jacket", thumbnail: "dog@2x",
//                                   itemDetails: "Jacket I lost on Ronda street", itemCategory: ItemCategories.lost)
//
//        XCTAssertNotNil(lostJacket)

    }
    // Confirm that the Item initializer fails when passed invalid parameters.
    func testItemInitializationFails() {

    }

    func testAddItems() {
        let item = Item.init(itemID: "123213231", name: "item", thumbnail: #imageLiteral(resourceName: "bird@2x" ),
                    itemDetails: "sadsadasd", itemCategory: .lost)

        let itemData = ItemData.init()

        itemData.saveItem(newItem: item!)
    }

}
