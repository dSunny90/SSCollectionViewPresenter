//
//  SSCollectionViewPresenter+FlowLayout.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 24.04.2021.
//

import UIKit

// MARK: - UICollectionViewDelegateFlowLayout

extension SSCollectionViewPresenter: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        guard let items = viewModel?[safe: indexPath.section]?.items,
              let item = items[safe: indexPath.item % items.count] else { return }

        if isInfinitePage {
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
        guard let items = viewModel?[safe: indexPath.section]?.items,
              let item = items[safe: indexPath.item % items.count] else { return }

        if isInfinitePage {
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
        guard let section = viewModel?[safe: indexPath.section] else { return }

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
        guard let section = viewModel?[safe: indexPath.section] else { return }

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
        guard let items = viewModel?[safe: indexPath.section]?.items else { return }
        let adjustedIndexPath = IndexPath(item: indexPath.item % items.count, section: indexPath.section)

        guard let cell = collectionView.cellForItem(at: adjustedIndexPath),
              let item = items[safe: indexPath.item % items.count] else { return }

        item.didHighlight(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didUnhighlightItemAt indexPath: IndexPath) {
        guard let items = viewModel?[safe: indexPath.section]?.items else { return }
        let adjustedIndexPath = IndexPath(item: indexPath.item % items.count, section: indexPath.section)

        guard let cell = collectionView.cellForItem(at: adjustedIndexPath),
              let item = items[safe: indexPath.item % items.count] else { return }

        item.didUnhighlight(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        guard let items = viewModel?[safe: indexPath.section]?.items else { return }
        let adjustedIndexPath = IndexPath(item: indexPath.item % items.count, section: indexPath.section)

        guard let cell = collectionView.cellForItem(at: adjustedIndexPath),
              let item = items[safe: indexPath.item % items.count] else { return }

        item.didSelect(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didDeselectItemAt indexPath: IndexPath) {
        guard let items = viewModel?[safe: indexPath.section]?.items else { return }
        let adjustedIndexPath = IndexPath(item: indexPath.item % items.count, section: indexPath.section)

        guard let cell = collectionView.cellForItem(at: adjustedIndexPath),
              let item = items[safe: indexPath.item % items.count] else { return }

        item.didDeselect(to: cell)
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let sectionInfo = viewModel?[safe: indexPath.section]
        else { return defaultItemSize(layout: collectionViewLayout) }

        guard let item = sectionInfo.items[safe: indexPath.item % sectionInfo.items.count]
        else { return defaultItemSize(layout: collectionViewLayout) }

        if sectionInfo.gridColumnCount != nil {
            let cellSize = gridItemSize(
                collectionView,
                layout: collectionViewLayout,
                sectionInfo: sectionInfo,
                cellInfo: item
            ) ?? defaultItemSize(layout: collectionViewLayout)
            return cellSize
        } else {
            let cellSize = item.size(
                constrainedTo: collectionView.bounds.size
            ) ?? defaultItemSize(layout: collectionViewLayout)
            return cellSize
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let sectionInfo = viewModel?[safe: section]
        else { return defaultSectionInset(layout: collectionViewLayout) }

        let sectionInset = sectionInfo.sectionInset ?? defaultSectionInset(layout: collectionViewLayout)

        if let gridColumns = sectionInfo.gridColumnCount, gridColumns == 0 {
            if (collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection == .horizontal {
                return UIEdgeInsets(top: 0,
                                    left: sectionInset.left,
                                    bottom: 0,
                                    right: sectionInset.bottom)
            } else {
                return UIEdgeInsets(top: sectionInset.top,
                                    left: 0,
                                    bottom: sectionInset.bottom,
                                    right: 0)
            }
        }

        return sectionInset
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let lineSpacing = viewModel?[safe: section]?.minimumLineSpacing
        else { return defaultMinimumLineSpacing(layout: collectionViewLayout) }

        return lineSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let itemSpacing = viewModel?[safe: section]?.minimumInteritemSpacing
        else { return defaultMinimumInteritemSpacing(layout: collectionViewLayout) }

        return itemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let viewSize = viewModel?[safe: section]?.header?.size(constrainedTo: collectionView.bounds.size)
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.headerReferenceSize
            } else {
                return .zero
            }
        }

        return viewSize
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let viewSize = viewModel?[safe: section]?.footer?.size(constrainedTo: collectionView.bounds.size)
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.footerReferenceSize
            } else {
                return .zero
            }
        }

        return viewSize
    }

    func defaultItemSize(layout collectionViewLayout: UICollectionViewLayout) -> CGSize {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.itemSize
        } else {
            return .zero
        }
    }

    private func defaultSectionInset(
        layout collectionViewLayout: UICollectionViewLayout
    ) -> UIEdgeInsets {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.sectionInset
        } else {
            return .zero
        }
    }

    private func defaultMinimumLineSpacing(
        layout collectionViewLayout: UICollectionViewLayout
    ) -> CGFloat {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.minimumLineSpacing
        } else {
            return 0
        }
    }

    private func defaultMinimumInteritemSpacing(
        layout collectionViewLayout: UICollectionViewLayout
    ) -> CGFloat {
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            return flowLayout.minimumInteritemSpacing
        } else {
            return 0
        }
    }

    private func gridItemSize(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sectionInfo: SectionInfo,
        cellInfo: CellInfo
    ) -> CGSize? {
        guard let gridColumns = sectionInfo.gridColumnCount else { return nil }

        let scrollDirection = (collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection ?? .vertical

        if gridColumns > 0 {
            let inset = sectionInfo.sectionInset ?? defaultSectionInset(layout: collectionViewLayout)
            let spacing = sectionInfo.minimumInteritemSpacing ?? defaultMinimumInteritemSpacing(layout: collectionViewLayout)

            if scrollDirection == .horizontal {
                let margins = inset.top + inset.bottom + spacing * (CGFloat(gridColumns) - 1)
                let itemHeight = (collectionView.bounds.size.height - margins) / CGFloat(gridColumns)
                let itemWidth = cellInfo.size(
                    constrainedTo: CGSize(
                        width: collectionView.bounds.size.width,
                        height: itemHeight
                    )
                )?.width ?? defaultItemSize(layout: collectionViewLayout).width
                return CGSize(width: itemWidth, height: itemHeight)
            } else {
                let margins = inset.left + inset.right + spacing * (CGFloat(gridColumns) - 1)
                let itemWidth = (collectionView.bounds.size.width - margins) / CGFloat(gridColumns)
                let itemHeight = cellInfo.size(
                    constrainedTo: CGSize(
                        width: itemWidth,
                        height: collectionView.bounds.size.height
                    )
                )?.height ?? defaultItemSize(layout: collectionViewLayout).height
                return CGSize(width: itemWidth, height: itemHeight)
            }
        } else if gridColumns == 0 {
            if scrollDirection == .horizontal {
                let itemWidth = cellInfo.size(
                    constrainedTo: collectionView.bounds.size
                )?.width ?? defaultItemSize(layout: collectionViewLayout).width
                return CGSize(width: itemWidth, height: collectionView.bounds.size.height)
            } else {
                let itemHeight = cellInfo.size(
                    constrainedTo: collectionView.bounds.size
                )?.height ?? defaultItemSize(layout: collectionViewLayout).height
                return CGSize(width: collectionView.bounds.size.width, height: itemHeight)
            }
        }
        return nil
    }
}
