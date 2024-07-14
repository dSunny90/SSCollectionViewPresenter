//
//  PaginationAndPagingTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class PaginationAndPagingTests: XCTestCase {
    // MARK: - Pagination (onNextRequest / hasNext)

    func test_on_next_request_is_stored() {
        // Given
        let cv = makeCollectionView()
        var callbackInvoked = false

        // When
        cv.ss.onNextRequest { _ in
            callbackInvoked = true
        }

        let vm = SSCollectionViewModel(sections: [], hasNext: true)
        cv.ss.setViewModel(with: vm)
        cv.presenter?.nextRequestBlock?(vm)

        // Then
        XCTAssertTrue(callbackInvoked)
    }

    func test_view_model_has_next_flag() {
        // Given
        let cv = makeCollectionView()

        // When
        cv.ss.buildViewModel(page: 0, hasNext: true) { builder in
            builder.section {
                builder.cells(makeSampleBanners(11), cellType: TestBannerCell.self)
            }
        }

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertTrue(vm?.hasNext ?? false)
        XCTAssertEqual(vm?.page, 0)
    }

    func test_should_load_next_page_returns_false_when_has_next_is_false() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel(page: 0, hasNext: false) { builder in
            builder.section { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertFalse(cv.presenter?.shouldLoadNextPage() ?? true)
    }

    // MARK: - Paging Configuration

    func test_paging_configuration_defaults() {
        // When
        let config = SSCollectionViewPresenter.PagingConfiguration()

        // Then
        XCTAssertTrue(config.isEnabled)
        XCTAssertFalse(config.isAlignCenter)
        XCTAssertFalse(config.isLooping)
        XCTAssertFalse(config.isInfinitePage)
        XCTAssertFalse(config.isAutoRolling)
        XCTAssertEqual(config.autoRollingTimeInterval, 3.0)
    }

    func test_paging_configuration_custom_values() {
        // When
        let config = SSCollectionViewPresenter.PagingConfiguration(
            isEnabled: true,
            isAlignCenter: true,
            isLooping: true,
            isInfinitePage: true,
            isAutoRolling: true,
            autoRollingTimeInterval: 5.0
        )

        // Then
        XCTAssertTrue(config.isEnabled)
        XCTAssertTrue(config.isAlignCenter)
        XCTAssertTrue(config.isLooping)
        XCTAssertTrue(config.isInfinitePage)
        XCTAssertTrue(config.isAutoRolling)
        XCTAssertEqual(config.autoRollingTimeInterval, 5.0)
    }

    func test_set_paging_enabled_configures_presenter() {
        // Given
        let cv = makeCollectionView()

        // When
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(
            isAlignCenter: true,
            isLooping: true,
            isInfinitePage: true,
            isAutoRolling: true,
            autoRollingTimeInterval: 2.5
        ))

        // Then
        let presenter = cv.presenter
        XCTAssertTrue(presenter?.isCustomPagingEnabled ?? false)
        XCTAssertTrue(presenter?.isAlignCenter ?? false)
        XCTAssertTrue(presenter?.isLooping ?? false)
        XCTAssertTrue(presenter?.isInfinitePage ?? false)
        XCTAssertTrue(presenter?.isAutoRolling ?? false)
        XCTAssertEqual(presenter?.pagingTimeInterval, 2.5)
    }

    func test_disabling_paging_resets_dependent_flags() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(
            isAlignCenter: true,
            isInfinitePage: true,
            isAutoRolling: true
        ))

        // When
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isEnabled: false))

        // Then
        let presenter = cv.presenter
        XCTAssertFalse(presenter?.isCustomPagingEnabled ?? true)
        XCTAssertFalse(presenter?.isAlignCenter ?? true)
        XCTAssertFalse(presenter?.isInfinitePage ?? true)
        XCTAssertFalse(presenter?.isAutoRolling ?? true)
    }

    func test_paging_configuration_computed_aliases_match_struct() {
        // Given
        let cv = makeCollectionView()
        let config = SSCollectionViewPresenter.PagingConfiguration(
            isAlignCenter: true,
            isAutoRolling: true,
            autoRollingTimeInterval: 4.0
        )

        // When
        cv.ss.setPagingEnabled(config)

        // Then
        let presenter = cv.presenter!
        XCTAssertEqual(presenter.pagingConfig.isEnabled, presenter.isCustomPagingEnabled)
        XCTAssertEqual(presenter.pagingConfig.isAlignCenter, presenter.isAlignCenter)
        XCTAssertEqual(presenter.pagingConfig.isLooping, presenter.isLooping)
        XCTAssertEqual(presenter.pagingConfig.isInfinitePage, presenter.isInfinitePage)
        XCTAssertEqual(presenter.pagingConfig.isAutoRolling, presenter.isAutoRolling)
        XCTAssertEqual(presenter.pagingConfig.autoRollingTimeInterval, presenter.pagingTimeInterval)
    }

    // MARK: - Page Lifecycle Callbacks

    func test_page_callbacks_are_stored() {
        // Given
        let cv = makeCollectionView()

        var willAppearIndex: Int?
        var didAppearIndex: Int?
        var willDisappearIndex: Int?
        var didDisappearIndex: Int?

        // When
        cv.ss.onPageWillAppear { _, index in willAppearIndex = index }
        cv.ss.onPageDidAppear { _, index in didAppearIndex = index }
        cv.ss.onPageWillDisappear { _, index in willDisappearIndex = index }
        cv.ss.onPageDidDisappear { _, index in didDisappearIndex = index }

        cv.presenter?.pageWillAppearBlock?(cv, 0)
        cv.presenter?.pageDidAppearBlock?(cv, 1)
        cv.presenter?.pageWillDisappearBlock?(cv, 2)
        cv.presenter?.pageDidDisappearBlock?(cv, 3)

        // Then
        XCTAssertEqual(willAppearIndex, 0)
        XCTAssertEqual(didAppearIndex, 1)
        XCTAssertEqual(willDisappearIndex, 2)
        XCTAssertEqual(didDisappearIndex, 3)
    }

    // MARK: - Infinite Scroll

    func test_infinite_scroll_triplicates_item_count() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(11)
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isInfinitePage: true))
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()

        // When
        let itemCount = cv.dataSource?.collectionView(cv, numberOfItemsInSection: 0)

        // Then
        XCTAssertEqual(itemCount, 11 * 3, "Infinite scroll should triplicate items")
    }

    func test_infinite_scroll_single_item_not_triplicated() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(1)
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isInfinitePage: true))
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()

        // When
        let itemCount = cv.dataSource?.collectionView(cv, numberOfItemsInSection: 0)

        // Then
        XCTAssertEqual(itemCount, 1, "Single item should not be triplicated")
    }

    // MARK: - Programmatic Paging

    func test_move_to_next_page_sets_programmatic_scroll_flag() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()
        cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isAlignCenter: true))

        // When
        cv.ss.moveToNextPage(animated: false)

        // Then
        XCTAssertTrue(cv.presenter?.isProgrammaticScrollAnimating ?? false)
    }

    func test_move_to_previous_page_sets_programmatic_scroll_flag() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()
        cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isAlignCenter: true))

        // When
        cv.ss.moveToPreviousPage(animated: false)

        // Then
        XCTAssertTrue(cv.presenter?.isProgrammaticScrollAnimating ?? false)
    }

    func test_pending_page_offset_queued_during_animation() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isAlignCenter: true))
        cv.presenter?.isProgrammaticScrollAnimating = true

        // When — two additional next requests during animation
        cv.presenter?.moveToNextPage(animated: true)
        cv.presenter?.moveToNextPage(animated: true)

        // Then
        XCTAssertEqual(cv.presenter?.pendingPageOffset, 2)
    }
}
