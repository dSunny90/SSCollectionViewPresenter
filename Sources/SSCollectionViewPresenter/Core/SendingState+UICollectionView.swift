//
//  SendingState+UICollectionView.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 25.04.2021.
//

import UIKit

@_exported import SendingState

extension SendingState where Base: UICollectionView {
    public typealias Builder = SSCollectionViewModel.Builder
    public typealias SectionInfo = SSCollectionViewModel.SectionInfo
    public typealias CellInfo = SSCollectionViewModel.CellInfo
    public typealias ReusableViewInfo = SSCollectionViewModel.ReusableViewInfo

    /// Returns the currently selected items.
    ///
    /// The presenter automatically tracks selections and deselections via
    /// `collectionView(_:didSelectItemAt:)` and
    /// `collectionView(_:didDeselectItemAt:)`.
    /// When items are removed from the view model, they are also removed
    /// from this collection.
    public var selectedItems: [CellInfo] {
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

    /// Clears the selection tracking state.
    ///
    /// This only clears the presenter's internal tracking set.
    /// To also visually deselect cells, iterate
    /// `UICollectionView.indexPathsForSelectedItems` and call
    /// `deselectItem(at:animated:)` on the collection view.
    public func clearSelectedItems() {
        guard let presenter = base.presenter,
              let model = presenter.viewModel else { return }

        // Capture UI-selected index paths before we clear them
        let uiSelectedIndexPaths = Set(base.indexPathsForSelectedItems ?? [])

        // 1) Visually deselect items so UICollectionView updates its state
        //    and the delegate's didDeselect is fired for visible cells
        for indexPath in uiSelectedIndexPaths {
            base.deselectItem(at: indexPath, animated: false)
        }

        // 2) Ensure model's selection state is cleared for any items that
        //    remain selected only in the model (e.g., offscreen cells)
        for (section, sectionInfo) in model.sections.enumerated() {
            for (item, cellInfo) in sectionInfo.items.enumerated()
                where cellInfo.isSelected
            {
                let indexPath = IndexPath(item: item, section: section)
                if let cell = base.cellForItem(at: indexPath) {
                    // Forward didDeselect to the binder and clear selection flag
                    cellInfo.didDeselect(to: cell)
                } else {
                    // If the cell is not visible, just clear the selection state
                    cellInfo.isSelected = false
                }
            }
        }

        // Write back the model for consistency
        presenter.viewModel = model
    }

    /// Builds a new `SSCollectionViewModel` using a builder pattern and assigns
    /// it to the presenter.
    ///
    /// This method replaces any existing view model. After calling this method,
    /// you must manually refresh the UI by calling `collectionView.reloadData()`.
    ///
    /// # Example
    /// ```swift
    /// collectionView.ss.buildViewModel { builder in
    ///     builder.section() {
    ///         builder.cell(result.eventBanner, cellType: EventBannerCell.self)
    ///     }
    ///     builder.section() {
    ///         builder.cells(result.mainBannerList, cellType: MainBannerCell.self)
    ///     }
    ///     builder.section("productList") {
    ///         builder.header(result.productHeaderInfo, viewType: ProductHeaderView.self)
    ///         builder.footer(result.productFooterInfo, viewType: ProductFooterView.self)
    ///         builder.cells(result.productList, cellType: ProductCell.self)
    ///     }
    /// }
    ///
    /// // Refresh the UI
    /// collectionView.reloadData()
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
    @discardableResult
    public func buildViewModel(
        page: Int = 0,
        hasNext: Bool = false,
        _ build: (Builder) -> Void
    ) -> SSCollectionViewModel {
        let builder = Builder()
        build(builder)
        let model = builder.build(page: page, hasNext: hasNext)
        base.presenter?.updateViewModel(model)
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
    /// `collectionView.reloadData()`.
    ///
    /// # Example
    /// ```swift
    /// // Load next page of products
    /// collectionView.ss.extendViewModel(
    ///     page: currentPage + 1,
    ///     hasNext: response.hasNext
    /// ) { builder in
    ///     builder.section("productList") {
    ///         builder.cells(response.productList, cellType: ProductCell.self)
    ///     }
    /// }
    ///
    /// // Refresh the UI
    /// collectionView.reloadData()
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
    @discardableResult
    public func extendViewModel(
        page: Int = 0,
        hasNext: Bool = false,
        _ build: (Builder) -> Void
    ) -> SSCollectionViewModel {
        let builder = Builder()
        build(builder)

        var model = base.presenter?.viewModel ?? SSCollectionViewModel(sections: [])
        model.page = page
        model.hasNext = hasNext

        for section in builder.build().sections {
            if let sectionId = section.identifier,
               let idx = model.firstIndex(where: { $0.identifier == sectionId })
            {
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

        base.presenter?.updateViewModel(model)
        return model
    }

    // MARK: - Prefetching

    /// Sets a closure to be called when items should be prefetched.
    ///
    /// Automatically sets the collection view's `prefetchDataSource`.
    ///
    /// - Parameter block: A closure that receives the `CellInfo` for items
    ///                    to prefetch.
    @available(iOS 10.0, *)
    public func onPrefetch(_ block: @escaping ([CellInfo]) -> Void) {
        base.presenter?.prefetchBlock = block
    }

    /// Sets a closure to be called when prefetching should be cancelled.
    ///
    /// - Parameter block: A closure that receives the `CellInfo` for items
    ///                    whose prefetching should be cancelled.
    @available(iOS 10.0, *)
    public func onCancelPrefetch(_ block: @escaping ([CellInfo]) -> Void) {
        base.presenter?.cancelPrefetchBlock = block
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
        sections: [SectionInfo]
    ) -> SSCollectionViewModel {
        var model = base.presenter?.viewModel ?? SSCollectionViewModel()
        model.hasNext = hasNext
        model.setPage(page, sections: sections)
        base.presenter?.updateViewModel(model)
        return model
    }

    /// Stores sections for a given page using the builder pattern
    /// and rebuilds the merged sections array.
    ///
    /// This is a convenience overload of `loadPage(_:hasNext:sections:)`
    /// that uses `SSCollectionViewModel.Builder` for a more declarative syntax.
    ///
    /// After calling this method, you must manually refresh the UI
    /// by calling `collectionView.reloadData()`.
    ///
    /// # Example
    /// ```swift
    /// // Initial load
    /// collectionView.ss.loadPage(0, hasNext: true) { builder in
    ///     builder.section("banner") {
    ///         builder.cells(bannerList, cellType: BannerCell.self)
    ///     }
    ///     builder.section("weekly") {
    ///         builder.cells(productList, cellType: ProductCell.self)
    ///     }
    /// }
    /// collectionView.reloadData()
    ///
    /// // Next page
    /// collectionView.ss.loadPage(1, hasNext: false) { builder in
    ///     builder.section("today") {
    ///         builder.cells(productList, cellType: ProductCell.self)
    ///     }
    /// }
    /// collectionView.reloadData()
    /// ```
    ///
    /// - Parameters:
    ///   - page: The page number for this batch of data.
    ///   - hasNext: Whether more data is available for pagination.
    ///              Default is `false`.
    ///   - build: A closure that receives a `Builder` to construct the
    ///            sections for this page.
    ///
    /// - Returns: The merged `SSCollectionViewModel` after storing the page.
    @discardableResult
    public func loadPage(
        _ page: Int,
        hasNext: Bool = false,
        _ build: (Builder) -> Void
    ) -> SSCollectionViewModel {
        let builder = Builder()
        build(builder)
        let built = builder.build()
        return loadPage(page, hasNext: hasNext, sections: built.sections)
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

    // MARK: - Section Operations

    /// Appends a section to the end of the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter section: The section to append.
    public func appendSection(_ section: SectionInfo) {
        guard var viewModel = base.presenter?.viewModel else { return }
        viewModel.append(section)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Appends multiple sections to the end of the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter sections: The sections to append.
    public func appendSections(contentsOf sections: [SectionInfo]) {
        guard var viewModel = base.presenter?.viewModel else { return }
        viewModel.append(contentsOf: sections)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Inserts a section at the specified index.
    ///
    /// No-op if the index is out of bounds (`0...sectionCount`).
    ///
    /// - Parameters:
    ///   - section: The section to insert.
    ///   - index: The position at which to insert the section.
    public func insertSection(_ section: SectionInfo, at index: Int) {
        guard var viewModel = base.presenter?.viewModel,
              (0...viewModel.count).contains(index) else { return }
        viewModel.insert(section, at: index)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Inserts multiple sections starting at the specified index.
    ///
    /// No-op if the index is out of bounds (`0...sectionCount`).
    ///
    /// - Parameters:
    ///   - sections: The sections to insert.
    ///   - index: The starting position for the insertion.
    public func insertSections(_ sections: [SectionInfo], at index: Int) {
        guard var viewModel = base.presenter?.viewModel,
              (0...viewModel.count).contains(index) else { return }
        viewModel.insert(contentsOf: sections, at: index)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes the section at the specified index.
    ///
    /// No-op if the index is out of bounds.
    ///
    /// - Parameter index: The index of the section to remove.
    public func removeSection(at index: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(index) else { return }
        viewModel.remove(at: index)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes sections at the specified indices.
    ///
    /// Out-of-bounds indices are silently ignored.
    ///
    /// - Parameter indices: An `IndexSet` of section indices to remove.
    public func removeSections(at indices: IndexSet) {
        guard var viewModel = base.presenter?.viewModel else { return }
        for index in indices.sorted(by: >) {
            guard viewModel.indices.contains(index) else { continue }
            viewModel.remove(at: index)
        }
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    ///
    /// - Parameter identifier: The identifier of the section to remove.
    public func removeSection(identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let index = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel.remove(at: index)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes all sections from the view model.
    public func removeAllSections() {
        guard var viewModel = base.presenter?.viewModel else { return }
        viewModel.removeAll()
        base.presenter?.updateViewModel(viewModel)
    }

    /// Replaces the section at the specified index with a new section.
    ///
    /// No-op if the index is out of bounds.
    ///
    /// - Parameters:
    ///   - section: The replacement section.
    ///   - index: The index of the section to replace.
    public func replaceSection(_ section: SectionInfo, at index: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(index) else { return }
        viewModel[index] = section
        base.presenter?.updateViewModel(viewModel)
    }

    /// Replaces the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    ///
    /// - Parameters:
    ///   - section: The replacement section.
    ///   - identifier: The identifier of the section to replace.
    public func replaceSection(_ section: SectionInfo, identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let index = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel[index] = section
        base.presenter?.updateViewModel(viewModel)
    }

    /// Moves a section from one index to another.
    ///
    /// No-op if either index is out of bounds.
    ///
    /// - Parameters:
    ///   - fromIndex: The current index of the section.
    ///   - toIndex: The destination index for the section.
    public func moveSection(from fromIndex: Int, to toIndex: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(fromIndex),
              (0...viewModel.count - 1).contains(toIndex),
              fromIndex != toIndex
        else { return }
        let section = viewModel.remove(at: fromIndex)
        viewModel.insert(section, at: toIndex)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Returns the number of sections in the view model.
    public var sectionCount: Int {
        base.presenter?.viewModel?.count ?? 0
    }

    /// Returns the section at the specified index, or `nil` if out of bounds.
    ///
    /// - Parameter index: The index of the section.
    /// - Returns: The `SectionInfo` at the index, or `nil`.
    public func section(at index: Int) -> SectionInfo? {
        base.presenter?.viewModel?.sectionInfo(at: index)
    }

    /// Returns the first section matching the given identifier, or `nil`
    /// if not found.
    ///
    /// - Parameter identifier: The identifier to search for.
    /// - Returns: The matching `SectionInfo`, or `nil`.
    public func section(identifier: String) -> SectionInfo? {
        base.presenter?.viewModel?.sections.first(where: { $0.identifier == identifier })
    }

    /// Returns the index of the first section matching the given identifier,
    /// or `nil` if not found.
    ///
    /// - Parameter identifier: The identifier to search for.
    /// - Returns: The section index, or `nil`.
    public func sectionIndex(identifier: String) -> Int? {
        base.presenter?.viewModel?.sections.firstIndex(where: { $0.identifier == identifier })
    }

    // MARK: - Item Operations

    /// Appends an item to the section at the specified index.
    ///
    /// No-op if the section index is out of bounds.
    ///
    /// - Parameters:
    ///   - item: The item to append.
    ///   - section: The index of the target section.
    public func appendItem(_ item: CellInfo, toSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(section) else { return }
        viewModel[section].append(item)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Appends multiple items to the section at the specified index.
    ///
    /// No-op if the section index is out of bounds.
    ///
    /// - Parameters:
    ///   - items: The items to append.
    ///   - section: The index of the target section.
    public func appendItems(contentsOf items: [CellInfo], toSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(section) else { return }
        viewModel[section].append(contentsOf: items)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Appends an item to the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    ///
    /// - Parameters:
    ///   - item: The item to append.
    ///   - identifier: The identifier of the target section.
    public func appendItem(_ item: CellInfo, sectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel.sections[sectionIndex].append(item)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Appends multiple items to the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    ///
    /// - Parameters:
    ///   - items: The items to append.
    ///   - identifier: The identifier of the target section.
    public func appendItems(contentsOf items: [CellInfo], sectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel.sections[sectionIndex].append(contentsOf: items)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Appends an item to the last section in the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter item: The item to append.
    public func appendItemToLastSection(_ item: CellInfo) {
        guard var viewModel = base.presenter?.viewModel,
              !viewModel.isEmpty else { return }
        let lastIndex = viewModel.count - 1
        viewModel[lastIndex].append(item)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Appends multiple items to the last section in the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter items: The items to append.
    public func appendItemsToLastSection(contentsOf items: [CellInfo]) {
        guard var viewModel = base.presenter?.viewModel,
              !viewModel.isEmpty else { return }
        let lastIndex = viewModel.count - 1
        viewModel[lastIndex].append(contentsOf: items)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Inserts an item at the specified index path.
    ///
    /// No-op if the section or item index is out of bounds.
    ///
    /// - Parameters:
    ///   - item: The item to insert.
    ///   - indexPath: The index path where the item will be inserted.
    public func insertItem(_ item: CellInfo, at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item <= viewModel[indexPath.section].count else { return }
        viewModel[indexPath.section].insert(item, at: indexPath.item)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Inserts multiple items starting at the specified index path.
    ///
    /// No-op if the section or item index is out of bounds.
    ///
    /// - Parameters:
    ///   - items: The items to insert.
    ///   - indexPath: The starting index path for insertion.
    public func insertItems(_ items: [CellInfo], at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item <= viewModel[indexPath.section].count else { return }
        viewModel[indexPath.section].insert(contentsOf: items, at: indexPath.item)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Inserts an item at the specified row in the first section matching
    /// the given identifier.
    ///
    /// No-op if no section with the identifier exists or the row is out
    /// of bounds (`0...itemCount`).
    ///
    /// - Parameters:
    ///   - item: The item to insert.
    ///   - row: The row index for insertion.
    ///   - identifier: The identifier of the target section.
    public func insertItem(
        _ item: CellInfo,
        atRow row: Int,
        sectionIdentifier identifier: String
    ) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              (0...viewModel[sectionIndex].count).contains(row)
        else { return }
        viewModel[sectionIndex].insert(item, at: row)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Inserts multiple items starting at the specified row in the first
    /// section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists or the row is out
    /// of bounds (`0...itemCount`).
    ///
    /// - Parameters:
    ///   - items: The items to insert.
    ///   - row: The starting row index for insertion.
    ///   - identifier: The identifier of the target section.
    public func insertItems(
        _ items: [CellInfo],
        atRow row: Int,
        sectionIdentifier identifier: String
    ) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              (0...viewModel[sectionIndex].count).contains(row)
        else { return }
        viewModel[sectionIndex].insert(contentsOf: items, at: row)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes the item at the specified index path.
    ///
    /// No-op if the index path is out of bounds.
    ///
    /// - Parameter indexPath: The index path of the item to remove.
    public func removeItem(at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item < viewModel[indexPath.section].count else { return }
        viewModel[indexPath.section].remove(at: indexPath.item)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes items at the specified index paths.
    ///
    /// Out-of-bounds index paths are silently ignored.
    ///
    /// - Parameter indexPaths: The index paths of the items to remove.
    public func removeItems(at indexPaths: [IndexPath]) {
        guard var viewModel = base.presenter?.viewModel else { return }
        let sorted = indexPaths.sorted {
            $0.section > $1.section ||
            ($0.section == $1.section && $0.item > $1.item)
        }
        for indexPath in sorted {
            guard indexPath.section < viewModel.count,
                  indexPath.item < viewModel[indexPath.section].count else { continue }
            viewModel[indexPath.section].remove(at: indexPath.item)
        }
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes all items in the section at the specified index.
    ///
    /// No-op if the section index is out of bounds.
    /// The section itself remains; only its items are cleared.
    ///
    /// - Parameter section: The index of the section to clear.
    public func removeAllItems(inSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.indices.contains(section) else { return }
        viewModel[section].removeAll()
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes the item at the specified row in the first section matching
    /// the given identifier.
    ///
    /// No-op if no section with the identifier exists or the row is out
    /// of bounds.
    ///
    /// - Parameters:
    ///   - row: The row index of the item to remove.
    ///   - identifier: The identifier of the target section.
    public func removeItem(atRow row: Int, sectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel[sectionIndex].count
        else { return }
        viewModel[sectionIndex].remove(at: row)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Removes all items in the first section matching the given identifier.
    ///
    /// No-op if no section with the identifier exists.
    /// The section itself remains; only its items are cleared.
    ///
    /// - Parameter identifier: The identifier of the section to clear.
    public func removeAllItems(sectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier })
        else { return }
        viewModel[sectionIndex].removeAll()
        base.presenter?.updateViewModel(viewModel)
    }

    /// Replaces the item at the specified index path.
    ///
    /// No-op if the index path is out of bounds.
    ///
    /// - Parameters:
    ///   - item: The replacement item.
    ///   - indexPath: The index path of the item to replace.
    public func replaceItem(_ item: CellInfo, at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.row < viewModel[indexPath.section].count else { return }
        viewModel[indexPath.section][indexPath.row] = item
        base.presenter?.updateViewModel(viewModel)
    }

    /// Replaces the item at the specified row in the first section matching
    /// the given identifier.
    ///
    /// No-op if no section with the identifier exists or the row is out
    /// of bounds.
    ///
    /// - Parameters:
    ///   - item: The replacement item.
    ///   - row: The row index of the item to replace.
    ///   - identifier: The identifier of the target section.
    public func replaceItem(
        _ item: CellInfo,
        atRow row: Int,
        sectionIdentifier identifier: String
    ) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel[sectionIndex].count
        else { return }
        viewModel[sectionIndex][row] = item
        base.presenter?.updateViewModel(viewModel)
    }

    /// Moves an item from one index path to another.
    ///
    /// No-op if the source index path is out of bounds. The destination
    /// row is clamped to the valid range after removal.
    ///
    /// - Parameters:
    ///   - source: The current index path of the item.
    ///   - destination: The destination index path for the item.
    public func moveItem(from source: IndexPath, to destination: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              source.section < viewModel.count,
              source.item < viewModel[source.section].count,
              destination.section < viewModel.count
        else { return }
        let item = viewModel[source.section].remove(at: source.item)
        let clampedRow = min(destination.item, viewModel[destination.section].count)
        viewModel[destination.section].insert(item, at: clampedRow)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Returns the number of items in the section at the specified index.
    ///
    /// - Parameter section: The index of the section.
    /// - Returns: The item count, or `0` if the section index is out of bounds.
    public func itemCount(inSection section: Int) -> Int {
        base.presenter?.viewModel?.sectionInfo(at: section)?.count ?? 0
    }

    /// Returns the number of items in the first section matching
    /// the given identifier.
    ///
    /// - Parameter identifier: The identifier of the section.
    /// - Returns: The item count, or `0` if no matching section exists.
    public func itemCount(sectionIdentifier identifier: String) -> Int {
        base.presenter?.viewModel?.sections
            .first(where: { $0.identifier == identifier })?.count ?? 0
    }

    /// Returns the item at the specified index path, or `nil` if out of bounds.
    ///
    /// - Parameter indexPath: The index path of the item.
    /// - Returns: The `CellInfo` at the index path, or `nil`.
    public func item(at indexPath: IndexPath) -> CellInfo? {
        guard let viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item < viewModel[indexPath.section].count
        else { return nil }
        return viewModel[indexPath.section][indexPath.item]
    }

    /// Returns the item at the specified row in the first section matching
    /// the given identifier, or `nil` if not found.
    ///
    /// - Parameters:
    ///   - row: The row index of the item.
    ///   - identifier: The identifier of the target section.
    /// - Returns: The `CellInfo`, or `nil`.
    public func item(atRow row: Int, sectionIdentifier identifier: String) -> CellInfo? {
        guard let viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel[sectionIndex].count
        else { return nil }
        return viewModel[sectionIndex][row]
    }
}
