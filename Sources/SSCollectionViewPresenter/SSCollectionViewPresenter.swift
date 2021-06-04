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
    // MARK: - PagingConfiguration

    /// Configuration for custom paging behavior in the collection view.
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

// MARK: - UICollectionViewDataSource

extension SSCollectionViewPresenter: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let viewModel = viewModel else { return 0 }

        guard !(isCustomPagingEnabled && viewModel.sections.count > 1)
        else {
            assertionFailure("⚠️ [SSCollectionViewPresenter] pagingConfig.isEnabled ignored: requires single section (count=\(viewModel.sections.count)).")
            self.isCustomPagingEnabled = false
            return viewModel.sections.count
        }

        if viewModel.sections.isEmpty, viewModel.hasNext {
            isLoadingNextPage = true
            nextRequestBlock?(viewModel)
        }
        /// Called as part of the layout cycle to determine the number of sections.
        /// This is one of the earliest entry points in a layout pass.
        ///
        /// If you need to adjust layout-related states (e.g., content offset),
        /// defer them using `DispatchQueue.main.async` to avoid interfering
        /// with UIKit’s internal layout process.
        DispatchQueue.main.async {
            if self.isAlignCenter {
                collectionView.setInitialOffsetIfNeeded(animated: false)
            }
            if self.isInfinitePage {
                collectionView.remapContentOffsetIfNeeded()
            }
            if self.isAutoRolling {
                self.cancelAutoRolling()
                self.perform(#selector(self.runAutoRolling), with: nil, afterDelay: 3)
            }
        }
        return viewModel.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        guard let items = viewModel?[section].items else { return 0 }

        let itemCount: Int
        if isInfinitePage, items.count > 1 {
            itemCount = items.count * duplicatedItemCount
        } else {
            itemCount = items.count
        }
        return itemCount
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = viewModel
        else { return collectionView.dequeueDefaultCell(for: indexPath) }

        defer {
            if shouldLoadNextPage() {
                isLoadingNextPage = true
                nextRequestBlock?(viewModel)
            }
        }

        let items = viewModel[indexPath.section].items
        let item = viewModel[indexPath.section].items[indexPath.item % items.count]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: item.binderType),
            for: indexPath
        )

        item.apply(to: cell)

        if let actionClosure = item.actionClosure {
            cell.actionClosure = { [weak cell] actionName, input in
                guard let cell = cell else { return }
                actionClosure(indexPath, cell, actionName, input)
            }
        } else {
            cell.actionClosure = nil
        }

        if let actionHandler = actionHandler,
           let aCell = cell as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aCell)
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = viewModel?[indexPath.section]
        else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let item: SSCollectionViewModel.ReusableViewInfo?
        if kind == UICollectionView.elementKindSectionHeader {
            item = section.header
        } else if kind == UICollectionView.elementKindSectionFooter {
            item = section.footer
        } else {
            item = nil
        }

        guard let item = item else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: String(describing: item.binderType),
            for: indexPath
        )

        item.apply(to: view)

        if let actionClosure = item.actionClosure {
            view.actionClosure = { [weak view] actionName, input in
                guard let view = view else { return }
                actionClosure(indexPath.section, view, actionName, input)
            }
        } else {
            view.actionClosure = nil
        }

        if let actionHandler = actionHandler,
           let aView = view as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aView)
        }

        return view
    }
}

extension SSCollectionViewPresenter: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        guard let items = viewModel?[indexPath.section].items else { return }
        let item = items[indexPath.item % items.count]

        if isInfinitePage {
            let lowerBoundIndex = duplicatedItemCount / 2
            let upperBoundIndex = duplicatedItemCount / 2 + 1
            if indexPath.item >= items.count && indexPath.item * lowerBoundIndex < items.count * upperBoundIndex {
                item.willDisplay(to: cell)
            }
        } else {
            item.willDisplay(to: cell)
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didEndDisplaying cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        guard let items = viewModel?[indexPath.section].items else { return }
        let item = items[indexPath.item % items.count]

        if isInfinitePage {
            let lowerBoundIndex = duplicatedItemCount / 2
            let upperBoundIndex = duplicatedItemCount / 2 + 1
            if indexPath.item >= items.count && indexPath.item * lowerBoundIndex < items.count * upperBoundIndex {
                item.didEndDisplaying(to: cell)
            }
        } else {
            item.didEndDisplaying(to: cell)
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplaySupplementaryView view: UICollectionReusableView,
                               forElementKind elementKind: String,
                               at indexPath: IndexPath) {
        guard let section = viewModel?[indexPath.section] else { return }

        let item: SSCollectionViewModel.ReusableViewInfo?

        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            item = section.header
        case UICollectionView.elementKindSectionFooter:
            item = section.footer
        default:
            item = nil
        }

        item?.willDisplay(to: view)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didEndDisplayingSupplementaryView view: UICollectionReusableView,
                               forElementOfKind elementKind: String,
                               at indexPath: IndexPath) {
        guard let section = viewModel?[indexPath.section] else { return }

        let item: SSCollectionViewModel.ReusableViewInfo?

        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            item = section.header
        case UICollectionView.elementKindSectionFooter:
            item = section.footer
        default:
            item = nil
        }

        item?.didEndDisplaying(to: view)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didHighlightItemAt indexPath: IndexPath) {
        guard let items = viewModel?[indexPath.section].items else { return }
        let adjustedIndexPath = IndexPath(item: indexPath.item % items.count, section: indexPath.section)

        guard let cell = collectionView.cellForItem(at: adjustedIndexPath)
        else { return }

        let item = items[indexPath.item % items.count]
        item.didHighlight(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didUnhighlightItemAt indexPath: IndexPath) {
        guard let items = viewModel?[indexPath.section].items else { return }
        let adjustedIndexPath = IndexPath(item: indexPath.item % items.count, section: indexPath.section)

        guard let cell = collectionView.cellForItem(at: adjustedIndexPath)
        else { return }

        let item = items[indexPath.item % items.count]
        item.didUnhighlight(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        guard let items = viewModel?[indexPath.section].items else { return }
        let adjustedIndexPath = IndexPath(item: indexPath.item % items.count, section: indexPath.section)

        guard let cell = collectionView.cellForItem(at: adjustedIndexPath)
        else { return }

        let item = items[indexPath.item % items.count]
        item.didSelect(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didDeselectItemAt indexPath: IndexPath) {
        guard let items = viewModel?[indexPath.section].items else { return }
        let adjustedIndexPath = IndexPath(item: indexPath.item % items.count, section: indexPath.section)

        guard let cell = collectionView.cellForItem(at: adjustedIndexPath)
        else { return }

        let item = items[indexPath.item % items.count]
        item.didDeselect(to: cell)
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        func defaultItemSize(layout collectionViewLayout: UICollectionViewLayout) -> CGSize {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.itemSize
            } else {
                return .zero
            }
        }

        guard let items = viewModel?[indexPath.section].items
        else { return defaultItemSize(layout: collectionViewLayout) }

        guard let itemSize = items[indexPath.item % items.count].size(constrainedTo: collectionView.bounds.size)
        else { return defaultItemSize(layout: collectionViewLayout) }

        return itemSize
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let sectionInset = viewModel?[section].sectionInset
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.sectionInset
            } else {
                return .zero
            }
        }

        return sectionInset
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let lineSpacing = viewModel?[section].minimumLineSpacing
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.minimumLineSpacing
            } else {
                return 0
            }
        }

        return lineSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let itemSpacing = viewModel?[section].minimumInteritemSpacing
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.minimumInteritemSpacing
            } else {
                return 0
            }
        }

        return itemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let viewSize = viewModel?[section].header?.size(constrainedTo: collectionView.bounds.size)
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.headerReferenceSize
            } else {
                return .zero
            }
        }

        return viewSize
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let viewSize = viewModel?[section].footer?.size(constrainedTo: collectionView.bounds.size)
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.footerReferenceSize
            } else {
                return .zero
            }
        }

        return viewSize
    }
}

extension SSCollectionViewPresenter: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidScroll?(scrollView)

        guard let collectionView = scrollView as? UICollectionView else { return }

        if isPagingEnabled {
            guard let section = viewModel?.sections.first, section.items.count > 0 else { return }
            let pageIndex = Int(round(collectionView.currentPage))
            let adjustedIndex = pageIndex % section.items.count
            if currentPageIndex != adjustedIndex {
                pageDidDisappearBlock?(collectionView, currentPageIndex)
                currentPageIndex = adjustedIndex
                pageWillAppearBlock?(collectionView, currentPageIndex)
            }
        }
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidZoom?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewWillBeginDragging?(scrollView)

        guard let collectionView = scrollView as? UICollectionView else { return }

        if isAutoRolling {
            cancelAutoRolling()
        }

        if isPagingEnabled {
            pageWillDisappearBlock?(collectionView, currentPageIndex)
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewDelegateProxy?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)

        guard let collectionView = scrollView as? UICollectionView else { return }

        if isPagingEnabled {
            collectionView.remapTargetContentOffset(withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegateProxy?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)

        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewWillBeginDecelerating?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidEndDecelerating?(scrollView)

        guard let collectionView = scrollView as? UICollectionView else { return }

        if isAutoRolling {
            perform(#selector(self.runAutoRolling), with: nil, afterDelay: pagingTimeInterval)
        }

        // After scrolling fully stops, remap offset for infinite scroll once
        if isInfinitePage {
            collectionView.remapContentOffsetIfNeeded()
        }

        if isPagingEnabled {
            pageDidAppearBlock?(collectionView, currentPageIndex)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidEndScrollingAnimation?(scrollView)

        guard let collectionView = scrollView as? UICollectionView else { return }

        endProgrammaticScrollAnimating()

        // If there are queued page moves, perform them now as a single offset
        let offset = pendingPageOffset
        if offset != 0 {
            pendingPageOffset = 0
            isProgrammaticScrollAnimating = true
            collectionView.scrollPages(by: offset, animated: true)
            return
        }

        // After programmatic animation ends, remap offset for infinite scroll once
        if isInfinitePage {
            collectionView.remapContentOffsetIfNeeded()
        }

        // No more queued moves; schedule auto-rolling and notify page appearance
        if isAutoRolling {
            perform(#selector(self.runAutoRolling), with: nil, afterDelay: pagingTimeInterval)
        }

        if isPagingEnabled {
            pageDidAppearBlock?(collectionView, currentPageIndex)
        }
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollViewDelegateProxy?.viewForZooming?(in: scrollView)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollViewDelegateProxy?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewDelegateProxy?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return scrollViewDelegateProxy?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidScrollToTop?(scrollView)
    }

    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}
