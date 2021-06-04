//
//  SendingState+UICollectionView.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 25.04.2021.
//

import UIKit

@_exported import SendingState

extension SendingState where Base: UICollectionView {
    /// Returns the currently selected items.
    ///
    /// The presenter automatically tracks selections and deselections via
    /// `collectionView(_:didSelectItemAt:)` and
    /// `collectionView(_:didDeselectItemAt:)`.
    /// When items are removed from the view model, they are also removed
    /// from this collection.
    public var selectedItems: [SSCollectionViewModel.CellInfo] {
        Array(base.presenter?.viewModel?.selectedItems ?? [])
    }

    // MARK: - Configuration

    /// Sets up the presenter for the collection view
    ///
    /// - Parameter actionHandler: An optional handler for user interactions.
    public func setupPresenter(
        actionHandler: (any ActionHandlingProvider)? = nil
    ) {
        base.presenter = SSCollectionViewPresenter(
            collectionView: base,
            actionHandler: actionHandler
        )
    }

    /// Forwards scroll events using a delegate proxy.
    ///
    /// - Parameter proxy: A `UIScrollViewDelegate`
    public func setScrollViewDelegateProxy(_ proxy: UIScrollViewDelegate) {
        base.presenter?.scrollViewDelegateProxy = proxy
    }

    // MARK: - View Model

    /// Assigns the view model used by the presenter (sections & items source).
    ///
    /// - Parameter viewModel: The model containing sections and items.
    public func setViewModel(with viewModel: SSCollectionViewModel) {
        base.presenter?.updateViewModel(viewModel)
    }

    /// Gets the current view model used by the presenter.
    ///
    /// - Returns: The current `SSCollectionViewModel`, if available.
    public func getViewModel() -> SSCollectionViewModel? {
        return base.presenter?.viewModel
    }

    /// Resets the view model's sections.
    public func resetViewModel() {
        var model = base.presenter?.viewModel ?? SSCollectionViewModel()
        model.removeAllPages()
        base.presenter?.updateViewModel(model)
    }

    // MARK: - Section/Item Control

    /// Updates the state of a visible cell without reloading it.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the cell.
    ///   - indexPath: The index path of the cell to update.
    public func reconfigureItem<T>(_ newState: T, at indexPath: IndexPath) {
        base.presenter?.reconfigureItem(newState, at: indexPath)
    }

    /// Updates the state of a visible section header without reloading it.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the header view.
    ///   - section: The index of the section whose header to update.
    @available(iOS 9.0, *)
    public func reconfigureHeader<T>(_ newState: T, at section: Int) {
        base.presenter?.reconfigureHeader(newState, at: section)
    }

    /// Updates the state of a visible section footer without reloading it.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the footer view.
    ///   - section: The index of the section whose footer to update.
    @available(iOS 9.0, *)
    public func reconfigureFooter<T>(_ newState: T, at section: Int) {
        base.presenter?.reconfigureFooter(newState, at: section)
    }

    /// Clears the selection tracking state.
    public func clearSelectedItems() {
        base.presenter?.clearSelectedItems()
    }

    // MARK: - Page-Based Loading

    /// Loads a page of data into the view model's page map and
    /// rebuilds the merged sections.
    ///
    /// This method is designed for server-side pagination where each
    /// page response contains sections that should be merged with
    /// existing pages by identifier.
    ///
    /// **Merge behavior:**
    /// - Sections with the same non-nil identifier across pages have
    ///   their items concatenated in page order.
    /// - Headers and footers from later pages override earlier ones
    ///   for the same section identifier.
    /// - Sections with unique (or nil) identifiers are appended
    ///   in page order.
    ///
    /// After calling this method, you must manually refresh the UI
    /// by calling `collectionView.reloadData()`.
    ///
    /// - Parameters:
    ///   - page: The page number for this batch of data.
    ///   - hasNext: Whether more data is available for pagination.
    ///              Default is `false`.
    ///   - sections: The sections for this page.
    ///
    /// - Returns: The merged `SSCollectionViewModel` after storing the page.
    @discardableResult
    public func loadPage(
        _ page: Int,
        hasNext: Bool = false,
        sections: [SSCollectionViewModel.SectionInfo]
    ) -> SSCollectionViewModel {
        var model = base.presenter?.viewModel ?? SSCollectionViewModel()
        model.hasNext = hasNext
        model.setPage(page, sections: sections)
        base.presenter?.updateViewModel(model)
        return model
    }

    /// Removes a specific page from the page map and rebuilds
    /// the merged sections.
    ///
    /// - Parameter page: The page number to remove.
    /// - Returns: The updated `SSCollectionViewModel` after removal,
    ///            or `nil` if no view model exists.
    @discardableResult
    public func removePage(_ page: Int) -> SSCollectionViewModel? {
        guard var model = base.presenter?.viewModel else { return nil }
        model.removePage(page)
        base.presenter?.updateViewModel(model)
        return model
    }

    /// Configures the pagination handler for loading the next page.
    ///
    /// The closure is called automatically when the user scrolls near the end
    /// and `viewModel.hasNext` is `true`.
    ///
    /// - Parameter block: A closure that receives the current view model.
    ///   Use this to fetch additional data from your API.
    public func onNextRequest(_ block: @escaping (SSCollectionViewModel) -> Void) {
        base.presenter?.nextRequestBlock = block
    }

    // MARK: - Paging Configuration

    /// Configures custom paging using a `PagingConfiguration` struct.
    public func setPagingEnabled(_ config: SSCollectionViewPresenter.PagingConfiguration) {
        base.presenter?.pagingConfig = config
    }

    /// Cancels auto rolling and marks auto rolling as inactive.
    ///
    /// Sets `presenter`'s `isAutoRolling` to `false` before cancelling.
    public func cancelAutoRolling() {
        base.presenter?.isAutoRolling = false
        base.presenter?.cancelAutoRolling()
    }

    /// Starts auto rolling and marks auto rolling as active.
    ///
    /// Sets `presenter`'s `isAutoRolling` to `true` before starting.
    public func runAutoRolling() {
        base.presenter?.isAutoRolling = true
        base.presenter?.runAutoRolling()
    }

    // MARK: - Paging Actions

    /// Scrolls to the next page.
    ///
    /// - Parameter animated: If `true`, animates the transition.
    ///                       Default is `true`.
    public func moveToNextPage(animated: Bool = true) {
        base.presenter?.moveToNextPage(animated: animated)
    }

    /// Scrolls to the previous page.
    ///
    /// - Parameter animated: If `true`, animates the transition.
    ///                       Default is `true`.
    public func moveToPreviousPage(animated: Bool = true) {
        base.presenter?.moveToPreviousPage(animated: animated)
    }

    // MARK: - Paging Callbacks

    /// Sets a closure to be called just before a page becomes visible.
    ///
    /// - Parameter block: A closure that receives the collection view and the
    ///                    page index that is about to appear.
    public func onPageWillAppear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageWillAppearBlock = block
    }

    /// Sets a closure to be called immediately after a page becomes visible.
    ///
    /// - Parameter block: A closure that receives the collection view and the
    ///                    page index that appeared.
    public func onPageDidAppear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageDidAppearBlock = block
    }

    /// Sets a closure to be called just before a page disappears from view.
    ///
    /// - Parameter block: A closure that receives the collection view and the
    ///                    page index that is about to disappear.
    public func onPageWillDisappear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageWillDisappearBlock = block
    }

    /// Sets a closure to be called immediately after a page disappears from view.
    ///
    /// - Parameter block: A closure that receives the collection view and the
    ///                    page index that disappeared.
    public func onPageDidDisappear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageDidDisappearBlock = block
    }
}
