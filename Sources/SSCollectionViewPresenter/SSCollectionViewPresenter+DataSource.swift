//
//  SSCollectionViewPresenter+DataSource.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 24.04.2021.
//

import UIKit

// MARK: - UICollectionViewDataSource

extension SSCollectionViewPresenter: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let viewModel = viewModel else { return 0 }

        guard !(isCustomPagingEnabled && viewModel.sections.count > 1)
        else {
            assertionFailure("⚠️ [SSCollectionViewPresenter] pagingConfig.isEnabled ignored: requires single section (count=\(viewModel.sections.count)).")
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
                self.cancelAutoRolling()
                self.perform(#selector(self.runAutoRolling), with: nil, afterDelay: 3)
            }
        }
        return viewModel.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        guard let sectionInfo = viewModel?[section],
              !sectionInfo.isCollapsed else { return 0 }

        let itemCount: Int
        if isInfinitePage, sectionInfo.items.count > 1 {
            itemCount = sectionInfo.items.count * duplicatedItemCount
        } else {
            itemCount = sectionInfo.items.count
        }
        return itemCount
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = viewModel
        else { return collectionView.dequeueDefaultCell(for: indexPath) }

        defer {
            if shouldLoadNextPage() {
                isLoadingNextPage = true
                nextRequestBlock?(viewModel)
            }
        }

        let items = viewModel[indexPath.section].items
        let item = viewModel[indexPath.section].items[indexPath.item % items.count]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: item.binderType),
            for: indexPath
        )

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
           let aCell = cell as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aCell)
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = viewModel?[indexPath.section]
        else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let item: SSCollectionViewModel.ReusableViewInfo?
        if kind == UICollectionView.elementKindSectionHeader {
            item = section.header
        } else if kind == UICollectionView.elementKindSectionFooter {
            item = section.footer
        } else {
            item = nil
        }

        guard let item = item else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: String(describing: item.binderType),
            for: indexPath
        )

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
           let aView = view as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aView)
        }

        return view
    }
}
