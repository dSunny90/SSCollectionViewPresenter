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

    // MARK: - Reorder

    /// Whether drag & drop reordering is enabled.
    internal var isReorderEnabled: Bool = false

    /// Determines if a specific item can be dragged. Defaults to `true` if nil.
    internal var canDragItemBlock: ((CellInfo) -> Bool)?

    /// Called with the items about to move, before the snapshot is applied.
    internal var willReorderBlock: (([(indexPath: IndexPath, cellInfo: CellInfo)]) -> Void)?

    /// Called after the snapshot is applied with moved items and destination.
    internal var didReorderBlock: (([(indexPath: IndexPath, cellInfo: CellInfo)], IndexPath) -> Void)?

    /// Provides custom `UIDragPreviewParameters` for a dragged item.
    internal var dragPreviewParametersBlock: ((IndexPath) -> UIDragPreviewParameters?)?

    /// Provides a custom preview view for a dragged item. Returns nil for default.
    internal var dragPreviewProviderBlock: ((CellInfo) -> UIView?)?

    // MARK: - External Drag & Drop Handlers (iPad)

    /// Whether external drag & drop is enabled.
    ///
    /// When enabled, items can be dragged out to or dropped in from
    /// other apps on iPad.
    internal var isExternalDragDropEnabled: Bool = false

    /// Optional provider to build an NSItemProvider
    /// for a given cell & cell info when a drag begins.
    internal var dragItemProviderBlock: ((UICollectionViewCell, CellInfo) -> NSItemProvider?)?

    /// UTType identifiers accepted for external drops.
    /// Only drop sessions advertising a matching type are forwarded to
    /// `externalDropHandler`.
    internal var acceptedExternalDropTypeIdentifiers: [String] = []

    /// Converts an externally dropped value into a `CellInfo` at the
    /// destination index path. Return `nil` to reject the drop.
    internal var externalDropHandler: ((Any?, IndexPath) -> CellInfo?)?

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
        actionHandler: (any ActionHandlingProvider)? = nil,
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

    // MARK: - Section/Item Control

    /// Updates the state of a visible cell without reloading it.
    ///
    /// Applies `newState` directly to the bound cell if it is currently visible.
    /// Has no effect if the cell is not visible or if `newState` does not match
    /// the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the cell.
    ///   - indexPath: The index path of the cell to update.
    internal func reconfigureItem<T>(_ newState: T, at indexPath: IndexPath) {
        guard let collectionView = collectionView,
              let item = viewModel?[safe: indexPath.section]?[safe: indexPath.item],
              item.state is T else { return }

        if let cell = collectionView.cellForItem(at: indexPath) {
            item.state = newState
            item.apply(to: cell)
        }
    }

    /// Updates the state of a visible section header without reloading it.
    ///
    /// Applies `newState` directly to the bound supplementary view if it is
    /// currently visible. Has no effect if the header is not visible or if
    /// `newState` does not match the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the header view.
    ///   - section: The index of the section whose header to update.
    internal func reconfigureHeader<T>(_ newState: T, at section: Int) {
        guard let collectionView = collectionView,
              let header = viewModel?[safe: section]?.header,
              header.state is T else { return }

        if let view = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: section)
        ) {
            header.state = newState
            header.apply(to: view)
        }
    }

    /// Updates the state of a visible section footer without reloading it.
    ///
    /// Applies `newState` directly to the bound supplementary view if it is
    /// currently visible. Has no effect if the footer is not visible or if
    /// `newState` does not match the existing state type.
    ///
    /// - Parameters:
    ///   - newState: The new state to apply to the footer view.
    ///   - section: The index of the section whose footer to update.
    internal func reconfigureFooter<T>(_ newState: T, at section: Int) {
        guard let collectionView = collectionView,
              let footer = viewModel?[safe: section]?.footer,
              footer.state is T else { return }

        if let view = collectionView.supplementaryView(
            forElementKind: UICollectionView.elementKindSectionFooter,
            at: IndexPath(item: 0, section: section)
        ) {
            footer.state = newState
            footer.apply(to: view)
        }
    }

    /// Clears the selection tracking state.
    ///
    /// This only clears the presenter's internal tracking set.
    /// To also visually deselect cells, iterate
    /// `UICollectionView.indexPathsForSelectedItems` and call
    /// `deselectItem(at:animated:)` on the collection view.
    internal func clearSelectedItems() {
        guard let collectionView = collectionView,
              let viewModel = viewModel else { return }

        // Capture UI-selected index paths before we clear them
        let indexPaths = Set(collectionView.indexPathsForSelectedItems ?? [])

        // 1) Visually deselect items so UICollectionView updates its state
        //    and the delegate's didDeselect is fired for visible cells
        for indexPath in indexPaths {
            collectionView.deselectItem(at: indexPath, animated: false)
        }

        // 2) Ensure model's selection state is cleared for any items that
        //    remain selected only in the model (e.g., offscreen cells)
        for (section, sectionInfo) in viewModel.sections.enumerated() {
            for (item, cellInfo) in sectionInfo.items.enumerated()
            where cellInfo.isSelected
            {
                let indexPath = IndexPath(item: item, section: section)
                if let cell = collectionView.cellForItem(at: indexPath) {
                    // Forward didDeselect to the binder and clear selection flag
                    cellInfo.didDeselect(to: cell)
                } else {
                    // If the cell is not visible, just clear the selection state
                    cellInfo.isSelected = false
                }
            }
        }

        // Write back the model for consistency
        self.viewModel = viewModel
    }

    /// Toggles the collapsed state of the specified section and animates
    /// the changes.
    ///
    /// Updates `isCollapsed` on the section model before calling
    /// `performBatchUpdates` to keep the data source consistent
    /// during animation.
    ///
    /// - Parameters:
    ///   - section: The index of the section to toggle.
    ///   - completion: A closure called after the animation completes.
    ///                 Receives `true` if the section is now expanded,
    ///                 `false` if collapsed.
    internal func toggleSection(_ section: Int, completion: @escaping ((Bool) -> Void)) {
        guard let collectionView = collectionView,
              var model = viewModel else { return }

        let wasCollapsed = model[section].isCollapsed
        let indexPaths = (0..<model[section].count).map {
            IndexPath(item: $0, section: section)
        }

        model[section].isCollapsed = !wasCollapsed
        self.viewModel = model

        collectionView.performBatchUpdates {
            if wasCollapsed {
                collectionView.insertItems(at: indexPaths)
            } else {
                collectionView.deleteItems(at: indexPaths)
            }
        } completion: { _ in
            completion(!wasCollapsed)
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
                self.diffableSupportCore?.presenter = self
                self.diffableSupportCore?.configureDiffableDataSource(
                    in: collectionView,
                    anyActionHandler: actionHandler
                )
            } else {
                assertionFailure("Diffable is not supported below iOS 13.")
            }
        }
    }

    // MARK: - Drag&Drop Configuration

    /// Configures drag & drop on the collection view.
    ///
    /// When either `isReorderEnabled` or `isExternalDragDropEnabled` is
    /// `true`, sets `dragInteractionEnabled = true` and assigns the
    /// presenter as both `dragDelegate` and `dropDelegate`.
    ///
    /// If `isReorderEnabled` is `true` and the data source is `.diffable`,
    /// reordering handlers are also applied via
    /// `DiffableSupportCore.configureReorderingHandlers(canDragItem:willReorder:didReorder:)`.
    ///
    /// - Note: Both reordering and external drag & drop are incompatible
    ///   with infinite paging. If either is enabled alongside
    ///   `isInfinitePage`, an assertion failure is triggered and both
    ///   flags are reset to `false`.
    internal func configureDragDrop() {
        guard let collectionView = collectionView else { return }
        if isReorderEnabled || isExternalDragDropEnabled {
            guard !isInfinitePage else {
                assertionFailure(
                    "⚠️ [SSCollectionViewPresenter] Reorder / External Drag&Drop is not supported with infinite paging."
                )
                isReorderEnabled = false
                isExternalDragDropEnabled = false
                return
            }
            collectionView.dragInteractionEnabled = true
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self

            if isReorderEnabled, #available(iOS 14.0, *), dataSourceMode == .diffable {
                diffableSupportCore?.configureReorderingHandlers(
                    canDragItem: canDragItemBlock,
                    willReorder: willReorderBlock,
                    didReorder: didReorderBlock
                )
            }
        } else {
            collectionView.dragInteractionEnabled = false
            collectionView.dragDelegate = nil
            collectionView.dropDelegate = nil
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

    // MARK: - iOS 15+ Features

    /// Reconfigures cells without reloading them.
    @available(iOS 15.0, *)
    internal func reconfigureItems(_ identifiers: [CellInfo]) {
        guard dataSourceMode == .diffable else { return }
        diffableSupportCore?.reconfigureItems(identifiers)
    }

    /// Applies the snapshot using a full reload without diffing.
    @available(iOS 15.0, *)
    internal func applySnapshotUsingReloadData() {
        guard dataSourceMode == .diffable else { return }
        diffableSupportCore?.applySnapshotUsingReloadData()
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
