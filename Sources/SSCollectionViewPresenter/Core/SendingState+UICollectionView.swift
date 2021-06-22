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

    // MARK: - Section Operations

    /// Appends a section to the end of the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter section: The section to append.
    public func appendSection(_ section: SSCollectionViewModel.SectionInfo) {
        guard var viewModel = base.presenter?.viewModel else { return }
        viewModel.append(section)
        base.presenter?.updateViewModel(viewModel)
    }

    /// Appends multiple sections to the end of the view model.
    ///
    /// No-op if the view model is empty.
    ///
    /// - Parameter sections: The sections to append.
    public func appendSections(contentsOf sections: [SSCollectionViewModel.SectionInfo]) {
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
    public func insertSection(_ section: SSCollectionViewModel.SectionInfo, at index: Int) {
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
    public func insertSections(_ sections: [SSCollectionViewModel.SectionInfo], at index: Int) {
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
    public func replaceSection(_ section: SSCollectionViewModel.SectionInfo, at index: Int) {
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
    public func replaceSection(_ section: SSCollectionViewModel.SectionInfo, identifier: String) {
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
    public func section(at index: Int) -> SSCollectionViewModel.SectionInfo? {
        base.presenter?.viewModel?.sectionInfo(at: index)
    }

    /// Returns the first section matching the given identifier, or `nil`
    /// if not found.
    ///
    /// - Parameter identifier: The identifier to search for.
    /// - Returns: The matching `SectionInfo`, or `nil`.
    public func section(identifier: String) -> SSCollectionViewModel.SectionInfo? {
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
}
