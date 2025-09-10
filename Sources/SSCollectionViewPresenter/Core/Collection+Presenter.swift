//
//  Collection+Presenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import Foundation

extension Collection {
    /// Safely accesses the element at the given index.
    /// Returns `nil` if the index is out of bounds.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
