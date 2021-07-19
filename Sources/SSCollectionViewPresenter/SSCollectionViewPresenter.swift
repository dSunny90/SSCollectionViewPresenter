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
///
/// - Note: Primarily designed for `UICollectionViewFlowLayout`, though
///         `UICollectionViewCompositionalLayout` is also supported.
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
        didSet {
            guard let viewModel = viewModel, let collectionView = collectionView else { return }
            // iOS 14 introduced UICollectionView's registration-based API as
            // a more modern alternative to explicit register(_:) calls.
            // I know this API exists, but I have not adopted it here yet
            // because this library still supports iOS 8.
            //
            // Once I raise the library's minimum deployment target to iOS 14 or
            // later, and verify that this approach fits the library well,
            // I plan to revisit the design and consider adopting it.
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

    // MARK: - Prefetching

    /// Closure called when items should be prefetched.
    internal var prefetchBlock: (([CellInfo]) -> Void)?

    /// Closure called when prefetching should be cancelled.
    internal var cancelPrefetchBlock: (([CellInfo]) -> Void)?

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
        layoutKind: LayoutKind,
        actionHandler: ActionHandlingProvider? = nil,
        dataSourceMode: DataSourceMode = .traditional
    ) {
        self.collectionView = collectionView
        self.layoutKind = layoutKind
        if let actionHandler = actionHandler {
            self.actionHandler = AnyActionHandlingProvider(actionHandler)
        }
        self.dataSourceMode = dataSourceMode
        super.init()
        configureLayout()
        configureDataSource()
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
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

    // MARK: - Configuration

    /// Configures the collection view's layout based on the specified layout kind.
    ///
    /// Sets up either a `UICollectionViewFlowLayout` or
    /// `UICollectionViewCompositionalLayout` depending on the configuration.
    private func configureLayout() {
        guard let collectionView = collectionView else { return }
        switch layoutKind {
        case .flow:
            if collectionView.collectionViewLayout as? UICollectionViewFlowLayout == nil {
                let layout = UICollectionViewFlowLayout()
                collectionView.setCollectionViewLayout(layout, animated: false)
            }
        case .compositional(let config):
            if #available(iOS 13.0, *) {
                if let config = config, collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout == nil {
                    let layout = config.makeLayout()
                    collectionView.setCollectionViewLayout(layout, animated: false)
                }
            } else {
                assertionFailure("Compositional is not supported below iOS 13.")
            }
        case .list(let config):
            if #available(iOS 14.0, *) {
                if let config = config, collectionView.collectionViewLayout as? UICollectionViewCompositionalLayout == nil {
                    let layout = config.makeLayout()
                    collectionView.setCollectionViewLayout(layout, animated: false)
                }
            } else {
                assertionFailure("List layout is not supported below iOS 14.")
            }
        }
    }

    /// Configures the data source for the collection view.
    ///
    /// Sets up either traditional data source callbacks or a diffable data source
    /// based on the specified mode.
    private func configureDataSource() {
        guard let collectionView = collectionView else { return }
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

    /// Applies a section snapshot for a specific section.
    @available(iOS 14.0, *)
    internal func applySectionSnapshot(
        _ items: [CellInfo],
        to section: SectionInfo,
        animated: Bool
    ) {
        guard dataSourceMode == .diffable else { return }
        diffableSupportCore?.applySectionSnapshot(items, to: section, animated: animated)
    }

    /// Returns the current section snapshot for a given section.
    @available(iOS 14.0, *)
    internal func sectionSnapshot(
        for section: SectionInfo
    ) -> NSDiffableDataSourceSectionSnapshot<CellInfo>? {
        diffableSupportCore?.sectionSnapshot(for: section)
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
