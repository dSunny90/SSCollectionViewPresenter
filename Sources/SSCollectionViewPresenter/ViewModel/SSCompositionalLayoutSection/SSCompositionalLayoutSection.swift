//
//  SSCompositionalLayoutSection.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 16.11.2022.
//

import UIKit

public struct SSCompositionalLayoutSection {
    var direction: UICollectionView.ScrollDirection
    var columns: Int
    var itemWidth: CGFloat?
    var height: CGFloat
    var scrolling: ScrollingBehavior?

    public init(
        direction: UICollectionView.ScrollDirection,
        columns: Int = 1,
        itemWidth: CGFloat? = nil,
        height: CGFloat,
        scrolling: ScrollingBehavior? = nil
    ) {
        self.direction = direction
        self.columns = columns
        self.itemWidth = itemWidth
        self.height = height
        self.scrolling = scrolling
    }

    public enum ScrollingBehavior: Int, @unchecked Sendable {
        case none = 0
        case continuous = 1
        case continuousGroupLeadingBoundary = 2
        case paging = 3
        case groupPaging = 4
        case groupPagingCentered = 5
    }
}
