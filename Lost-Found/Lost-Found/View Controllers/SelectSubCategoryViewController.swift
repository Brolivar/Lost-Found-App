//
//  SelectSubCategoryViewController.swift
//  Lost-Found
//
//  Created by Jose Bolivar Herrera on 04/11/2019.
//  Copyright © 2019 Jose Bolivar Herrera. All rights reserved.
//

import UIKit

class SelectSubCategoryViewController: UIViewController {

    // MARK: - Properties
    weak var delegate: Coordinator?     // We don't specify coordinator class, since this will be reusable
    // Delegate for communication with the AddItemVC
    weak var subcategorySelectedDelegate: SubcategorySelectedDelegate?
    private var subcategoriesList: [ItemSubCategories] = []

    @IBOutlet var subcategoryCollectionView: UICollectionView!
    @IBOutlet var dismissView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        for subcategory in ItemSubCategories.allCases {
            subcategoriesList.append(subcategory)
        }

        // Cell set-up
        let cellSize = CGSize(width: (view.frame.width / 3) - 30, height: 100)
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.minimumLineSpacing = 20.0
        layout.minimumInteritemSpacing = 5.0
        self.subcategoryCollectionView.setCollectionViewLayout(layout, animated: true)

        self.subcategoryCollectionView.reloadData()
    }

    // Dismiss view when touching outside the view
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        if touch?.view == self.dismissView {
            dismiss(animated: true)
        }
    }

}

// MARK: - UICollectionViewDataSource extension
// Manages the Data Source of the cells.
extension SelectSubCategoryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return subcategoriesList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubcategoryCell",
                                                            for: indexPath) as? SelectCategoryViewCell
            else {
                print("The dequeued cell is not an instance of SelectCategoryViewCell.")
                return UICollectionViewCell()
        }

        cell.configure(with: self.subcategoriesList[indexPath.row])
        return cell
    }
}

// MARK: - UICollectionViewDelegate extension

extension SelectSubCategoryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.subcategorySelectedDelegate?.subcategorySelected(subcategory: self.subcategoriesList[indexPath.row])
        dismiss(animated: true)
    }
}
