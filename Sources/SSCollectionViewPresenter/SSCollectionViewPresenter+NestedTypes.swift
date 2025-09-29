//
//  SSCollectionViewPresenter+NestedTypes.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
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
    @MainActor
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

    // MARK: - DiffableSupportCore

    /// Encapsulates diffable data source functionality for the presenter.
    ///
    /// Handles snapshot management and provides cell/supplementary view
    /// configuration for the diffable data source.
    @available(iOS 13.0, *)
    @MainActor
    internal class DiffableSupportCore {
        /// The diffable data source instance.
        private var dataSource: UICollectionViewDiffableDataSource<SectionInfo, CellInfo>?

        /// The current snapshot being managed.
        private var snapshot: NSDiffableDataSourceSnapshot<SectionInfo, CellInfo>?

        /// Configures the diffable data source for the collection view.
        ///
        /// Sets up cell and supplementary view providers with automatic
        /// action handler binding.
        ///
        /// - Parameters:
        ///   - collectionView: The collection view to configure.
        ///   - actionHandler: Optional action handler for event forwarding.
        internal func configureDiffableDataSource(
            in collectionView: UICollectionView,
            anyActionHandler actionHandler: AnyActionHandlingProvider? = nil
        ) {
            let aDataSource = UICollectionViewDiffableDataSource<SectionInfo, CellInfo>(collectionView: collectionView) {
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
                item.apply(to: cell)
                if let actionHandler,
                   let aCell = cell as? (UIView & EventForwardingProvider)
                {
                    actionHandler.attach(to: aCell)
                }
                return cell
            }

            aDataSource.supplementaryViewProvider = {
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
                    section.header?.apply(to: v)
                    if let actionHandler,
                       let aView = v as? (UIView & EventForwardingProvider)
                    {
                        actionHandler.attach(to: aView)
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
                    section.footer?.apply(to: v)
                    if let actionHandler,
                       let aView = v as? (UIView & EventForwardingProvider)
                    {
                        actionHandler.attach(to: aView)
                    }
                    view = v
                default:
                    view = UICollectionReusableView()
                }

                return view
            }
            self.dataSource = aDataSource
        }

        /// Updates the internal snapshot with the given view model.
        ///
        /// Builds a new snapshot by iterating through sections and items.
        /// Does not apply the snapshot automatically.
        ///
        /// - Parameter viewModel: The view model to convert into a snapshot.
        internal func updateSnapshot(with viewModel: SSCollectionViewModel) {
            var snapshot = NSDiffableDataSourceSnapshot<SectionInfo, CellInfo>()
            for section in viewModel.sections {
                snapshot.appendSections([section])
                snapshot.appendItems(section.items, toSection: section)
            }
            self.snapshot = snapshot
        }

        /// Applies the current snapshot to the data source.
        ///
        /// - Parameter animated: Whether to animate the changes.
        internal func applySnapshot(animated: Bool) {
            guard let snapshot else { return }
            dataSource?.apply(snapshot, animatingDifferences: animated)
        }
    }
}
