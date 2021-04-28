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
}
