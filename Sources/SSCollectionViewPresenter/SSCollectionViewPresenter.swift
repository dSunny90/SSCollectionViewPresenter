//
//  SSCollectionViewPresenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 24.04.2021.
//

import UIKit

/// Simplifies configuring and managing a `UICollectionView` with a
/// `SSCollectionViewModel`.
///
/// `SSCollectionViewPresenter` bridges your view model with the collection view,
/// automatically handling data source and delegate methods. It provides an
/// easy way to bind cell and supplementary view data with minimal boilerplate.
public final class SSCollectionViewPresenter: NSObject {
    // MARK: - Constants

    /// Number of times items are duplicated for infinite scrolling.
    internal let duplicatedItemCount: Int = 3

    // MARK: - ViewModel

    /// The current view model backing the collection view.
    internal var viewModel: SSCollectionViewModel? {
        didSet {
            guard let viewModel = viewModel, let collectionView = collectionView else { return }
            for section in viewModel.sections {
                for item in section.items {
                    collectionView.registerCell(item.binderType)
                }
                if let header = section.header {
                    collectionView.registerHeader(header.binderType)
                }
                if let footer = section.footer {
                    collectionView.registerFooter(footer.binderType)
                }
            }
            isLoadingNextPage = false
        }
    }

    // MARK: - Action Handling

    /// The action handler responsible for dispatching actions.
    internal var actionHandler: AnyActionHandlingProvider?

    // MARK: - Pagination

    /// Closure called when the next page of data should be loaded.
    internal var nextRequestBlock: ((SSCollectionViewModel) -> Void)?

    /// Flag indicating whether a pagination request is in progress.
    internal var isLoadingNextPage: Bool = false

    // MARK: - Scroll Delegate

    /// Proxy for forwarding scroll view delegate methods.
    internal weak var scrollViewDelegateProxy: UIScrollViewDelegate?

    // MARK: - Paging Options

    /// The paging configuration for the collection view.
    internal var pagingConfig = PagingConfiguration(isEnabled: false)

    internal var isCustomPagingEnabled: Bool {
        get { pagingConfig.isEnabled }
        set { pagingConfig.isEnabled = newValue }
    }

    internal var isAlignCenter: Bool {
        get { pagingConfig.isAlignCenter }
        set { pagingConfig.isAlignCenter = newValue }
    }

    internal var isLooping: Bool {
        get { pagingConfig.isLooping }
        set { pagingConfig.isLooping = newValue }
    }

    internal var isInfinitePage: Bool {
        get { pagingConfig.isInfinitePage }
        set { pagingConfig.isInfinitePage = newValue }
    }

    internal var isAutoRolling: Bool {
        get { pagingConfig.isAutoRolling }
        set { pagingConfig.isAutoRolling = newValue }
    }

    internal var pagingTimeInterval: TimeInterval {
        get { pagingConfig.autoRollingTimeInterval }
        set { pagingConfig.autoRollingTimeInterval = newValue }
    }

    // MARK: - Page Event Callbacks

    /// Called just before a page becomes visible.
    internal var pageWillAppearBlock: ((UICollectionView, Int) -> Void)?

    /// Called right after a page becomes visible
    internal var pageDidAppearBlock: ((UICollectionView, Int) -> Void)?

    /// Called just before a page disappears from view.
    internal var pageWillDisappearBlock: ((UICollectionView, Int) -> Void)?

    /// Called immediately after a page disappears from view.
    internal var pageDidDisappearBlock: ((UICollectionView, Int) -> Void)?

    // MARK: - Collection View Reference

    /// The collection view being managed by this presenter.
    private weak var collectionView: UICollectionView?

    // MARK: - Paging State

    /// The zero-based index of the current page.
    internal var currentPageIndex: Int = 0

    /// Indicates whether a programmatic scroll animation is in progress.
    internal var isProgrammaticScrollAnimating: Bool = false

    /// Accumulated page offset requested during an ongoing animation.
    internal var pendingPageOffset: Int = 0

    /// Returns `true` if any paging mode is active.
    internal var isPagingEnabled: Bool {
        isCustomPagingEnabled || isInfinitePage || isAutoRolling
    }

    // MARK: - Initialization

    public init(
        collectionView: UICollectionView,
        actionHandler: ActionHandlingProvider? = nil
    ) {
        self.collectionView = collectionView
        if let actionHandler = actionHandler {
            self.actionHandler = AnyActionHandlingProvider(actionHandler)
        }
        super.init()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerDefaultCell()
        collectionView.registerDefaultReusableViews(
            ofKind: UICollectionView.elementKindSectionHeader
        )
        collectionView.registerDefaultReusableViews(
            ofKind: UICollectionView.elementKindSectionFooter
        )
    }

    // MARK: - ViewModel Replacement

    /// Replaces the view model and fires page lifecycle callbacks.
    ///
    /// Unlike a plain `viewModel` assignment (which only registers types),
    /// this method additionally notifies `pageWillAppear` / `pageDidAppear`
    /// when paging is active.
    ///
    /// Use this for **full replacements** (`setViewModel`, `buildViewModel`,
    /// `extendViewModel`). For incremental mutations (append, insert, delete,
    /// update), assign to `viewModel` directly.
    internal func updateViewModel(_ viewModel: SSCollectionViewModel) {
        guard let collectionView = collectionView else {
            self.viewModel = viewModel
            return
        }
        if isPagingEnabled {
            pageWillAppearBlock?(collectionView, currentPageIndex)
        }
        self.viewModel = viewModel
        if isPagingEnabled {
            pageDidAppearBlock?(collectionView, currentPageIndex)
        }
    }

    // MARK: - Section/Item Control

    /// Updates the state of a visible cell without reloading it.
    ///
    /// Applies `newState` directly to the bound cell if it is currently visible.
    /// Has no effect if the cell is not visible or if `newState` does not match
    /// the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the cell.
    ///   - indexPath: The index path of the cell to update.
    internal func reconfigureItem<T>(_ newState: T, at indexPath: IndexPath) {
        guard let collectionView = collectionView,
              let viewModel = viewModel,
              indexPath.section < viewModel.count,
              indexPath.item < viewModel[indexPath.section].count else { return }

        let item = viewModel[indexPath.section][indexPath.item]
        guard item.state is T else { return }

        if let cell = collectionView.cellForItem(at: indexPath) {
            item.state = newState
            item.apply(to: cell)
        }
    }

    /// Updates the state of a visible section header without reloading it.
    ///
    /// Applies `newState` directly to the bound supplementary view if it is
    /// currently visible. Has no effect if the header is not visible or if
    /// `newState` does not match the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the header view.
    ///   - section: The index of the section whose header to update.
    @available(iOS 9.0, *)
    internal func reconfigureHeader<T>(_ newState: T, at section: Int) {
        guard let collectionView = collectionView,
              let viewModel = viewModel,
              section < viewModel.count else { return }

        guard let header = viewModel[section].header,
              header.state is T else { return }

        if let view = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: section)
        ) {
            header.state = newState
            header.apply(to: view)
        }
    }

    /// Updates the state of a visible section footer without reloading it.
    ///
    /// Applies `newState` directly to the bound supplementary view if it is
    /// currently visible. Has no effect if the footer is not visible or if
    /// `newState` does not match the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the footer view.
    ///   - section: The index of the section whose footer to update.
    @available(iOS 9.0, *)
    internal func reconfigureFooter<T>(_ newState: T, at section: Int) {
        guard let collectionView = collectionView,
              let viewModel = viewModel,
              section < viewModel.count else { return }

        guard let footer = viewModel[section].footer,
              footer.state is T else { return }

        if let view = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionFooter,
            at: IndexPath(item: 0, section: section)
        ) {
            footer.state = newState
            footer.apply(to: view)
        }
    }

    /// Clears the selection tracking state.
    ///
    /// This only clears the presenter's internal tracking set.
    /// To also visually deselect cells, iterate
    /// `UICollectionView.indexPathsForSelectedItems` and call
    /// `deselectItem(at:animated:)` on the collection view.
    internal func clearSelectedItems() {
        guard let collectionView = collectionView,
              let viewModel = viewModel else { return }

        // Capture UI-selected index paths before we clear them
        let indexPaths = Set(collectionView.indexPathsForSelectedItems ?? [])

        // 1) Visually deselect items so UICollectionView updates its state
        //    and the delegate's didDeselect is fired for visible cells
        for indexPath in indexPaths {
            collectionView.deselectItem(at: indexPath, animated: false)
        }

        // 2) Ensure model's selection state is cleared for any items that
        //    remain selected only in the model (e.g., offscreen cells)
        for (section, sectionInfo) in viewModel.sections.enumerated() {
            for (item, cellInfo) in sectionInfo.items.enumerated()
            where cellInfo.isSelected
            {
                let indexPath = IndexPath(item: item, section: section)
                if let cell = collectionView.cellForItem(at: indexPath) {
                    // Forward didDeselect to the binder and clear selection flag
                    cellInfo.didDeselect(to: cell)
                } else {
                    // If the cell is not visible, just clear the selection state
                    cellInfo.isSelected = false
                }
            }
        }

        // Write back the model for consistency
        self.viewModel = viewModel
    }

    /// Toggles the collapsed state of the specified section and animates
    /// the changes.
    ///
    /// Updates `isCollapsed` on the section model before calling
    /// `performBatchUpdates` to keep the data source consistent
    /// during animation.
    ///
    /// - Parameters:
    ///   - section: The index of the section to toggle.
    ///   - completion: A closure called after the animation completes.
    ///                 Receives `true` if the section is now expanded,
    ///                 `false` if collapsed.
    internal func toggleSection(_ section: Int, completion: @escaping ((Bool) -> Void)) {
        guard let collectionView = collectionView,
              var model = viewModel else { return }

        let wasCollapsed = model[section].isCollapsed
        let indexPaths = (0..<model[section].count).map {
            IndexPath(item: $0, section: section)
        }

        model[section].isCollapsed = !wasCollapsed
        self.viewModel = model

        collectionView.performBatchUpdates {
            if wasCollapsed {
                collectionView.insertItems(at: indexPaths)
            } else {
                collectionView.deleteItems(at: indexPaths)
            }
        } completion: { _ in
            completion(!wasCollapsed)
        }
    }

    // MARK: - Pagination

    /// Determines whether the next page should be loaded based on scroll position.
    ///
    /// Checks if the user has scrolled close enough to the end and whether
    /// pagination is available and not already in progress.
    ///
    /// - Returns: `true` if the next page should be requested; otherwise, `false`.
    internal func shouldLoadNextPage() -> Bool {
        guard let collectionView = collectionView, let viewModel = viewModel,
              viewModel.hasNext, isLoadingNextPage == false
        else { return false }

        return (collectionView.currentOffset > collectionView.contentLength - collectionView.boundsLength * 3)
    }

    // MARK: - Auto-Rolling

    /// Cancels any pending auto-rolling operations.
    internal func cancelAutoRolling() {
        NSObject.cancelPreviousPerformRequests(
            withTarget: self,
            selector: #selector(self.runAutoRolling),
            object: nil
        )
    }

    /// Performs an automatic scroll to the next page and schedules the next one.
    ///
    /// Requires `isAutoRolling` to be enabled. This method calls itself
    /// recursively at intervals defined by `pagingTimeInterval`.
    @objc internal func runAutoRolling() {
        cancelAutoRolling()
        guard let collectionView = collectionView else { return }
        collectionView.scrollPages(by: 1, animated: true)
        perform(
            #selector(self.runAutoRolling),
            with: nil,
            afterDelay: pagingTimeInterval
        )
    }

    // MARK: - Paging Actions

    /// Scrolls to the next page programmatically.
    ///
    /// Cancels any active auto-rolling. If an animation is already in progress,
    /// the request is queued.
    ///
    /// - Parameter animated: Whether to animate the transition.
    internal func moveToNextPage(animated: Bool) {
        guard let collectionView = collectionView else { return }
        cancelAutoRolling()
        if isProgrammaticScrollAnimating {
            pendingPageOffset += 1
            return
        }
        isProgrammaticScrollAnimating = true
        collectionView.scrollPages(by: 1, animated: animated)
    }

    /// Scrolls to the previous page programmatically.
    ///
    /// Cancels any active auto-rolling. If an animation is already in progress,
    /// the request is queued.
    ///
    /// - Parameter animated: Whether to animate the transition.
    internal func moveToPreviousPage(animated: Bool) {
        guard let collectionView = collectionView else { return }
        cancelAutoRolling()
        if isProgrammaticScrollAnimating {
            pendingPageOffset -= 1
            return
        }
        isProgrammaticScrollAnimating = true
        collectionView.scrollPages(by: -1, animated: animated)
    }

    /// Marks the programmatic scroll animation as complete.
    internal func endProgrammaticScrollAnimating() {
        isProgrammaticScrollAnimating = false
    }
}
