//
//  TimelineLayout.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 04/09/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

// Timeline Layout Delegate Protocol
// Declares a method to request the cell's photo height
protocol TimeLineLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat
}

// Custom Layout class for the Timeline. Based on:
// https://www.raywenderlich.com/4829472-uicollectionview-custom-layout-tutorial-pinterest
class TimelineLayout: UICollectionViewLayout {

    weak var delegate: TimeLineLayoutDelegate?

    // Cell configuration
    private let numberOfColumns = 2
    private let cellPadding: CGFloat = 6

    private var headerViewHeight: CGFloat = 190
    // Array to cache calculated atributes
    // When prepare() is called, we calculate the attributes for all items and
    // add them to cache. When the collectionView is called again you can request
    // the attributes, instead of recalculting them every time.
    private var cache: [UICollectionViewLayoutAttributes] = []

    // Two properties to store the content size
    // ContentHeight increases as we add items
    // ContentWidth is calculated using the view's width and the content insets
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
    // We return sizes calculated in previous steps
    override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {

        // MODIFICATION: in order for the Layout to reload properly, when we apply any filter
        // We set the content heigh = 0 again (it can be more or less cells)
        // and reload the cache
        self.reloadCache()

        // Only calculate the layout attributes if cache is empty and the CV exists
        guard cache.isEmpty, let collectionView = collectionView
        else {
            return
        }

        // Declare and fill the offsets
        // X Offset -> array with x-coordinate based on column widths
        // Y Offset -> array tracks the y-coordinate of every column. Starts at 0
        let columnWidth = contentWidth / CGFloat(numberOfColumns)
        var xOffset: [CGFloat] = []
        for column in 0..<numberOfColumns {
            xOffset.append(CGFloat(column) * columnWidth)
        }
        var column = 0
        var yOffset: [CGFloat] = .init(repeating: self.headerViewHeight, count: numberOfColumns)

        // Loop through all the items in the first and only section
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)
            // Perform the frame calculation
            //-> Width is the previously calculated cellWidth with the padding removed
            //-> Height is calculated using the height of the photo asked to the delegate
            var photoHeight = delegate?.collectionView(
            collectionView, heightForPhotoAtIndexPath: indexPath) ?? 180

            // Handle images being too big
            if photoHeight > 320 {
                photoHeight = 320
            }

            let height = cellPadding * 2 + photoHeight
            let frame = CGRect(x: xOffset[column],
                             y: yOffset[column],
                             width: columnWidth,
                             height: height)

            let insetFrame = frame.insetBy(dx: cellPadding, dy: cellPadding)

            // Create a new UICollectionViewLayoutAttributes using insetFrame and append
            // the attributes to cache
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            cache.append(attributes)

            // Expand contentHeight to account for the newly calculated item
            // Advance yOffset to the current column, and then "column" to
            // the next column (where the next item will be placed)
            contentHeight = max(contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height

            column = column < (numberOfColumns - 1) ? (column + 1) : 0
        }

    }

    // Determine which items are visible in the given rectangle
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()

        visibleLayoutAttributes.append(self.layoutAttributesForSupplementaryView(ofKind:
            UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0))!)
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }

    // We retrieve and return from the cache the layout attributes of
    // requested indexPath
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {

        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind,
                                                          with: indexPath)
            attributes.frame = CGRect(x: 0, y: 0, width: (collectionView?.frame.width)!,
                                      height: self.headerViewHeight)

        return attributes
    }
    // The cache must be reloaded in case the bounds of the UICollectionView change like:
    // - elements are added/deleted
    // - orientation change
    func reloadCache() {
        self.contentHeight = 0
        self.cache.removeAll()
    }
}
