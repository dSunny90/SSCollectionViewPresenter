//
//  SSCollectionViewPresenter+NestedTypes.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 24.04.2021.
//

import UIKit

// MARK: - Nested Types

extension SSCollectionViewPresenter {
    /// Defines the layout type for the collection view.
    public enum LayoutKind {
        /// Standard flow layout with manual sizing.
        case flow

        /// Compositional layout with optional configuration.
        case compositional(CompositionalLayoutConfig? = nil)

        /// List layout with table view-like appearance (iOS 14+).
        case list(ListLayoutConfig? = nil)
    }

    /// Defines the data source implementation mode.
    public enum DataSourceMode {
        /// Classic data source using delegate callbacks.
        case traditional

        /// Modern diffable data source (iOS 13+).
        case diffable
    }


    // MARK: - CompositionalLayoutConfig

    /// Configuration for building a `UICollectionViewCompositionalLayout`.
    ///
    /// Provides a simplified way to create compositional layouts with
    /// common patterns like multi-column grids and horizontal scrolling sections.
    public struct CompositionalLayoutConfig {
        /// Section configurations for each section in the collection view.
        var sections: [SSCompositionalLayoutSection]

        /// Creates a `UICollectionViewCompositionalLayout` from the configuration.
        ///
        /// - Returns: A configured compositional layout instance.
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

    // MARK: - ListLayoutConfig

    /// Configuration for list-style collection view layouts (iOS 14+).
    ///
    /// Creates a `UICollectionViewCompositionalLayout` using
    /// `UICollectionLayoutListConfiguration` for UITableView-like appearance.
    ///
    /// # Example
    /// ```swift
    /// let config = SSCollectionViewPresenter.ListLayoutConfig(
    ///     appearance: .insetGrouped,
    ///     showsSeparators: true,
    ///     headerMode: .supplementary
    /// )
    /// collectionView.ss.setupPresenter(layoutKind: .list(config))
    /// ```
    public struct ListLayoutConfig {
        /// The visual style of the list.
        public enum Appearance: Int {
            case plain = 0
            case grouped = 1
            case insetGrouped = 2
            case sidebar = 3
            case sidebarPlain = 4
        }

        /// Header display mode for list sections.
        public enum HeaderMode: Int {
            case none = 0
            case supplementary = 1
            case firstItemInSection = 2
        }

        /// Footer display mode for list sections.
        public enum FooterMode: Int {
            case none = 0
            case supplementary = 1
        }

        /// The visual style of the list.
        public var appearance: Appearance

        /// Whether to show separators between items.
        public var showsSeparators: Bool

        /// How section headers are displayed.
        public var headerMode: HeaderMode

        /// How section footers are displayed.
        public var footerMode: FooterMode

        public init(
            appearance: Appearance = .plain,
            showsSeparators: Bool = true,
            headerMode: HeaderMode = .none,
            footerMode: FooterMode = .none
        ) {
            self.appearance = appearance
            self.showsSeparators = showsSeparators
            self.headerMode = headerMode
            self.footerMode = footerMode
        }

        /// Creates a `UICollectionViewCompositionalLayout` with list configuration.
        @available(iOS 14.0, *)
        func makeLayout() -> UICollectionViewCompositionalLayout {
            let uiAppearance: UICollectionLayoutListConfiguration.Appearance
            switch appearance {
            case .plain:        uiAppearance = .plain
            case .grouped:      uiAppearance = .grouped
            case .insetGrouped: uiAppearance = .insetGrouped
            case .sidebar:      uiAppearance = .sidebar
            case .sidebarPlain: uiAppearance = .sidebarPlain
            }

            var config = UICollectionLayoutListConfiguration(appearance: uiAppearance)
            config.showsSeparators = showsSeparators

            switch headerMode {
            case .none:                 config.headerMode = .none
            case .supplementary:        config.headerMode = .supplementary
            case .firstItemInSection:   config.headerMode = .firstItemInSection
            }

            switch footerMode {
            case .none:             config.footerMode = .none
            case .supplementary:    config.footerMode = .supplementary
            }

            return UICollectionViewCompositionalLayout.list(using: config)
        }
    }

    // MARK: - DiffableSupportCore

    /// The internal core that manages all diffable data source operations
    /// for ``SSCollectionViewPresenter``.
    ///
    /// ## Responsibilities
    /// - Creates and owns the `UICollectionViewDiffableDataSource`
    /// - Builds, stores, and applies `NSDiffableDataSourceSnapshot` instances
    /// - Configures cell and supplementary view provider closures
    /// - Manages iOS 14+ section snapshots
    ///
    /// ## Lifecycle
    /// 1. Instantiated in ``SSCollectionViewPresenter/init`` when
    ///    ``DataSourceMode/diffable`` is selected.
    /// 2. ``configureDiffableDataSource(in:anyActionHandler:)`` sets up the
    ///    data source and its providers.
    /// 3. On every view model update, ``updateSnapshot(with:)`` followed by
    ///    ``applySnapshot(animated:)`` pushes the changes to the collection view.
    ///
    /// ## Thread Safety
    /// All APIs must be called on the main thread.
    /// `UICollectionViewDiffableDataSource.apply` uses the main queue internally,
    /// but snapshot construction is performed synchronously.
    @available(iOS 13.0, *)
    internal class DiffableSupportCore {
        /// The `UICollectionViewDiffableDataSource` instance.
        ///
        /// Created during ``configureDiffableDataSource(in:anyActionHandler:)``
        /// and owns the cell provider and supplementary view provider closures.
        /// `nil` until initial configuration is complete.
        private var dataSource: UICollectionViewDiffableDataSource<SectionInfo, CellInfo>?

        /// The current `NSDiffableDataSourceSnapshot` managed by this core.
        ///
        /// Rebuilt from the view model each time ``updateSnapshot(with:)``
        /// is called, then applied to the data source via
        /// ``applySnapshot(animated:)`` or the iOS 14+
        /// ``applySectionSnapshot(_:to:animated:)``.
        /// Also used by the supplementary view provider to look up section
        /// headers and footers.
        private var snapshot: NSDiffableDataSourceSnapshot<SectionInfo, CellInfo>?

        /// Creates the diffable data source and attaches it to the
        /// collection view.
        ///
        /// Called once from
        /// ``SSCollectionViewPresenter/configureDataSource()``
        /// when the data source mode is ``DataSourceMode/diffable``.
        ///
        /// ## Cell Provider Behavior
        /// 1. Uses `CellInfo.binderType` name as the reuse identifier
        ///    to dequeue the cell.
        /// 2. Calls `CellInfo.apply(to:)` to bind data to the cell.
        /// 3. Attaches `actionHandler` if the cell conforms to
        ///    `EventForwardingProvider`.
        /// 4. Evaluates `shouldLoadNextPage()` to trigger pagination
        ///    when needed.
        ///
        /// ## Supplementary View Provider Behavior
        /// - Resolves `header` / `footer` from the snapshot's section
        ///   identifiers.
        /// - Falls back to `dequeueDefaultSupplementaryView` when no
        ///   data exists.
        ///
        /// - Parameters:
        ///   - collectionView: The collection view to bind the data
        ///     source to.
        ///   - actionHandler: Optional handler for forwarding cell
        ///     events.
        internal func configureDiffableDataSource(
            in collectionView: UICollectionView,
            anyActionHandler actionHandler: AnyActionHandlingProvider? = nil
        ) {
            let aDataSource = UICollectionViewDiffableDataSource<SectionInfo, CellInfo>(collectionView: collectionView) { cv, indexPath, item in
                defer {
                    if cv.presenter?.shouldLoadNextPage() ?? false {
                        if let viewModel = cv.presenter?.viewModel {
                            cv.presenter?.isLoadingNextPage = true
                            cv.presenter?.nextRequestBlock?(viewModel)
                        }
                    }
                }

                let id = String(describing: item.binderType)
                let cell = cv.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
                item.apply(to: cell)

                if let actionClosure = item.actionClosure {
                    cell.actionClosure = { [weak cell] actionName, input in
                        guard let cell = cell else { return }
                        actionClosure(indexPath, cell, actionName, input)
                    }
                } else {
                    cell.actionClosure = nil
                }

                if let actionHandler = actionHandler,
                   let aCell = cell as? (UIView & EventForwardingProvider)
                {
                    actionHandler.attach(to: aCell)
                }

                return cell
            }

            aDataSource.supplementaryViewProvider = { cv, kind, indexPath in
                guard let snapshot = self.snapshot,
                      let section = snapshot.sectionIdentifiers[safe: indexPath.section]
                else { return cv.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

                let item: ReusableViewInfo?

                switch kind {
                case UICollectionView.elementKindSectionHeader:
                    item = section.header
                case UICollectionView.elementKindSectionFooter:
                    item = section.footer
                default:
                    item = nil
                }

                guard let item = item else { return cv.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath)}

                let id = String(describing: item.binderType)
                let view = cv.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: id, for: indexPath)
                item.apply(to: view)

                if let actionClosure = item.actionClosure {
                    view.actionClosure = { [weak view] actionName, input in
                        guard let view = view else { return }
                        actionClosure(indexPath.section, view, actionName, input)
                    }
                } else {
                    view.actionClosure = nil
                }

                if let actionHandler = actionHandler,
                   let aView = view as? (UIView & EventForwardingProvider)
                {
                    actionHandler.attach(to: aView)
                }

                return view
            }
            self.dataSource = aDataSource
        }

        /// Builds a new snapshot from the given view model and stores it
        /// internally.
        ///
        /// This method **does not** apply the snapshot to the data source.
        /// Call ``applySnapshot(animated:)`` separately to push the changes.
        ///
        /// Automatically invoked from
        /// ``SSCollectionViewPresenter/viewModel``'s `didSet`, so external
        /// callers typically do not need to call this directly.
        ///
        /// - Parameter viewModel: The view model whose sections and items
        ///   will be converted into a snapshot.
        internal func updateSnapshot(with viewModel: SSCollectionViewModel) {
            var snapshot = NSDiffableDataSourceSnapshot<SectionInfo, CellInfo>()
            for section in viewModel.sections {
                snapshot.appendSections([section])
                snapshot.appendItems(section.items, toSection: section)
            }
            self.snapshot = snapshot
        }

        /// Applies the stored snapshot to the data source.
        ///
        /// No-op if ``updateSnapshot(with:)`` has not been called yet
        /// (i.e., `snapshot` is `nil`).
        ///
        /// When `animated` is `true`, UIKit automatically animates
        /// insertions, deletions, and moves.
        /// Pass `false` for the initial data load to avoid unnecessary
        /// animation.
        ///
        /// - Parameter animated: Whether to animate the diff-based
        ///   changes.
        internal func applySnapshot(animated: Bool) {
            guard let snapshot = snapshot else { return }
            dataSource?.apply(snapshot, animatingDifferences: animated)
        }


        /// Applies an independent section snapshot for a specific
        /// section (iOS 14+).
        ///
        /// Replaces only the items in the target section without
        /// rebuilding the full snapshot. Other sections remain unchanged.
        ///
        /// - Parameters:
        ///   - items: The `CellInfo` items to include in the section
        ///     snapshot.
        ///   - section: The target section identifier (`SectionInfo`).
        ///   - animated: Whether to animate the changes.
        @available(iOS 14.0, *)
        internal func applySectionSnapshot(
            _ items: [CellInfo],
            to section: SectionInfo,
            animated: Bool
        ) {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<CellInfo>()
            sectionSnapshot.append(items)
            dataSource?.apply(sectionSnapshot, to: section, animatingDifferences: animated)
        }

        /// Returns the current section snapshot for the given
        /// section (iOS 14+).
        ///
        /// Use this to inspect which items are currently in a specific
        /// section, or to build incremental updates on top of the
        /// existing snapshot.
        ///
        /// - Parameter section: The section identifier to query.
        /// - Returns: The `NSDiffableDataSourceSectionSnapshot` for
        ///   the section, or `nil` if the data source has not been
        ///   configured.
        @available(iOS 14.0, *)
        internal func sectionSnapshot(
            for section: SectionInfo
        ) -> NSDiffableDataSourceSectionSnapshot<CellInfo>? {
            dataSource?.snapshot(for: section)
        }

        // MARK: - iOS 15+ Reconfigure Items

        /// Reconfigures cells for the given item identifiers without reloading.
        ///
        /// This updates cell content without recreating the cell,
        /// providing better performance than `reloadItems`.
        ///
        /// - Parameter identifiers: The cell info identifiers to reconfigure.
        @available(iOS 15.0, *)
        internal func reconfigureItems(_ identifiers: [CellInfo]) {
            guard var currentSnapshot = snapshot else { return }
            currentSnapshot.reconfigureItems(identifiers)
            self.snapshot = currentSnapshot
            dataSource?.apply(currentSnapshot, animatingDifferences: false)
        }

        // MARK: - iOS 15+ Apply Snapshot Using Reload Data

        /// Applies the current snapshot without diffing, using a full reload.
        ///
        /// Use this for initial data loads or large batch updates where
        /// animation is not needed.
        @available(iOS 15.0, *)
        internal func applySnapshotUsingReloadData() {
            guard let snapshot = snapshot else { return }
            dataSource?.applySnapshotUsingReloadData(snapshot)
        }
    }

    // MARK: - PagingConfiguration

    /// Configuration for custom paging behavior in the collection view.
    ///
    /// Use this struct to enable banner-style carousels with paged scrolling,
    /// center alignment, looping, infinite scrolling, and auto-rolling.
    ///
    /// **Requirements:**
    /// - All items must have the same size (computed from the first item).
    /// - Only available for single-section layouts.
    /// - Works best without section headers or footers.
    ///
    /// # Example
    /// ```swift
    /// let config = SSCollectionViewPresenter.PagingConfiguration(
    ///     isAlignCenter: true,
    ///     isAutoRolling: true,
    ///     autoRollingTimeInterval: 4.0
    /// )
    /// collectionView.ss.setPagingEnabled(config)
    /// ```
    public struct PagingConfiguration {
        /// Enables custom paging (replaces `UIScrollView.isPagingEnabled`).
        public var isEnabled: Bool

        /// When `true`, snaps pages to the viewport center after scrolling.
        public var isAlignCenter: Bool

        /// When `true`, wraps around when reaching either end.
        public var isLooping: Bool

        /// Enables infinite scrolling by duplicating content.
        public var isInfinitePage: Bool

        /// Enables automatic page transitions at regular intervals.
        public var isAutoRolling: Bool

        /// Time interval between automatic page transitions, in seconds.
        public var autoRollingTimeInterval: TimeInterval

        public init(
            isEnabled: Bool = true,
            isAlignCenter: Bool = false,
            isLooping: Bool = false,
            isInfinitePage: Bool = false,
            isAutoRolling: Bool = false,
            autoRollingTimeInterval: TimeInterval = 3.0
        ) {
            self.isEnabled = isEnabled
            self.isAlignCenter = isAlignCenter
            self.isLooping = isLooping
            self.isInfinitePage = isInfinitePage
            self.isAutoRolling = isAutoRolling
            self.autoRollingTimeInterval = autoRollingTimeInterval
        }
    }
}
