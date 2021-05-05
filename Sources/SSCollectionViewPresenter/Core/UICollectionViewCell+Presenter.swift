//
//  UICollectionViewCell+Presenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 05.05.2021.
//

import UIKit

extension UICollectionViewCell {
    /// The index path of this cell within its collection view.
    ///
    /// Traverses the responder chain to locate the parent `UICollectionView`,
    /// then returns the index path for this cell.
    /// Returns `nil` if the cell is not currently visible or has no parent
    /// collection view.
    public var indexPath: IndexPath? {
        var responder: UIResponder? = self
        while let r = responder {
            if let collectionView = r as? UICollectionView {
                return collectionView.indexPath(for: self)
            }
            responder = r.next
        }
        return nil
    }
}
