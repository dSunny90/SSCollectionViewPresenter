//
//  PrefetchTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 23.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class PrefetchTests: XCTestCase {
    // MARK: - Prefetch / Cancel Prefetch

    func test_prefetch_and_cancel_prefetch_callbacks_receive_expected_items() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()

        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }

        var prefetchedIds: [String] = []
        var cancelledIds: [String] = []

        cv.ss.onPrefetch { items in
            prefetchedIds.append(contentsOf: items.compactMap { ($0.state as? TestBanner)?.id })
        }
        cv.ss.onCancelPrefetch { items in
            cancelledIds.append(contentsOf: items.compactMap { ($0.state as? TestBanner)?.id })
        }

        // When — trigger prefetch for first 3 items
        let prefetcher = cv.prefetchDataSource
        prefetcher?.collectionView(cv, prefetchItemsAt: [
            IndexPath(item: 0, section: 0),
            IndexPath(item: 1, section: 0),
            IndexPath(item: 2, section: 0)
        ])
        // And then cancel two of them
        prefetcher?.collectionView?(cv, cancelPrefetchingForItemsAt: [
            IndexPath(item: 1, section: 0),
            IndexPath(item: 2, section: 0)
        ])

        // Then
        XCTAssertEqual(prefetchedIds.count, 3)
        XCTAssertEqual(cancelledIds.count, 2)
    }
}
