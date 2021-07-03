//
//  SSCollectionViewPresenter+NestedTypes.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 24.04.2021.
//

import UIKit

// MARK: - Nested Types

extension SSCollectionViewPresenter {
    // MARK: - PagingConfiguration

    /// Configuration for custom paging behavior in the collection view.
    ///
    /// Use this struct to enable banner-style carousels with paged scrolling,
    /// center alignment, looping, infinite scrolling, and auto-rolling.
    ///
    /// **Requirements:**
    /// - All items must have the same size (computed from the first item).
    /// - Only available for single-section layouts.
    /// - Works best without section headers or footers.
    ///
    /// # Example
    /// ```swift
    /// let config = SSCollectionViewPresenter.PagingConfiguration(
    ///     isAlignCenter: true,
    ///     isAutoRolling: true,
    ///     autoRollingTimeInterval: 4.0
    /// )
    /// collectionView.ss.setPagingEnabled(config)
    /// ```
    public struct PagingConfiguration {
        /// Enables custom paging (replaces `UIScrollView.isPagingEnabled`).
        public var isEnabled: Bool

        /// When `true`, snaps pages to the viewport center after scrolling.
        public var isAlignCenter: Bool

        /// When `true`, wraps around when reaching either end.
        public var isLooping: Bool

        /// Enables infinite scrolling by duplicating content.
        public var isInfinitePage: Bool

        /// Enables automatic page transitions at regular intervals.
        public var isAutoRolling: Bool

        /// Time interval between automatic page transitions, in seconds.
        public var autoRollingTimeInterval: TimeInterval

        public init(
            isEnabled: Bool = true,
            isAlignCenter: Bool = false,
            isLooping: Bool = false,
            isInfinitePage: Bool = false,
            isAutoRolling: Bool = false,
            autoRollingTimeInterval: TimeInterval = 3.0
        ) {
            self.isEnabled = isEnabled
            self.isAlignCenter = isAlignCenter
            self.isLooping = isLooping
            self.isInfinitePage = isInfinitePage
            self.isAutoRolling = isAutoRolling
            self.autoRollingTimeInterval = autoRollingTimeInterval
        }
    }
}
