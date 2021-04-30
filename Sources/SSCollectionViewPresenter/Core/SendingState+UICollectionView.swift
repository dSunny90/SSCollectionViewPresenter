//
//  SendingState+UICollectionView.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 25.04.2021.
//

import UIKit

@_exported import SendingState

extension SendingState where Base: UICollectionView {
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

    // MARK: - View Model

    /// Assigns the view model used by the presenter (sections & items source).
    ///
    /// - Parameter viewModel: The model containing sections and items.
    public func setViewModel(with viewModel: SSCollectionViewModel) {
        base.presenter?.viewModel = viewModel
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
        base.presenter?.viewModel = model
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
        base.presenter?.viewModel = model
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
        base.presenter?.viewModel = model
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
}
