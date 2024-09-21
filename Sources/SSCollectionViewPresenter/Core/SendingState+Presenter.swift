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
}
