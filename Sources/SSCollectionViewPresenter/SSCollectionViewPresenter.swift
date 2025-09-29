//
//  SSCollectionViewPresenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

// MARK: - SSCollectionViewPresenter

/// Simplifies configuring and managing a `UICollectionView` with a
/// `SSCollectionViewModel`.
///
/// `SSCollectionViewPresenter` bridges your view model with the collection view,
/// automatically handling data source and delegate methods. It provides an
/// easy way to bind cell and supplementary view data with minimal boilerplate.
///
/// - Note: Primarily designed for `UICollectionViewFlowLayout`, though
///         `UICollectionViewCompositionalLayout` is also supported.
@MainActor
public final class SSCollectionViewPresenter: NSObject {
    typealias SectionInfo = SSCollectionViewModel.SectionInfo
    typealias CellInfo = SSCollectionViewModel.CellInfo
    typealias ReusableViewInfo = SSCollectionViewModel.ReusableViewInfo

    // MARK: - Constants

    /// Number of times items are duplicated for infinite scrolling.
    internal let duplicatedItemCount: Int = 3

    // MARK: - Configuration

    /// The layout type used by the collection view.
    internal let layoutKind: LayoutKind

    /// The data source mode (diffable or classic).
    internal let dataSourceMode: DataSourceMode

    // MARK: - ViewModel

    /// The current view model backing the collection view.
    internal var viewModel: SSCollectionViewModel? {
        willSet {
            guard let collectionView else { return }
            if isPagingEnabled {
                pageWillAppearBlock?(collectionView, currentPageIndex)
            }
        }
        didSet {
            guard let viewModel, let collectionView else { return }
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
            if isPagingEnabled {
                pageDidAppearBlock?(collectionView, currentPageIndex)
            }

            if #available(iOS 13.0, *) {
                if dataSourceMode == .diffable {
                    diffableSupportCore?.updateSnapshot(with: viewModel)
                }
            }
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

    /// Enables custom paging (replaces `UIScrollView.isPagingEnabled`).
    internal var isCustomPagingEnabled: Bool = false {
        didSet {
            guard isCustomPagingEnabled else {
                isAlignCenter = false
                isInfinitePage = false
                isAutoRolling = false
                return
            }
        }
    }

    /// When `true`, snaps pages to the viewport center after scrolling.
    internal var isAlignCenter: Bool = true

    /// Enables infinite scrolling by duplicating content.
    internal var isInfinitePage: Bool = false

    /// Enables automatic page transitions at regular intervals.
    internal var isAutoRolling: Bool = false

    /// When `true`, wraps around when reaching either end.
    internal var isLooping: Bool = false

    /// Time interval between automatic page transitions, in seconds.
    internal var pagingTimeInterval: TimeInterval = 3.0

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

    // MARK: - Diffable Data Source Support

    @available(iOS 13.0, *)
    private var diffableSupportCore: DiffableSupportCore? {
        get {
            _diffableSupportCore as? DiffableSupportCore
        }
        set {
            _diffableSupportCore = newValue
        }
    }

    private var _diffableSupportCore: Any?

    // MARK: - Initialization

    public init(
        collectionView: UICollectionView,
        layoutKind: LayoutKind,
        actionHandler: (any ActionHandlingProvider)? = nil,
        dataSourceMode: DataSourceMode = .traditional
    ) {
        self.collectionView = collectionView
        if let actionHandler {
            self.actionHandler = AnyActionHandlingProvider(actionHandler)
        }
        self.dataSourceMode = dataSourceMode
        self.layoutKind = layoutKind
        super.init()
        configureLayout()
        configureDataSource()
        collectionView.delegate = self
        collectionView.registerDefaultCell()
        collectionView.registerDefaultReusableViews(
            ofKind: UICollectionView.elementKindSectionHeader
        )
        collectionView.registerDefaultReusableViews(
            ofKind: UICollectionView.elementKindSectionFooter
        )
    }

    // MARK: - Presentation

    /// Applies the current snapshot to the diffable data source.
    ///
    /// Only applies when using the `.diffable` data source mode. Has no effect
    /// in traditional mode.
    ///
    /// - Parameter animated: Whether to animate the changes.
    @available(iOS 13.0, *)
    internal func applySnapshot(animated: Bool) {
        guard dataSourceMode == .diffable else { return }
        diffableSupportCore?.applySnapshot(animated: animated)
    }

    /// Scrolls to the next page programmatically.
    ///
    /// Cancels any active auto-rolling. If an animation is already in progress,
    /// the request is queued.
    ///
    /// - Parameter animated: Whether to animate the transition.
    internal func moveToNextPage(animated: Bool) {
        guard let collectionView else { return }
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
        guard let collectionView else { return }
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

    // MARK: - Configuration

    /// Configures the collection view's layout based on the specified layout kind.
    ///
    /// Sets up either a `UICollectionViewFlowLayout` or
    /// `UICollectionViewCompositionalLayout` depending on the configuration.
    private func configureLayout() {
        guard let collectionView else { return }
        switch layoutKind {
        case .flow:
            if collectionView.collectionViewLayout as? UICollectionViewFlowLayout == nil {
                let layout = UICollectionViewFlowLayout()
                collectionView.setCollectionViewLayout(layout, animated: false)
            }
        case .compositional(let config):
            if #available(iOS 13.0, *) {
                if let config, collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout == nil {
                    let layout = config.makeLayout()
                    collectionView.setCollectionViewLayout(layout, animated: false)
                }
            } else {
                assertionFailure("Compositional is not supported below iOS 13.")
            }
        }
    }

    /// Configures the data source for the collection view.
    ///
    /// Sets up either traditional data source callbacks or a diffable data source
    /// based on the specified mode.
    private func configureDataSource() {
        guard let collectionView else { return }
        switch dataSourceMode {
        case .traditional:
            collectionView.dataSource = self
        case .diffable:
            if #available(iOS 13.0, *) {
                self.diffableSupportCore = DiffableSupportCore()
                self.diffableSupportCore?.configureDiffableDataSource(
                    in: collectionView,
                    anyActionHandler: actionHandler
                )
            } else {
                assertionFailure("Diffable is not supported below iOS 13.")
            }
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
        guard let collectionView,
              let viewModel, viewModel.hasNext,
              isLoadingNextPage == false
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
        guard let collectionView else { return }
        collectionView.scrollPages(by: 1, animated: true)
        perform(
            #selector(self.runAutoRolling),
            with: nil,
            afterDelay: pagingTimeInterval
        )
    }
}
