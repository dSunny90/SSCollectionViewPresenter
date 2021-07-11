//
//  SSCollectionViewPresenter+Prefetching.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.07.2021.
//

import UIKit

// MARK: - UICollectionViewDataSourcePrefetching

@available(iOS 10.0, *)
extension SSCollectionViewPresenter: UICollectionViewDataSourcePrefetching {
    public func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        guard let viewModel = viewModel else { return }

        let items: [CellInfo] = indexPaths.compactMap {
            guard $0.section < viewModel.count,
                  $0.item < viewModel[$0.section].count else { return nil }
            return viewModel[$0.section][$0.item]
        }
        prefetchBlock?(items)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        guard let viewModel = viewModel else { return }

        let items: [CellInfo] = indexPaths.compactMap {
            guard $0.section < viewModel.count,
                  $0.item < viewModel[$0.section].count else { return nil }
            return viewModel[$0.section][$0.item]
        }
        cancelPrefetchBlock?(items)
    }
}
