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
/// Each instance describes the item sizing, scroll direction,
/// and orthogonal scrolling behavior for a single section.
///
/// ## Sizing Modes
///
/// **Uniform** -- all items share the same dimensions:
/// ```swift
/// .init(direction: .vertical, itemSize: .uniform(columns: 3, height: 110))
/// ```
///
/// **Dynamic** -- each cell provides its own size via
/// `static func size(with:constrainedTo:)`:
/// ```swift
/// .init(direction: .horizontal, itemSize: .dynamic, scrolling: .paging)
/// ```
///
/// ## Spacing & Insets
///
/// `itemSpacing`, `lineSpacing`, and `sectionInset` are optional.
/// When `itemSize` is ``ItemSizeMode/dynamic`` and these values are `nil`,
/// the corresponding `SSCollectionViewModel.SectionInfo` values
/// (`minimumInteritemSpacing`, `minimumLineSpacing`, `sectionInset`)
/// are used as a fallback. For ``ItemSizeMode/uniform``, only the
/// values defined on this struct are used.
public struct SSCompositionalLayoutSection {
    // MARK: - ItemSizeMode

    /// Determines how item dimensions are calculated.
    public enum ItemSizeMode {
        /// All items share the same fixed dimensions.
        ///
        /// - Parameters:
        ///   - columns: Number of columns in the group.
        ///     Width per item = containerWidth / columns unless `width` is set.
        ///   - width: Optional fixed width per item.
        ///     When `nil`, width is `.fractionalWidth(1 / columns)`.
        ///   - height: Fixed height for every item.
        case uniform(columns: Int = 1, width: CGFloat? = nil, height: CGFloat)

        /// Each item's size is queried from the cell's
        /// `static func size(with:constrainedTo:)` at layout time.
        ///
        /// If a cell's `size()` returns `nil`, `.estimated(50)` is used
        /// (Auto Layout self-sizing).
        case dynamic
    }

    // MARK: - ScrollingBehavior

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

    // MARK: - Properties

    /// Scroll direction for the section (`.vertical` or `.horizontal`).
    public var direction: UICollectionView.ScrollDirection

    /// Determines how item dimensions are calculated.
    public var itemSize: ItemSizeMode

    /// Orthogonal scrolling behavior; `nil` disables orthogonal scrolling.
    public var scrolling: ScrollingBehavior?

    /// Spacing between items within a group
    /// (maps to `NSCollectionLayoutGroup.interItemSpacing`).
    ///
    /// When `nil`, falls back to `SectionInfo.minimumInteritemSpacing`.
    public var itemSpacing: CGFloat?

    /// Spacing between groups within the section
    /// (maps to `NSCollectionLayoutSection.interGroupSpacing`).
    ///
    /// When `nil`, falls back to `SectionInfo.minimumLineSpacing`.
    public var lineSpacing: CGFloat?

    /// Section content insets
    /// (maps to `NSCollectionLayoutSection.contentInsets`).
    ///
    /// When `nil`, falls back to `SectionInfo.sectionInset`.
    public var sectionInset: UIEdgeInsets?

    /// When `true`, header/footer boundary supplementary items respect
    /// the section's `contentInsets`.
    /// Maps to `NSCollectionLayoutSection.supplementariesFollowContentInsets`.
    /// Defaults to `true` (matching UIKit's default).
    public var supplementariesFollowContentInsets: Bool

    // MARK: - Init

    /// Creates a section configuration.
    ///
    /// - Parameters:
    ///   - direction: Scroll direction (`.vertical` or `.horizontal`).
    ///   - itemSize: Sizing mode. Default `.dynamic`.
    ///   - scrolling: Orthogonal scrolling behavior.
    ///   - itemSpacing: Spacing between items within a group.
    ///   - lineSpacing: Spacing between groups within the section.
    ///   - sectionInset: Section content insets.
    ///   - supplementariesFollowContentInsets: Whether headers/footers
    ///     respect `sectionInset`. Defaults to `true`.
    public init(
        direction: UICollectionView.ScrollDirection,
        itemSize: ItemSizeMode = .dynamic,
        scrolling: ScrollingBehavior? = nil,
        itemSpacing: CGFloat? = nil,
        lineSpacing: CGFloat? = nil,
        sectionInset: UIEdgeInsets? = nil,
        supplementariesFollowContentInsets: Bool = true
    ) {
        self.direction = direction
        self.itemSize = itemSize
        self.scrolling = scrolling
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.sectionInset = sectionInset
        self.supplementariesFollowContentInsets = supplementariesFollowContentInsets
    }
}
