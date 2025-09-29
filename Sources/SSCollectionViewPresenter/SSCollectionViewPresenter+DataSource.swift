//
//  SSCollectionViewPresenter+DataSource.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

// MARK: - UICollectionViewDataSource

extension SSCollectionViewPresenter: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let viewModel else { return 0 }

        guard !(isCustomPagingEnabled && viewModel.sections.count > 1)
        else {
            assertionFailure("⚠️ [SSCollectionViewPresenter] setPagingEnabled ignored: requires single section (count=\(viewModel.sections.count)).")
            self.isCustomPagingEnabled = false
            return viewModel.sections.count
        }

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
            if self.isAlignCenter {
                collectionView.setInitialOffsetIfNeeded(animated: false)
            }
            if self.isInfinitePage {
                collectionView.remapContentOffsetIfNeeded()
            }
            if self.isAutoRolling {
                self.perform(#selector(self.runAutoRolling), with: nil, afterDelay: 3)
            }
        }
        return viewModel.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        guard let items = viewModel?[safe: section]?.items else { return 0 }

        let itemCount: Int
        if isInfinitePage, items.count > 1 {
            itemCount = items.count * duplicatedItemCount
        } else {
            itemCount = items.count
        }
        return itemCount
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel,
              let items = viewModel[safe: indexPath.section]?.items
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
        item.apply(to: cell)
        if let actionHandler,
           let aCell = cell as? (UIView & EventForwardingProvider)
        {
            actionHandler.attach(to: aCell)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = viewModel?[safe: indexPath.section]
        else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let item: ReusableViewInfo?
        if kind == UICollectionView.elementKindSectionHeader {
            item = section.header
        } else if kind == UICollectionView.elementKindSectionFooter {
            item = section.footer
        } else {
            item = nil
        }

        guard let item else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let identifier = String(describing: item.binderType)
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: identifier,
            for: indexPath
        )
        item.apply(to: view)
        if let actionHandler,
           let aView = view as? (UIView & EventForwardingProvider)
        {
            actionHandler.attach(to: aView)
        }
        return view
    }
}
