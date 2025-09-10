//
//  SendingState+Presenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 02.11.2022.
//

import UIKit

@_exported import SendingState

extension SendingState where Base: UICollectionView {
    /// Sets up the presenter for the collection view with layout,
    /// action handler, and data source mode.
    /// - Parameters:
    ///   - layoutKind: Layout type (`.flow` or `.compositional`). Default is `.flow`.
    ///   - actionHandler: Optional handler for user interactions.
    ///   - dataSourceMode: Data mode (`.traditional`, `.diffable`). Default is `.traditional`.
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

    /// Assigns the view model consumed by the presenter (sections & items source).
    ///
    /// - Important:
    ///   Configure the presenter **before** setting the view model — e.g.
    ///   `setPagingEnabled(_:)`, `setInfinitePage(...)`, `setAutoRolling(...)`,
    ///   etc. The presenter uses these to compute paging/positions.
    ///   Then set the view model **right before** you refresh the UI:
    ///   - Call `reloadData()` for the classic data source, **or**
    ///   - Call `ss.applySnapshot(animated:)` when using the **diffable** data source.
    ///
    /// - Note:
    ///   This does **not** refresh the collection view by itself; it only updates
    ///   the presenter’s model. You must call `reloadData()` or `ss.applySnapshot(animated: true)`.
    ///
    /// - Parameter viewModel: The model containing sections and items.
    @MainActor
    public func setViewModel(with viewModel: SSCollectionViewModel) {
        base.presenter?.viewModel = viewModel
    }

    /// Gets the current view model used by the presenter.
    /// - Returns: The current `SSCollectionViewModel`, if available.
    @MainActor
    public func getViewModel() -> SSCollectionViewModel? {
        return base.presenter?.viewModel
    }

    @MainActor
    public func appendSection(_ section: SSCollectionViewModel.SectionInfo) {
        base.presenter?.viewModel = base.presenter?.viewModel.map { $0 + section }
    }

    @MainActor
    public func appendSections(contentsOf sections: [SSCollectionViewModel.SectionInfo]) {
        base.presenter?.viewModel = base.presenter?.viewModel.map { $0 + sections }
    }

    @MainActor
    public func appendItem(_ item: SSCollectionViewModel.CellInfo, toSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              section < viewModel.count else { return }

        viewModel[section].append(item)
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func appendItems(contentsOf items: [SSCollectionViewModel.CellInfo], toSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              section < viewModel.count else { return }

        viewModel[section].append(contentsOf: items)
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func appendItem(_ item: SSCollectionViewModel.CellInfo, firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel else { return }

        guard let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }) else { return }

        viewModel.sections[sectionIndex].append(item)
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func appendItems(contentsOf items: [SSCollectionViewModel.CellInfo], firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel else { return }

        guard let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }) else { return }

        viewModel.sections[sectionIndex].append(contentsOf: items)
        base.presenter?.viewModel = viewModel
    }


    @MainActor
    public func appendItemToLastSection(_ item: SSCollectionViewModel.CellInfo) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.isEmpty == false else { return }

        let lastIndex = viewModel.count - 1
        viewModel[lastIndex].append(item)
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func appendItemsToLastSection(contentsOf items: [SSCollectionViewModel.CellInfo]) {
        guard var viewModel = base.presenter?.viewModel,
              viewModel.isEmpty == false else { return }

        let lastIndex = viewModel.count - 1
        viewModel[lastIndex].append(contentsOf: items)
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func insertItem(_ item: SSCollectionViewModel.CellInfo, at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item <= viewModel[indexPath.section].count else { return }

        viewModel[indexPath.section].insert(item, at: indexPath.item)
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func insertItems(_ items: [SSCollectionViewModel.CellInfo], at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item <= viewModel[indexPath.section].count else { return }

        viewModel[indexPath.section].insert(contentsOf: items, at: indexPath.item)
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func deleteItem(at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.count,
              indexPath.item < viewModel[indexPath.section].count else { return }

        viewModel[indexPath.section].remove(at: indexPath.item)
        base.presenter?.viewModel = viewModel
    }

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

    @MainActor
    public func deleteAllItems(inSection section: Int) {
        guard var viewModel = base.presenter?.viewModel,
              section < viewModel.count else { return }

        viewModel[section].removeAll()
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func deleteItem(atRow row: Int, firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel[sectionIndex].count else { return }

        viewModel[sectionIndex].remove(at: row)
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func deleteAllItems(firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.firstIndex(where: { $0.identifier == identifier }) else { return }

        viewModel[sectionIndex].removeAll()
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func updateItem(_ item: SSCollectionViewModel.CellInfo, at indexPath: IndexPath) {
        guard var viewModel = base.presenter?.viewModel,
              indexPath.section < viewModel.sections.count,
              indexPath.row < viewModel.sections[indexPath.section].count else { return }

        viewModel[indexPath.section][indexPath.row] = item
        base.presenter?.viewModel = viewModel
    }

    @MainActor
    public func updateItem(_ item: SSCollectionViewModel.CellInfo, atRow row: Int, firstSectionIdentifier identifier: String) {
        guard var viewModel = base.presenter?.viewModel,
              let sectionIndex = viewModel.sections.firstIndex(where: { $0.identifier == identifier }),
              row < viewModel.sections[sectionIndex].count else { return }

        viewModel[sectionIndex][row] = item
        base.presenter?.viewModel = viewModel
    }

    /// Sets a block to be called when requesting the next page of content.
    /// - Parameter block: Closure with current view model for paging.
    @MainActor
    public func nextRequest(_ block: @escaping (SSCollectionViewModel) -> Void) {
        base.presenter?.nextRequestBlock = block
    }

    /// Enables infinite scroll. Only available with `UICollectionViewFlowLayout`.
    /// This provides custom paging behavior, so `isPagingEnabled` must be `false`.
    ///
    /// - Parameter isOn: `true` to enable (default), `false` to disable.
    ///
    /// - Important: All item sizes must be **equal**. Behavior is based on the size
    ///              of the first item and assumes uniform sizing across the section.
    @MainActor
    public func setInfinitePage(_ isOn: Bool = true) {
        base.presenter?.isInfiniteScroll = true
    }

    /// Enables auto-rolling. Only available with `UICollectionViewFlowLayout`.
    /// This provides custom paging behavior, so `isPagingEnabled` must be `false`.
    ///
    /// - Parameters:
    ///   - isOn: `true` to enable (default), `false` to disable.
    ///   - timeInterval: Delay between rolls (default: 3s).
    ///
    /// - Important: All item sizes must be **equal**. Behavior is based on the size
    ///              of the first item and assumes uniform sizing across the section.
    @MainActor
    public func setAutoRolling(_ isOn: Bool = true,
                               timeInterval: TimeInterval = 3.0) {
        base.presenter?.isAutoRolling = true
        base.presenter?.pagingTimeInterval = timeInterval
    }

    /// Enable the layout’s **custom paging** (instead of `isPagingEnabled`).
    /// - Snaps by your page span (item size + spacing) and emits page events
    ///   (`willAppear/didAppear/willDisappear/didDisappear`).
    /// - Usually **no need to call**: it's enabled automatically when you use
    ///   `setInfinitePage(...)` or `setAutoRolling(...)`.
    ///
    /// - Parameters:
    ///   - isOn: `true` to enable (default), `false` to disable.
    ///   - isAlignCenter: `true` to **snap each page to the visual center**
    ///                    of the viewport at rest (content-inset–aware),
    ///                    so the current item is always centered after paging.
    @MainActor
    public func setPagingEnabled(_ isOn: Bool = true, isAlignCenter: Bool) {
        base.presenter?.isCustomPagingEnabled = isOn
        base.presenter?.isAlignCenter = isAlignCenter
    }

    /// Forwards scroll events using a delegate proxy.
    /// - Parameter proxy: A `UIScrollViewDelegate` proxy.
    @MainActor
    public func setScrollViewDelegateProxy(_ proxy: UIScrollViewDelegate) {
        base.presenter?.scrollViewDelegateProxy = proxy
    }

    /// Sets a callback that is triggered just before a page becomes visible.
    @MainActor
    public func pageWillAppear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageWillAppearBlock = block
    }

    /// Sets a callback that is triggered immediately after a page becomes visible.
    @MainActor
    public func pageDidAppear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageDidAppearBlock = block
    }

    /// Sets a callback that is triggered just before a page is no longer visible.
    @MainActor
    public func pageWillDisappear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageWillDisappearBlock = block
    }

    /// Sets a callback that is triggered immediately after a page is no longer visible.
    @MainActor
    public func pageDidDisappear(_ block: @escaping (UICollectionView, Int) -> Void) {
        base.presenter?.pageDidDisappearBlock = block
    }

    /// Applies snapshot when using `.diffable` mode. iOS 13+ only.
    /// - Parameter animated: If true, animates the changes.
    @available(iOS 13.0, *)
    @MainActor
    public func applySnapshot(animated: Bool) {
        base.presenter?.applySnapshot(animated: animated)
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
}
