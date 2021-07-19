//
//  SSCompositionalLayoutSection.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 04.07.2021.
//

import UIKit

/// Per-section layout descriptor used by
/// ``SSCollectionViewPresenter/CompositionalLayoutConfig``.
///
/// Each instance describes the item sizing, column count, scroll direction,
/// and orthogonal scrolling behavior for a single section.
/// `CompositionalLayoutConfig.makeLayout()` iterates the array of these
/// descriptors to build the final `UICollectionViewCompositionalLayout`.
///
/// ```swift
/// let sections: [SSCompositionalLayoutSection] = [
///     .init(direction: .vertical, columns: 3, height: 110),
///     .init(direction: .horizontal, height: 350, scrolling: .paging),
/// ]
/// ```
public struct SSCompositionalLayoutSection {
    /// Scroll direction for the section (`.vertical` or `.horizontal`).
    var direction: UICollectionView.ScrollDirection
    /// Number of columns in the section group.
    var columns: Int
    /// Optional fixed item width; when `nil`, width is calculated
    /// as a fraction of the group width.
    var itemWidth: CGFloat?
    /// Fixed height for every item in the section.
    var height: CGFloat
    /// Orthogonal scrolling behavior; `nil` disables orthogonal scrolling.
    var scrolling: ScrollingBehavior?

    /// Creates a section configuration.
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

    /// Orthogonal scrolling behavior that maps to
    /// `UICollectionLayoutSectionOrthogonalScrollingBehavior`.
    public enum ScrollingBehavior: Int {
        /// No orthogonal scrolling.
        case none = 0
        /// Free continuous scrolling.
        case continuous = 1
        /// Continuous scrolling that stops at the group's leading boundary.
        case continuousGroupLeadingBoundary = 2
        /// Page-based scrolling.
        case paging = 3
        /// Page-based scrolling per group.
        case groupPaging = 4
        /// Page-based scrolling that centers each group.
        case groupPagingCentered = 5
    }
}
