//
//  SSCollectionViewPresenter+FlowLayout.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

// MARK: - UICollectionViewDelegateFlowLayout

extension SSCollectionViewPresenter: UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView,
                               willDisplay cell: UICollectionViewCell,
                               forItemAt indexPath: IndexPath) {
        guard let viewModel,
              let items = viewModel[safe: indexPath.section]?.items else { return }

        let itemIndex = indexPath.item % items.count
        guard let item = items[safe: itemIndex] else { return }

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
        guard let viewModel,
              let items = viewModel[safe: indexPath.section]?.items else { return }

        let itemIndex = indexPath.item % items.count
        guard let item = items[safe: itemIndex] else { return }

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

        let itemIndex = indexPath.item % items.count
        guard let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: indexPath.section)),
              let item = items[safe: itemIndex] else { return }

        item.didHighlight(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didUnhighlightItemAt indexPath: IndexPath) {
        guard let items = viewModel?[safe: indexPath.section]?.items else { return }

        let itemIndex = indexPath.item % items.count
        guard let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: indexPath.section)),
              let item = items[safe: itemIndex] else { return }

        item.didUnhighlight(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        guard let items = viewModel?[safe: indexPath.section]?.items else { return }

        let itemIndex = indexPath.item % items.count
        guard let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: indexPath.section)),
              let item = items[safe: itemIndex] else { return }

        item.didSelect(to: cell)
    }

    public func collectionView(_ collectionView: UICollectionView,
                               didDeselectItemAt indexPath: IndexPath) {
        guard let items = viewModel?[safe: indexPath.section]?.items else { return }

        let itemIndex = indexPath.item % items.count
        guard let cell = collectionView.cellForItem(at: IndexPath(item: itemIndex, section: indexPath.section)),
              let item = items[safe: itemIndex] else { return }

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

        guard let items = viewModel?[safe: indexPath.section]?.items
        else { return defaultItemSize(layout: collectionViewLayout) }

        let itemIndex = indexPath.item % items.count
        guard let itemSize = items[safe: itemIndex]?.itemSize(constrainedTo: collectionView.bounds.size)
        else { return defaultItemSize(layout: collectionViewLayout) }

        return itemSize
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let sectionInset = viewModel?[safe: section]?.sectionInsets
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
        guard let lineSpacing = viewModel?[safe: section]?.minimumLineSpacing
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
        guard let itemSpacing = viewModel?[safe: section]?.minimumInteritemSpacing
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
        guard let viewSize = viewModel?[safe: section]?.header?.viewSize(constrainedTo: collectionView.bounds.size)
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
        guard let viewSize = viewModel?[safe: section]?.footer?.viewSize(constrainedTo: collectionView.bounds.size)
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.footerReferenceSize
            } else {
                return .zero
            }
        }
        return viewSize
    }
}
