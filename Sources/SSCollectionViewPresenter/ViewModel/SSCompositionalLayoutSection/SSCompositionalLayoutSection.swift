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
    ///
    /// - Note: On iOS 16+, UIKit deprecated
    ///   `supplementariesFollowContentInsets` in favor of
    ///   `supplementaryContentInsetsReference`. Use
    ///   ``contentInsetsReference`` instead.
    @available(iOS, introduced: 13.0, deprecated: 16.0,
               message: "Use contentInsetsReference instead")
    public var supplementariesFollowContentInsets: Bool {
        get { _supplementariesFollowContentInsets ?? true }
        set { _supplementariesFollowContentInsets = newValue }
    }
    internal var _supplementariesFollowContentInsets: Bool?

    /// Controls how supplementary views (headers/footers) resolve their
    /// content insets on iOS 16+.
    ///
    /// Maps to
    /// `NSCollectionLayoutSection.supplementaryContentInsetsReference`.
    ///
    /// | Value | Behavior |
    /// |-------|----------|
    /// | `.automatic` | System decides (default). |
    /// | `.none` | No insets applied. |
    /// | `.safeArea` | Insets follow safe area. |
    /// | `.layoutMargins` | Insets follow layout margins. |
    ///
    /// On iOS 13–15 this value is ignored and
    /// ``supplementariesFollowContentInsets`` is used instead.
    public var contentInsetsReference: ContentInsetsReference

    /// Mirrors `UIContentInsetsReference` without requiring iOS 16+
    /// availability on the stored property.
    public enum ContentInsetsReference: Int {
        /// System default behavior.
        case automatic = 0
        /// Supplementaries ignore content insets entirely.
        case none = 1
        /// Supplementaries follow the safe area.
        case safeArea = 2
        /// Supplementaries follow layout margins.
        case layoutMargins = 3
    }

    /// Orthogonal scrolling properties for fine-tuning scroll physics
    /// on iOS 17+.
    ///
    /// Maps to
    /// `NSCollectionLayoutSection.orthogonalScrollingProperties`.
    ///
    /// When `nil`, UIKit defaults are used.
    public var orthogonalScrollingProperties: OrthogonalScrollingProperties?

    /// Fine-grained control over orthogonal scrolling physics (iOS 17+).
    ///
    /// Mirrors `UICollectionLayoutSectionOrthogonalScrollingProperties`
    /// without requiring iOS 17+ availability on the stored property.
    public struct OrthogonalScrollingProperties {
        /// Deceleration rate for orthogonal scrolling.
        public var decelerationRate: DecelerationRate

        /// Bounce behavior for orthogonal scrolling.
        public var bounce: Bounce

        /// Deceleration rate that maps to
        /// `UICollectionLayoutSectionOrthogonalScrollingProperties.DecelerationRate`.
        public enum DecelerationRate: Int {
            /// System default behavior.
            case automatic = 0
            /// Normal deceleration (UIScrollView default).
            case normal = 1
            /// Fast deceleration (shorter scroll distance).
            case fast = 2
        }

        /// Bounce behavior that maps to
        /// `UICollectionLayoutSectionOrthogonalScrollingProperties.Bounce`.
        public enum Bounce: Int {
            /// System default behavior.
            case automatic = 0
            /// Always bounces at content edges.
            case always = 1
            /// Never bounces at content edges.
            case never = 2
        }

        /// Creates orthogonal scrolling properties.
        ///
        /// - Parameters:
        ///   - decelerationRate: Deceleration rate. Defaults to `.automatic`.
        ///   - bounce: Bounce behavior. Defaults to `.automatic`.
        public init(
            decelerationRate: DecelerationRate = .automatic,
            bounce: Bounce = .automatic
        ) {
            self.decelerationRate = decelerationRate
            self.bounce = bounce
        }
    }

    /// When `true`, items in the same group are uniformly sized
    /// based on the largest item (iOS 17+).
    public var isUniformAcrossSiblings: Bool

    /// Estimated height used for `uniformAcrossSiblings` calculation.
    /// Only used when `isUniformAcrossSiblings` is `true`.
    public var uniformEstimatedHeight: CGFloat?

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
    ///   - contentInsetsReference: How supplementary views resolve
    ///     insets (iOS 16+). Defaults to `.automatic`.
    ///   - orthogonalScrollingProperties: Fine-grained orthogonal
    ///     scroll physics (iOS 17+). Defaults to `nil`.
    ///   - isUniformAcrossSiblings: iOS 17+ uniform sizing.
    ///   - uniformEstimatedHeight: Estimated height for uniform sizing.
    public init(
        direction: UICollectionView.ScrollDirection,
        itemSize: ItemSizeMode = .dynamic,
        scrolling: ScrollingBehavior? = nil,
        itemSpacing: CGFloat? = nil,
        lineSpacing: CGFloat? = nil,
        sectionInset: UIEdgeInsets? = nil,
        contentInsetsReference: ContentInsetsReference = .automatic,
        orthogonalScrollingProperties: OrthogonalScrollingProperties? = nil,
        isUniformAcrossSiblings: Bool = false,
        uniformEstimatedHeight: CGFloat? = nil
    ) {
        self.direction = direction
        self.itemSize = itemSize
        self.scrolling = scrolling
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.sectionInset = sectionInset
        self.contentInsetsReference = contentInsetsReference
        self.orthogonalScrollingProperties = orthogonalScrollingProperties
        self.isUniformAcrossSiblings = isUniformAcrossSiblings
        self.uniformEstimatedHeight = uniformEstimatedHeight
    }
}
