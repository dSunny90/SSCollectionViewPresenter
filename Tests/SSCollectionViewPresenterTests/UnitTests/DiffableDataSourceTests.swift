//
//  DiffableDataSourceTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class DiffableDataSourceTests: XCTestCase {
    // MARK: - Setup with Diffable Mode

    func test_setup_with_diffable_mode_creates_presenter() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)

        // Then
        XCTAssertNotNil(cv.presenter)
    }

    func test_diffable_mode_does_not_set_traditional_data_source() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)

        // Then — diffable data source owns the data source, not the presenter
        XCTAssertFalse(cv.dataSource === cv.presenter,
                       "In diffable mode, presenter should not be the dataSource")
    }

    func test_traditional_mode_sets_presenter_as_data_source() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertTrue(cv.dataSource === cv.presenter)
    }

    // MARK: - Snapshot Application

    func test_apply_snapshot_with_diffable_mode() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }

        // When
        cv.ss.applySnapshot(animated: false)

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertNotNil(vm)
        XCTAssertEqual(vm?.count, 1)
        XCTAssertEqual(vm?[0].count, 5)
    }

    func test_apply_snapshot_animated() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        // When — should not crash
        cv.ss.applySnapshot(animated: true)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
    }

    func test_apply_snapshot_in_traditional_mode_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        // When — should not crash, just no-op
        cv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
    }

    // MARK: - Multiple Sections

    func test_apply_snapshot_with_multiple_sections() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self)
            }
        }

        // When
        cv.ss.applySnapshot(animated: false)

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertEqual(vm?.count, 3)
        XCTAssertEqual(vm?[0].count, 2)
        XCTAssertEqual(vm?[1].count, 4)
        XCTAssertEqual(vm?[2].count, 1)
    }

    // MARK: - Snapshot Update After ViewModel Change

    func test_snapshot_updates_when_viewmodel_changes() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section("Test") {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)

        // When — replace with new viewmodel
        _ = cv.ss.buildViewModel { builder in
            builder.section("Test") {
                builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 7)
    }

    // MARK: - Empty Snapshot

    func test_apply_snapshot_with_empty_viewmodel() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { _ in }

        // When — should not crash
        cv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertTrue(cv.ss.getViewModel()?.isEmpty ?? true)
    }

    // MARK: - Diffable with Headers and Footers

    func test_diffable_snapshot_with_headers_and_footers() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.header(TestHeaderData(title: "TestHeader"), viewType: TestHeaderView.self)
                builder.footer(TestFooterData(text: "TestFooter"), viewType: TestFooterView.self)
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        // When
        cv.ss.applySnapshot(animated: false)

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertNotNil(vm?[0].header)
        XCTAssertNotNil(vm?[0].footer)
    }

    // MARK: - Section Snapshot (iOS 14+)

    @available(iOS 14.0, *)
    func test_apply_section_snapshot_by_identifier() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section("Test") {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // When — apply section snapshot with new items
        let newItems = makeCellInfos(from: makeSampleBanners(5))
        cv.ss.applySectionSnapshot(newItems, toSectionIdentifier: "Test", animated: false)

        // Then — section snapshot applied without crash
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
    }

    @available(iOS 14.0, *)
    func test_apply_section_snapshot_by_index() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // When — apply section snapshot to second section by index
        let newItems = makeCellInfos(from: makeSampleBanners(6))
        cv.ss.applySectionSnapshot(newItems, toSectionAt: 1, animated: false)

        // Then — should not crash
        XCTAssertEqual(cv.ss.getViewModel()?.count, 2)
    }

    @available(iOS 14.0, *)
    func test_apply_section_snapshot_with_nonexistent_identifier_is_no_op() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section("Test1") {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // When — apply to nonexistent section, should be no-op
        let newItems = makeCellInfos(from: makeSampleBanners(5))
        cv.ss.applySectionSnapshot(newItems, toSectionIdentifier: "Test2", animated: false)

        // Then — original data unchanged
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
    }

    // MARK: - Reconfigure Items (iOS 15+)

    @available(iOS 15.0, *)
    func test_reconfigure_items_at_index_paths() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // When — should not crash
        cv.ss.reconfigureItems(at: [IndexPath(item: 0, section: 0), IndexPath(item: 2, section: 0)])

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 5)
    }

    @available(iOS 15.0, *)
    func test_reconfigure_items_with_out_of_bounds_index_paths() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(18), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // When — out of bounds index paths should be safely skipped
        cv.ss.reconfigureItems(at: [IndexPath(item: 19, section: 0)])

        // Then — no crash
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 18)
    }

    @available(iOS 15.0, *)
    func test_reconfigure_visible_items() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)
        cv.layoutIfNeeded()

        // When — should not crash
        cv.ss.reconfigureVisibleItems()

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
    }

    @available(iOS 15.0, *)
    func test_reconfigure_items_in_traditional_mode_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()

        // When — should be no-op, not crash
        cv.ss.reconfigureItems(at: [IndexPath(item: 0, section: 0)])

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
    }

    // MARK: - Apply Snapshot Using Reload Data (iOS 15+)

    @available(iOS 15.0, *)
    func test_apply_snapshot_using_reload_data() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }

        // When
        cv.ss.applySnapshotUsingReloadData()

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 4)
    }

    @available(iOS 15.0, *)
    func test_apply_snapshot_using_reload_data_in_traditional_mode_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        // When — should be no-op, not crash
        cv.ss.applySnapshotUsingReloadData()

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
    }

    // MARK: - Diffable with Pagination

    func test_diffable_with_build_and_extend_viewmodel() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel(page: 0, hasNext: true) { builder in
            builder.section("ProductList") {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 5)

        // When — extend with next page
        _ = cv.ss.extendViewModel(page: 1, hasNext: false) { builder in
            builder.section("ProductList") {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 8)
        XCTAssertFalse(cv.ss.getViewModel()?.hasNext ?? true)
    }

    // MARK: - Reconfigure Items by Identifiers (iOS 15+)

    @available(iOS 15.0, *)
    func test_reconfigure_items_by_identifiers() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section("Test1") {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // When — reconfigure by non-matching identifiers should be safe
        cv.ss.reconfigureItems(identifiers: ["Test2"])

        // Then — no crash
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 5)
    }

    // MARK: - Reset ViewModel in Diffable Mode

    func test_reset_viewmodel_in_diffable_mode() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)

        // When
        cv.ss.resetViewModel()
        cv.ss.applySnapshot(animated: false)

        // Then
        XCTAssertTrue(cv.ss.getViewModel()?.isEmpty ?? false)
    }
}
