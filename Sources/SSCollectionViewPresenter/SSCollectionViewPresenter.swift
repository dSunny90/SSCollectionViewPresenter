//
//  SSCollectionViewPresenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

// MARK: - SSCollectionViewPresenter
/// A presenter class that simplifies configuring and managing a
/// `UICollectionView` based on a `SSCollectionViewModel`.
///
/// - Overview:
///   - `SSCollectionViewPresenter` bridges the view model
///     (`SSCollectionViewModel`) with the collection view,
///     automatically handling data source and delegate methods.
///   - It allows developers to easily bind cell and supplementary view data,
///     minimizing boilerplate code while maintaining flexibility.
///   - Primarily designed for `UICollectionViewFlowLayout`.
///     `UICollectionViewCompositionalLayout` is also supported,
///     but using this with `UICollectionViewFlowLayout` is recommended.
public final class SSCollectionViewPresenter: NSObject {
    typealias SectionInfo = SSCollectionViewModel.SectionInfo
    typealias CellInfo = SSCollectionViewModel.CellInfo
    typealias ReusableViewInfo = SSCollectionViewModel.ReusableViewInfo

    // MARK: - Constant
    /// Number of times items are duplicated for infinite scrolling.
    internal let duplicatedItemCount: Int = 3

    // MARK: - LayoutKind, DataSourceMode
    /// The type of layout used by the collection view (e.g., flow, alignment).
    internal let layoutKind: LayoutKind

    /// Determines whether the data source is diffable or legacy.
    internal let dataSourceMode: DataSourceMode

    // MARK: - CollectionView
    internal weak var collectionView: UICollectionView?

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
            guard #available(iOS 13.0, *) else { return }
            guard dataSourceMode == .diffable else { return }
            diffableSupportCore?.updateSnapshot(with: viewModel)
        }
    }

    // MARK: - ActionHandler
    /// The action handler responsible for dispatching actions.
    internal var actionHandler: AnyActionHandlingProvider?

    // MARK: - Paginated API Option
    /// Closure to be called when requesting the next page of data.
    internal var nextRequestBlock: ((SSCollectionViewModel) -> Void)?

    // MARK: - UIScrollViewDelegate Proxy
    /// Proxy to forward scroll view delegate methods.
    internal weak var scrollViewDelegateProxy: UIScrollViewDelegate?

    // MARK: - FlowLayout Paging Options
    /// Enable layout-controlled paging/snap (replaces `UIScrollView.isPagingEnabled`).
    internal var isCustomPagingEnabled: Bool = false

    /// Indicates whether infinite scroll is enabled.
    internal var isInfiniteScroll: Bool = false

    /// Indicates whether auto-rolling (carousel style) is enabled.
    internal var isAutoRolling: Bool = false

    /// Time interval between auto-rolling page transitions.
    internal var pagingTimeInterval: TimeInterval = 3.0

    /// Snap pages to the viewport center when paging (custom paging required).
    internal var isAlignCenter: Bool = true

    /// Called just before a page becomes visible
    internal var pageWillAppearBlock: ((UICollectionView, Int) -> Void)?

    /// Called right after a page becomes visible
    internal var pageDidAppearBlock: ((UICollectionView, Int) -> Void)?

    /// Called just before a page is no longer visible
    internal var pageWillDisappearBlock: ((UICollectionView, Int) -> Void)?

    /// Called right after a page is no longer visible
    internal var pageDidDisappearBlock: ((UICollectionView, Int) -> Void)?

    /// Current scroll direction of the collection view layout.
    private var scrollDirection: UICollectionView.ScrollDirection {
        switch layoutKind {
        case .flow:
            return (collectionView?.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection ?? .vertical
        case .compositional(let config):
            return config?.sections.last?.direction ?? .vertical
        }
    }

    // MARK: - Paginated API Support
    /// Flag indicating whether a pagination request is in progress.
    private var isLoadingNextPage: Bool = false

    // MARK: - FlowLayout Paging Support
    /// 0-based index of the current (centered) page; updated on scroll/snap.
    private var currentPageIndex: Int = 0

    /// Effective paging flag: `true` if any paging mode is active
    /// (custom paging, infinite scroll, or auto rolling). Read-only.
    private var isPagingEnabled: Bool {
        isCustomPagingEnabled || isInfiniteScroll || isAutoRolling
    }

    // MARK: - DiffableDataSource Support
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

    // MARK: - Init
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

    // MARK: - Presenting Logic
    /// Applies the latest snapshot to the diffable data source.
    /// - Parameter animated: Whether to animate the changes.
    /// Only applies when using the `.diffable` data source mode.
    @available(iOS 13.0, *)
    internal func applySnapshot(animated: Bool) {
        guard dataSourceMode == .diffable else { return }
        diffableSupportCore?.applySnapshot(animated: animated)
    }

    // MARK: - Private Methods
    /// Configures the initial layout of the collection view,
    /// including scroll direction and layout-specific settings.
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

    /// Sets up the data source for the collection view.
    /// This may vary depending on whether the traditional or diffable mode is used.
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

    /// Determines whether the next page of data should be loaded based on
    /// current scroll position and internal loading state.
    /// - Returns: `true` if the next page should be requested; otherwise, `false`.
    private func shouldLoadNextPage() -> Bool {
        guard let collectionView,
              let viewModel, viewModel.hasNext,
              isLoadingNextPage == false
        else { return false }

        switch scrollDirection {
        case .vertical:
            if collectionView.contentOffset.y > collectionView.contentSize.height - collectionView.frame.height * 3 {
                return true
            }
        case .horizontal:
            if collectionView.contentOffset.x > collectionView.contentSize.width - collectionView.frame.width * 3 {
                return true
            }
        @unknown default:
            return false
        }
        return false
    }

    /// Cancels any pending auto-rolling operations for this instance.
    private func cancelAutoRolling() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.runAutoRolling), object: nil)
    }

    /// Triggers the next automatic scroll, then schedules the next one recursively.
    /// Requires `isAutoRolling` to be enabled and `collectionView` to be available.
    @objc private func runAutoRolling() {
        cancelAutoRolling()
        guard let collectionView else { return }
        collectionView.setAutoRollingContentOffset(isAlignCenter: isAlignCenter)
        perform(#selector(self.runAutoRolling), with: nil, afterDelay: pagingTimeInterval)
    }
}
// MARK: - SSCollectionViewPresenter Enumm, Structs, and Classes
extension SSCollectionViewPresenter {
    public enum LayoutKind {
        case flow
        case compositional(CompositionalLayoutConfig? = nil)
    }

    public enum DataSourceMode {
        case traditional
        case diffable
    }

    // MARK: - CompositionalLayoutConfig
    public struct CompositionalLayoutConfig {
        var sections: [SSCompositionalLayoutSection]

        @available(iOS 13.0, *)
        func makeLayout() -> UICollectionViewCompositionalLayout {
            return UICollectionViewCompositionalLayout { idx, _ in
                let config = self.sections[idx]

                let width: NSCollectionLayoutDimension
                if let fixedWidth = config.itemWidth {
                    width = .absolute(fixedWidth)
                } else {
                    width = .fractionalWidth(1 / CGFloat(config.columns))
                }

                let itemSize = NSCollectionLayoutSize(
                    widthDimension: width,
                    heightDimension: .absolute(config.height)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(config.height)
                )

                let group: NSCollectionLayoutGroup
                if config.direction == .horizontal {
                    if #available(iOS 16.0, *) {
                        group = NSCollectionLayoutGroup.horizontal(
                            layoutSize: groupSize,
                            repeatingSubitem: item,
                            count: config.columns
                        )
                    } else {
                        group = NSCollectionLayoutGroup.horizontal(
                            layoutSize: groupSize,
                            subitem: item,
                            count: config.columns
                        )
                    }

                    let section = NSCollectionLayoutSection(group: group)
                    section.orthogonalScrollingBehavior = .init(
                        rawValue: config.scrolling?.rawValue ?? 0
                    ) ?? .none
                    return section
                } else {
                    if #available(iOS 16.0, *) {
                        group = NSCollectionLayoutGroup.vertical(
                            layoutSize: groupSize,
                            repeatingSubitem: item,
                            count: config.columns
                        )
                    } else {
                        group = NSCollectionLayoutGroup.vertical(
                            layoutSize: groupSize,
                            subitem: item,
                            count: config.columns
                        )
                    }
                    return NSCollectionLayoutSection(group: group)
                }
            }
        }
    }

    // MARK: - DiffableSupportCore
    /// Core that encapsulates DiffableDataSource wiring for the presenter layer.
    @available(iOS 13.0, *)
    fileprivate class DiffableSupportCore {
        private var diffableDataSource: UICollectionViewDiffableDataSource<SectionInfo, CellInfo>?
        private var snapshot: NSDiffableDataSourceSnapshot<SectionInfo, CellInfo>?

        fileprivate func configureDiffableDataSource(
            in collectionView: UICollectionView,
            anyActionHandler actionHandler: AnyActionHandlingProvider? = nil
        ) {
            let dataSource = UICollectionViewDiffableDataSource<SectionInfo, CellInfo>(collectionView: collectionView) {
                collectionView, indexPath, item in
                defer {
                    if collectionView.presenter?.shouldLoadNextPage() ?? false {
                        if let viewModel = collectionView.presenter?.viewModel {
                            collectionView.presenter?.isLoadingNextPage = true
                            collectionView.presenter?.nextRequestBlock?(viewModel)
                        }
                    }
                }

                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "\(item.binderType)",
                    for: indexPath
                )
                item.bound(to: cell)
                if let actionHandler,
                   let aCell = cell as? (UIView & EventForwardingProvider)
                {
                    assignAnyActionHandler(to: aCell, handler: actionHandler)
                }
                return cell
            }

            dataSource.supplementaryViewProvider = {
                collectionView, kind, indexPath in

                guard let snapshot = self.snapshot
                else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }
                let section = snapshot.sectionIdentifiers[indexPath.section]
                let view: UICollectionReusableView

                switch kind {
                case UICollectionView.elementKindSectionHeader:
                    let reuseIdentifier = String(
                        describing: section.header?.binderType
                    )
                    let v = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: reuseIdentifier,
                        for: indexPath
                    )
                    section.header?.bound(to: v)
                    if let actionHandler,
                       let aView = v as? (UIView & EventForwardingProvider)
                    {
                        assignAnyActionHandler(to: aView,
                                               handler: actionHandler)
                    }
                    view = v
                case UICollectionView.elementKindSectionFooter:
                    let reuseIdentifier = String(
                        describing: section.footer?.binderType
                    )
                    let v = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: reuseIdentifier,
                        for: indexPath
                    )
                    section.footer?.bound(to: v)
                    if let actionHandler,
                       let aView = v as? (UIView & EventForwardingProvider)
                    {
                        assignAnyActionHandler(to: aView,
                                               handler: actionHandler)
                    }
                    view = v
                default:
                    view = UICollectionReusableView()
                }

                return view
            }
            self.diffableDataSource = dataSource
        }

        fileprivate func updateSnapshot(with viewModel: SSCollectionViewModel) {
            var snapshot = NSDiffableDataSourceSnapshot<SectionInfo, CellInfo>()
            for section in viewModel.sections {
                snapshot.appendSections([section])
                snapshot.appendItems(section.items, toSection: section)
            }
            self.snapshot = snapshot
        }

        fileprivate func applySnapshot(animated: Bool) {
            guard let snapshot else { return }
            diffableDataSource?.apply(snapshot, animatingDifferences: animated)
        }
    }
}

// MARK: - UICollectionViewDataSource
extension SSCollectionViewPresenter: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let viewModel else { return 0 }
        if viewModel.sections.isEmpty, viewModel.hasNext {
            isLoadingNextPage = true
            nextRequestBlock?(viewModel)
        }
        /// Called as part of the layout cycle to determine the number of sections.
        /// This is one of the earliest entry points in a layout pass.
        ///
        /// If you need to adjust layout-related states (e.g., content offset),
        /// defer them using `DispatchQueue.main.async` to avoid interfering
        /// with UIKit’s internal layout process.
        DispatchQueue.main.async {
            if self.isInfiniteScroll {
                collectionView.remapContentOffsetIfNeeded(duplicatedItemCount: self.duplicatedItemCount, isAlignCenter: self.isAlignCenter)
            }
            if self.isAutoRolling {
                self.perform(#selector(self.runAutoRolling), with: nil, afterDelay: 3)
            }
        }
        return viewModel.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        guard let items = viewModel?.sections[safe: section]?.items
        else { return 0 }

        let itemCount: Int
        if isInfiniteScroll, items.count > 1 {
            itemCount = items.count * duplicatedItemCount
        } else {
            itemCount = items.count
        }
        return itemCount
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel,
              let items = viewModel.sections[safe: indexPath.section]?.items
        else { return collectionView.dequeueDefaultCell(for: indexPath) }

        let itemIndex = indexPath.item % items.count
        guard let item = items[safe: itemIndex]
        else { return collectionView.dequeueDefaultCell(for: indexPath) }

        defer {
            if shouldLoadNextPage() {
                isLoadingNextPage = true
                nextRequestBlock?(viewModel)
            }
        }

        let identifier = String(describing: item.binderType)
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: identifier,
            for: indexPath
        )
        item.bound(to: cell)
        if let actionHandler,
           let aCell = cell as? (UIView & EventForwardingProvider)
        {
            assignAnyActionHandler(to: aCell, handler: actionHandler)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = viewModel?.sections[safe: indexPath.section]
        else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }
        let item: ReusableViewInfo?
        if kind == UICollectionView.elementKindSectionHeader {
            item = section.header
        } else if kind == UICollectionView.elementKindSectionFooter {
            item = section.footer
        } else {
            item = nil
        }

        guard let item
        else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let identifier = String(describing: item.binderType)
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: identifier,
            for: indexPath
        )
        item.bound(to: view)
        if let actionHandler,
           let aView = view as? (UIView & EventForwardingProvider)
        {
            assignAnyActionHandler(to: aView, handler: actionHandler)
        }
        return view
    }
}

extension SSCollectionViewPresenter: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        guard let viewModel,
              let items = viewModel.sections[safe: indexPath.section]?.items
        else { return }

        let itemIndex = indexPath.item % items.count
        guard let item = items[safe: itemIndex] else { return }
        if isInfiniteScroll {
            let lowerBoundIndex = duplicatedItemCount / 2
            let upperBoundIndex = duplicatedItemCount / 2 + 1
            if indexPath.item >= items.count && indexPath.item * lowerBoundIndex < items.count * upperBoundIndex {
                item.willDisplay(to: cell)
            }
        } else {
            item.willDisplay(to: cell)
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didEndDisplaying cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        guard let viewModel,
              let items = viewModel.sections[safe: indexPath.section]?.items
        else { return }

        let itemIndex = indexPath.item % items.count
        guard let item = items[safe: itemIndex] else { return }
        if isInfiniteScroll {
            let lowerBoundIndex = duplicatedItemCount / 2
            let upperBoundIndex = duplicatedItemCount / 2 + 1
            if indexPath.item >= items.count && indexPath.item * lowerBoundIndex < items.count * upperBoundIndex {
                item.didEndDisplaying(to: cell)
            }
        } else {
            item.didEndDisplaying(to: cell)
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplaySupplementaryView view: UICollectionReusableView,
                               forElementKind elementKind: String,
                               at indexPath: IndexPath) {
        guard let section = viewModel?.sections[safe: indexPath.section]
        else { return }

        let item: ReusableViewInfo?

        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            item = section.header
        case UICollectionView.elementKindSectionFooter:
            item = section.footer
        default:
            item = nil
        }
        item?.willDisplay(to: view)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didEndDisplayingSupplementaryView view: UICollectionReusableView,
                               forElementOfKind elementKind: String,
                               at indexPath: IndexPath) {
        guard let section = viewModel?.sections[safe: indexPath.section]
        else { return }

        let item: ReusableViewInfo?

        switch elementKind {
        case UICollectionView.elementKindSectionHeader:
            item = section.header
        case UICollectionView.elementKindSectionFooter:
            item = section.footer
        default:
            item = nil
        }
        item?.didEndDisplaying(to: view)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didHighlightItemAt indexPath: IndexPath) {
        guard let viewModel,
              let items = viewModel.sections[safe: indexPath.section]?.items
        else { return }

        let itemIndex = indexPath.item % items.count
        guard let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: indexPath.section)),
              let item = items[safe: itemIndex]
        else { return }

        item.didHighlight(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didUnhighlightItemAt indexPath: IndexPath) {
        guard let viewModel,
              let items = viewModel.sections[safe: indexPath.section]?.items
        else { return }

        let itemIndex = indexPath.item % items.count
        guard let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: indexPath.section)),
              let item = items[safe: itemIndex]
        else { return }

        item.didUnhighlight(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        guard let viewModel,
              let items = viewModel.sections[safe: indexPath.section]?.items
        else { return }

        let itemIndex = indexPath.item % items.count
        guard let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: indexPath.section)),
              let item = items[safe: itemIndex]
        else { return }

        item.didSelect(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didDeselectItemAt indexPath: IndexPath) {
        guard let viewModel,
              let items = viewModel.sections[safe: indexPath.section]?.items
        else { return }

        let itemIndex = indexPath.item % items.count
        guard let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: indexPath.section)),
              let item = items[safe: itemIndex]
        else { return }

        item.didDeselect(to: cell)
    }

    // MARK: - UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {

        func defaultItemSize(layout collectionViewLayout: UICollectionViewLayout) -> CGSize {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.itemSize
            } else {
                return .zero
            }
        }

        guard let viewModel,
              let items = viewModel.sections[safe: indexPath.section]?.items
        else { return defaultItemSize(layout: collectionViewLayout) }

        let itemIndex = indexPath.item % items.count
        guard let item = items[safe: itemIndex]
        else { return defaultItemSize(layout: collectionViewLayout) }
        return item.itemSize(constrainedTo: collectionView.bounds.size)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let sectionInfo = viewModel?.sections[safe: section],
              let sectionInset = sectionInfo.sectionInsets
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.sectionInset
            } else {
                return .zero
            }
        }
        return sectionInset
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let sectionInfo = viewModel?.sections[safe: section],
              let lineSpacing = sectionInfo.minimumLineSpacing
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.minimumLineSpacing
            } else {
                return 0
            }
        }
        return lineSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let sectionInfo = viewModel?.sections[safe: section],
              let itemSpacing = sectionInfo.minimumInteritemSpacing
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.minimumInteritemSpacing
            } else {
                return 0
            }
        }
        return itemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let header = viewModel?.sections[safe: section]?.header
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.headerReferenceSize
            } else {
                return .zero
            }
        }
        return header.viewSize(constrainedTo: collectionView.bounds.size)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let footer = viewModel?.sections[safe: section]?.footer
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.footerReferenceSize
            } else {
                return .zero
            }
        }
        return footer.viewSize(constrainedTo: collectionView.bounds.size)
    }
}

// MARK: - UIScrollViewDelegate
extension SSCollectionViewPresenter: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidScroll?(scrollView)
        guard let collectionView else { return }

        if isInfiniteScroll {
            collectionView.remapContentOffsetIfNeeded(duplicatedItemCount: duplicatedItemCount, isAlignCenter: isAlignCenter)
        }

        if isPagingEnabled {
            guard let section = viewModel?.sections.first, section.items.count > 0 else { return }
            let page = collectionView.currentPage()
            let pageIndex = Int(round(page))
            let adjustedIndex = pageIndex % section.items.count
            if currentPageIndex != adjustedIndex {
                pageDidDisappearBlock?(collectionView, currentPageIndex)
                currentPageIndex = adjustedIndex
                pageWillAppearBlock?(collectionView, currentPageIndex)
            }
        }
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidZoom?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewWillBeginDragging?(scrollView)
        guard let collectionView else { return }

        if isAutoRolling {
            cancelAutoRolling()
        }

        if isPagingEnabled {
            pageWillDisappearBlock?(collectionView, currentPageIndex)
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewDelegateProxy?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        guard let collectionView = scrollView as? UICollectionView else { return }
        if isPagingEnabled {
            let newTargetContentOffset = collectionView.getRemappedTargetContentOffset(velocity: velocity, isAlignCenter: isAlignCenter)

            switch scrollDirection {
            case .vertical:
                targetContentOffset.pointee.y = newTargetContentOffset
            case .horizontal:
                targetContentOffset.pointee.x = newTargetContentOffset
            @unknown default:
                break
            }
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegateProxy?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewWillBeginDecelerating?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidEndDecelerating?(scrollView)
        guard let collectionView else { return }

        if isAutoRolling {
            perform(#selector(self.runAutoRolling), with: nil, afterDelay: pagingTimeInterval)
        }

        if isPagingEnabled {
            pageDidAppearBlock?(collectionView, currentPageIndex)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidEndScrollingAnimation?(scrollView)
        guard let collectionView else { return }

        if isPagingEnabled {
            pageDidAppearBlock?(collectionView, currentPageIndex)
        }
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollViewDelegateProxy?.viewForZooming?(in: scrollView)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollViewDelegateProxy?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewDelegateProxy?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return scrollViewDelegateProxy?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidScrollToTop?(scrollView)
    }

    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}

fileprivate extension Collection {
    /// Safely accesses the element at the given index.
    /// Returns `nil` if the index is out of bounds.
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - ActionHandler Helper
/// Attaches a type-erased action handler to a view that forwards UI events.
/// - Parameters:
///   - view: A `UIView` conforming to `EventForwardingProvider`.
///   - handler: The `AnyActionHandlingProvider` to receive forwarded actions.
fileprivate func assignAnyActionHandler<T: UIView & EventForwardingProvider>(
    to view: T, handler: AnyActionHandlingProvider
) {
    DispatchQueue.main.async {
        view.ss.assignAnyActionHandler(to: handler)
    }
}
