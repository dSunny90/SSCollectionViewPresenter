//
//  SendingState+UICollectionView.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 02.11.2022.
//

import UIKit

@_exported import SendingState

extension SendingState where Base: UICollectionView {
    // MARK: - Configuration

    /// Sets up the presenter for the collection view with layout,
    /// action handler, and data source mode.
    ///
    /// - Parameters:
    ///   - layoutKind: Layout type (`.flow` or `.compositional`).
    ///                 Default is `.flow`.
    ///   - actionHandler: Optional handler for user interactions.
    ///   - dataSourceMode: Data mode (`.traditional`, `.diffable`).
    ///                     Default is `.traditional`.
    @MainActor
    public func setupPresenter(
        layoutKind: SSCollectionViewPresenter.LayoutKind = .flow,
        actionHandler: (any ActionHandlingProvider)? = nil,
        dataSourceMode: SSCollectionViewPresenter.DataSourceMode = .traditional,
    ) {
        base.presenter = SSCollectionViewPresenter(
            collectionView: base,
            layoutKind: layoutKind,
            actionHandler: actionHandler,
            dataSourceMode: dataSourceMode
        )
    }

    /// Forwards scroll events using a delegate proxy.
    ///
    /// - Parameter proxy: A `UIScrollViewDelegate` proxy.
    @MainActor
    public func setScrollViewDelegateProxy(_ proxy: UIScrollViewDelegate) {
        base.presenter?.scrollViewDelegateProxy = proxy
    }

    // MARK: - View Model

    /// Assigns the view model used by the presenter (sections & items source).
    ///
    /// - Important:
    ///   Configure the presenter before setting the view model — e.g.,
    ///   `setPagingEnabled(_::::)`. The presenter uses these settings
    ///   to compute paging/positions.
    ///   Then set the view model right before refershing the UI:
    ///   - Call `collectionView.reloadData()` for the classic data source, or
    ///   - Call `collectionView.ss.applySnapshot(animated:)` when using the
    ///     diffable data source.
    ///
    /// - Note:
    ///   This does not refresh the collection view automatically; it only
    ///   updates the presenter’s model. You must explicitly call `reloadData()`
    ///   or `ss.applySnapshot(animated: true)`.
    ///
    /// - Parameter viewModel: The model containing sections and items.
    @MainActor
    public func setViewModel(with viewModel: SSCollectionViewModel) {
        base.presenter?.viewModel = viewModel
    }

    /// Gets the current view model used by the presenter.
    ///
    /// - Returns: The current `SSCollectionViewModel`, if available.
    @MainActor
    public func getViewModel() -> SSCollectionViewModel? {
        return base.presenter?.viewModel
    }

    /// Builds a new `SSCollectionViewModel` using a builder pattern and assigns
    /// it to the presenter.
    ///
    /// This method replaces any existing view model. After calling this method,
    /// you must manually refresh the UI by calling `collectionView.reloadData()`
    /// or `collectionView.ss.applySnapshot(animated:)`.
    ///
    /// # Example
    /// ```swift
    /// collectionView.ss.buildViewModel { builder in
    ///     builder.section() {
    ///         builder.cell(
    ///             model: result.eventBanner,
    ///             viewModel: EventBannerViewModel()
    ///         )
    ///     }
    ///     builder.section() {
    ///         builder.cells(
    ///             models: result.mainBannerList,
    ///             viewModel: MainBannerListViewModel()
    ///         )
    ///     }
    ///     builder.section("productList") {
    ///         builder.header(
    ///             model: result.productHeaderInfo,
    ///             viewModel: ProductHeaderViewModel()
    ///         )
    ///         builder.footer(
    ///             model: result.productFooterInfo,
    ///             viewModel: ProductFooterViewModel()
    ///         )
    ///         builder.cells(
    ///             models: result.productList,
    ///             viewModel: ProductViewModel()
    ///         )
    ///     }
    /// }
    ///
    /// // Refresh the UI
    /// collectionView.ss.applySnapshot(animated: true)
    /// ```
    ///
    /// - Parameters:
    ///   - page: The current page number for pagination. Default is `0`.
    ///   - hasNext: Whether more data is available for pagination.
    ///              Default is `false`.
    ///   - build: A closure that receives a `Builder` instance for constructing
    ///            sections and items.
    ///
    /// - Returns: The newly built `SSCollectionViewModel` that was assigned to
    ///            the presenter.
    @MainActor
    @discardableResult
    public func buildViewModel(
        page: Int = 0,
        hasNext: Bool = false,
        _ build: (SSCollectionViewModel.Builder) -> Void
    ) -> SSCollectionViewModel {
        let builder = SSCollectionViewModel.Builder()
        build(builder)
        let model = builder.build(page: page, hasNext: hasNext)
        base.presenter?.viewModel = model
        return model
    }

    /// Extends the current view model by appending new sections and items.
    ///
    /// This method is designed for pagination scenarios where you want to add
    /// content to existing data rather than replacing it entirely.
    ///
    /// **Merge behavior:**
    /// - If a section with the same identifier exists, new items are appended
    ///   to that section
    /// - Headers and footers are replaced if provided in the new content
    /// - If a section identifier is new, the entire section is appended
    ///
    /// After calling this method, you must manually refresh the UI by calling
    /// `collectionView.reloadData()`
    /// or `collectionView.ss.applySnapshot(animated:)`.
    ///
    /// # Example
    /// ```swift
    /// // Load next page of products
    /// collectionView.ss.extendViewModel(
    ///     page: currentPage + 1,
    ///     hasNext: response.hasNext
    /// ) { builder in
    ///     builder.section("productList") {
    ///         builder.cells(
    ///             models: response.productList,
    ///             viewModel: ProductViewModel()
    ///         )
    ///     }
    /// }
    ///
    /// // Refresh the UI
    /// collectionView.ss.applySnapshot(animated: true)
    /// ```
    ///
    /// - Parameters:
    ///   - page: The current page number for pagination. Default is `0`.
    ///   - hasNext: Whether more data is available for pagination.
    ///              Default is `false`.
    ///   - build: A closure that receives a `Builder` instance for constructing
    ///            additional sections and items.
    ///
    /// - Returns: The merged `SSCollectionViewModel` after appending
    ///            the new content.
    @MainActor
    @discardableResult
    public func extendViewModel(
        page: Int = 0,
        hasNext: Bool = false,
        _ build: (SSCollectionViewModel.Builder) -> Void
    ) -> SSCollectionViewModel {
        let builder = SSCollectionViewModel.Builder()
        build(builder)

        var model = base.presenter?.viewModel ?? SSCollectionViewModel(sections: [])
        model.page = page
        model.hasNext = hasNext

        for section in builder.build().sections {
            if let idx = model.firstIndex(where: { $0.identifier == section.identifier }) {
                // Append items to existing section
                model.sections[idx].items.append(contentsOf: section.items)

                // Override header/footer if present
                if let header = section.header {
                    model.sections[idx].header = header
                }
                if let footer = section.footer {
                    model.sections[idx].footer = footer
                }
            } else {
                // Append new section
                model.append(section)
            }
        }

        base.presenter?.viewModel = model
        return model
    }

    // MARK: - Paging Configuration

    /// Configures the pagination handler for loading the next page.
    ///
    /// The closure is called automatically when the user scrolls near the end
    /// and `viewModel.hasNext` is `true`.
    ///
    /// - Parameter block: A closure that receives the current view model.
    ///   Use this to fetch additional data from your API.
    @MainActor
    public func onNextRequest(_ block: @escaping (SSCollectionViewModel) -> Void) {
        base.presenter?.nextRequestBlock = block
    }

    /// Enables custom paging with support for center alignment, looping,
    /// infinite scrolling, and auto-rolling.
    ///
    /// - Discussion:
    ///   This method configures all paging-related behaviors in one call. When
    ///   using custom paging, you should disable `UICollectionView.isPagingEnabled`
    ///   to avoid conflicts.
    ///
    ///   **Requirements:**
    ///   - All items must have the same size (computed from the first item)
    ///   - Only available for single-section layouts
    ///   - Works best without section headers or footers
    ///
    ///   This feature is designed for banner-style carousels with paged scrolling.
    ///
    /// - Parameters:
    ///   - isOn: Enables custom paging. Default is `true`.
    ///   - isAlignCenter: When `true`, snaps the current page to the center
    ///                    after scrolling. Default is `false`.
    ///   - isLooping: When `true`, wraps around when reaching either end.
    ///                Default is `false`.
    ///   - isInfinitePage: Enables infinite paging behavior. Default is `false`.
    ///   - isAutoRolling: Enables automatic scrolling. Default is `false`.
    ///   - autoRollingTimeInterval: Time interval between auto-scroll actions,
    ///                              in seconds. Default is `3.0`.
    ///
    /// # Example
    /// ```swift
    /// // Enable custom paging with defaults
    /// collectionView.ss.setPagingEnabled()
    ///
    /// // Center-aligned with auto-rolling every 4 seconds
    /// collectionView.ss.setPagingEnabled(
    ///     isAlignCenter: true,
    ///     isAutoRolling: true,
    ///     autoRollingTimeInterval: 4.0
    /// )
    ///
    /// // Infinite paging with auto-rolling
    /// collectionView.ss.setPagingEnabled(
    ///     isInfinitePage: true,
    ///     isAutoRolling: true
    /// )
    /// ```
    @MainActor
    public func setPagingEnabled(
        _ isOn: Bool = true,
        isAlignCenter: Bool = false,
        isLooping: Bool = false,
        isInfinitePage: Bool = false,
        isAutoRolling: Bool = false,
        autoRollingTimeInterval: TimeInterval = 3.0
    ) {
        base.presenter?.isCustomPagingEnabled = isOn
        base.presenter?.isAlignCenter = isAlignCenter
        base.presenter?.isLooping = isLooping
        base.presenter?.isInfinitePage = isInfinitePage
        base.presenter?.isAutoRolling = isAutoRolling
        base.presenter?.pagingTimeInterval = autoRollingTimeInterval
    }

    // MARK: - Paging Actions

    /// Scrolls to the next page.
    ///
    /// - Parameter animated: If `true`, animates the transition.
    ///                       Default is `true`.
    @MainActor
    public func moveToNextPage(animated: Bool = true) {
        base.presenter?.moveToNextPage(animated: animated)
    }

    /// Scrolls to the previous page.
    ///
    /// - Parameter animated: If `true`, animates the transition.
    ///                       Default is `true`.
    @MainActor
    public func moveToPreviousPage(animated: Bool = true) {
        base.presenter?.moveToPreviousPage(animated: animated)
    }

    // MARK: - Paging Callbacks

    /// Sets a closure to be called just before a page becomes visible.
    ///
    /// - Parameter block: A closure that receives the collection view and the
    ///                    page index that is about to appear.
    @MainActor
    public func onPageWillAppear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageWillAppearBlock = block
    }

    /// Sets a closure to be called immediately after a page becomes visible.
    ///
    /// - Parameter block: A closure that receives the collection view and the
    ///                    page index that appeared.
    @MainActor
    public func onPageDidAppear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageDidAppearBlock = block
    }

    /// Sets a closure to be called just before a page disappears from view.
    ///
    /// - Parameter block: A closure that receives the collection view and the
    ///                    page index that is about to disappear.
    @MainActor
    public func onPageWillDisappear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageWillDisappearBlock = block
    }

    /// Sets a closure to be called immediately after a page disappears from view.
    ///
    /// - Parameter block: A closure that receives the collection view and the
    ///                    page index that disappeared.
    @MainActor
    public func onPageDidDisappear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageDidDisappearBlock = block
    }

    // MARK: - Updating the UI

    /// Applies snapshot when using `.diffable` mode. iOS 13+ only.
    ///
    /// - Parameter animated: If true, animates the changes.
    @available(iOS 13.0, *)
    @MainActor
    public func applySnapshot(animated: Bool) {
        base.presenter?.applySnapshot(animated: animated)
    }

    // MARK: - Section Operations

    /// Appends a section to the end of the view model.
    /// - Parameter section: The section to append.
    @MainActor
    public func appendSection(_ section: SSCollectionViewModel.SectionInfo) {
        base.presenter?.viewModel = base.presenter?.viewModel.map { $0 + section }
    }

    /// Appends multiple sections to the end of the view model.
    /// - Parameter sections: The sections to append.
    @MainActor
    public func appendSections(contentsOf sections: [SSCollectionViewModel.SectionInfo]) {
        base.presenter?.viewModel = base.presenter?.viewModel.map { $0 + sections }
    }

    // MARK: - Item Operations (by Section Index)

    /// Appends an item to the specified section.
    /// - Parameters:
    ///   - item: The item to append.
    ///   - section: The index of the target section.
    @MainActor
    public func appendItem(_ item: SSCollectionViewModel.CellInfo, toSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              section < viewModel.count else { return }

        viewModel[section].append(item)
        base.presenter?.viewModel = viewModel
    }

    /// Appends multiple items to the specified section.
    /// - Parameters:
    ///   - items: The items to append.
    ///   - section: The index of the target section.
    @MainActor
    public func appendItems(contentsOf items: [SSCollectionViewModel.CellInfo], toSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              section < viewModel.count else { return }

        viewModel[section].append(contentsOf: items)
        base.presenter?.viewModel = viewModel
    }

    // MARK: - Item Operations (by Section Identifier)

    /// Appends an item to the first section matching the identifier.
    /// - Parameters:
    ///   - item: The item to append.
    ///   - identifier: The identifier of the target section.
    @MainActor
    public func appendItem(_ item: SSCollectionViewModel.CellInfo, firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel else { return }

        guard let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }) else { return }

        viewModel.sections[sectionIndex].append(item)
        base.presenter?.viewModel = viewModel
    }

    /// Appends multiple items to the first section matching the identifier.
    /// - Parameters:
    ///   - items: The items to append.
    ///   - identifier: The identifier of the target section.
    @MainActor
    public func appendItems(contentsOf items: [SSCollectionViewModel.CellInfo], firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel else { return }

        guard let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }) else { return }

        viewModel.sections[sectionIndex].append(contentsOf: items)
        base.presenter?.viewModel = viewModel
    }

    // MARK: - Item Operations (Last Section)

    /// Appends an item to the last section in the view model.
    /// - Parameter item: The item to append.
    @MainActor
    public func appendItemToLastSection(_ item: SSCollectionViewModel.CellInfo) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.isEmpty == false else { return }

        let lastIndex = viewModel.count - 1
        viewModel[lastIndex].append(item)
        base.presenter?.viewModel = viewModel
    }

    /// Appends multiple items to the last section in the view model.
    /// - Parameter items: The items to append.
    @MainActor
    public func appendItemsToLastSection(contentsOf items: [SSCollectionViewModel.CellInfo]) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.isEmpty == false else { return }

        let lastIndex = viewModel.count - 1
        viewModel[lastIndex].append(contentsOf: items)
        base.presenter?.viewModel = viewModel
    }

    // MARK: - Insert Operations

    /// Inserts an item at the specified index path.
    /// - Parameters:
    ///   - item: The item to insert.
    ///   - indexPath: The index path where the item will be inserted.
    @MainActor
    public func insertItem(_ item: SSCollectionViewModel.CellInfo, at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item <= viewModel[indexPath.section].count else { return }

        viewModel[indexPath.section].insert(item, at: indexPath.item)
        base.presenter?.viewModel = viewModel
    }

    /// Inserts multiple items starting at the specified index path.
    /// - Parameters:
    ///   - items: The items to insert.
    ///   - indexPath: The starting index path for insertion.
    @MainActor
    public func insertItems(_ items: [SSCollectionViewModel.CellInfo], at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item <= viewModel[indexPath.section].count else { return }

        viewModel[indexPath.section].insert(contentsOf: items, at: indexPath.item)
        base.presenter?.viewModel = viewModel
    }

    // MARK: - Delete Operations

    /// Deletes the item at the specified index path.
    /// - Parameter indexPath: The index path of the item to delete.
    @MainActor
    public func deleteItem(at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item < viewModel[indexPath.section].count else { return }

        viewModel[indexPath.section].remove(at: indexPath.item)
        base.presenter?.viewModel = viewModel
    }

    /// Deletes items at the specified index paths.
    /// - Parameter indexPaths: The index paths of the items to delete.
    @MainActor
    public func deleteItems(at indexPaths: [IndexPath]) {
        guard var viewModel = base.presenter?.viewModel else { return }

        let sortedIndexPaths = indexPaths.sorted {
            $0.section > $1.section ||
            ($0.section == $1.section && $0.item > $1.item)
        }

        for indexPath in sortedIndexPaths {
            guard indexPath.section < viewModel.count,
                  indexPath.item < viewModel[indexPath.section].count else { continue }
            viewModel[indexPath.section].remove(at: indexPath.item)
        }

        base.presenter?.viewModel = viewModel
    }

    /// Deletes all items in the specified section.
    /// - Parameter section: The index of the section to clear.
    @MainActor
    public func deleteAllItems(inSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              section < viewModel.count else { return }

        viewModel[section].removeAll()
        base.presenter?.viewModel = viewModel
    }

    /// Deletes an item at the specified row in the first section matching
    /// the identifier.
    /// - Parameters:
    ///   - row: The row index of the item to delete.
    ///   - identifier: The identifier of the target section.
    @MainActor
    public func deleteItem(atRow row: Int, firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel[sectionIndex].count else { return }

        viewModel[sectionIndex].remove(at: row)
        base.presenter?.viewModel = viewModel
    }

    /// Deletes all items in the first section matching the identifier.
    /// - Parameter identifier: The identifier of the section to clear.
    @MainActor
    public func deleteAllItems(firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.firstIndex(where: { $0.identifier == identifier }) else { return }

        viewModel[sectionIndex].removeAll()
        base.presenter?.viewModel = viewModel
    }

    // MARK: - Update Operations

    /// Updates the item at the specified index path.
    /// - Parameters:
    ///   - item: The new item data.
    ///   - indexPath: The index path of the item to update.
    @MainActor
    public func updateItem(_ item: SSCollectionViewModel.CellInfo, at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.sections.count,
              indexPath.row < viewModel.sections[indexPath.section].count else { return }

        viewModel[indexPath.section][indexPath.row] = item
        base.presenter?.viewModel = viewModel
    }

    /// Updates an item at the specified row in the first section matching
    /// the identifier.
    /// - Parameters:
    ///   - item: The new item data.
    ///   - row: The row index of the item to update.
    ///   - identifier: The identifier of the target section.
    @MainActor
    public func updateItem(_ item: SSCollectionViewModel.CellInfo, atRow row: Int, firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel.sections[sectionIndex].count else { return }

        viewModel[sectionIndex][row] = item
        base.presenter?.viewModel = viewModel
    }
}
