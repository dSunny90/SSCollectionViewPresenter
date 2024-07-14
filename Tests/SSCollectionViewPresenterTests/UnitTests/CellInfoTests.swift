//
//  CellInfoTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class CellInfoTests: XCTestCase {
    // MARK: - CellInfo Stores Data

    func test_cell_info_stores_content_data() {
        // Given
        let banner = TestBanner(id: "523", title: "Hello, World!")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // Then
        XCTAssertTrue(cellInfo.binderType == TestBannerCell.self)
    }

    func test_cell_info_item_size() {
        // Given
        let banner = TestBanner(id: "644", title: "Hello, SSCollectionViewPresenter!")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // When
        let size = cellInfo.size(constrainedTo: CGSize(width: 375, height: 200))

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 100))
    }

    func test_cell_info_hashable() {
        // Given
        let banner = TestBanner(id: "777", title: "Hello, Swift!")
        let cellInfo1 = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cellInfo2 = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // Then
        XCTAssertNotEqual(cellInfo1, cellInfo2, "Each CellInfo should have a unique UUID")
        XCTAssertEqual(cellInfo1, cellInfo1, "Same instance should be equal")
    }

    // MARK: - CellInfo Apply / Interaction

    func test_cell_info_apply_binds_data_to_correct_binder() {
        // Given
        let banner = TestBanner(id: "211", title: "ApplyTestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.apply(to: cell)

        // Then
        XCTAssertEqual(cell.titleLabel.text, "ApplyTestItem")
    }

    func test_cell_info_should_highlight_returns_true() {
        // Given
        let banner = TestBanner(id: "444", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()

        // When
        let shouldHighlight = cellInfo.shouldHighlight(to: cell)

        // Then
        XCTAssertTrue(shouldHighlight)
    }

    func test_cell_info_should_select_returns_true() {
        // Given
        let banner = TestBanner(id: "500", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()

        // When
        let shouldSelect = cellInfo.shouldSelect(to: cell)

        // Then
        XCTAssertTrue(shouldSelect)
    }

    func test_cell_info_should_deselect_returns_true() {
        // Given
        let banner = TestBanner(id: "664", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()

        // When
        let shouldDeselect = cellInfo.shouldDeselect(to: cell)

        // Then
        XCTAssertTrue(shouldDeselect)
    }

    func test_cell_info_did_select_calls_cell_method() {
        // Given
        let banner = TestBanner(id: "423", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.didSelect(to: cell)

        // Then
        XCTAssertTrue(cell.didSelectCalled)
        XCTAssertTrue(cellInfo.isSelected)
    }

    func test_cell_info_did_deselect_calls_cell_method() {
        // Given
        let banner = TestBanner(id: "909", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()
        cellInfo.didSelect(to: cell)

        // When
        cellInfo.didDeselect(to: cell)

        // Then
        XCTAssertTrue(cell.didDeselectCalled)
        XCTAssertFalse(cellInfo.isSelected)
    }

    func test_cell_info_did_highlight_calls_cell_method() {
        // Given
        let banner = TestBanner(id: "159", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.didHighlight(to: cell)

        // Then
        XCTAssertTrue(cell.didHighlightCalled)
        XCTAssertTrue(cellInfo.isHighlighted)
    }

    func test_cell_info_did_unhighlight_calls_cell_method() {
        // Given
        let banner = TestBanner(id: "951", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()
        cellInfo.didHighlight(to: cell)

        // When
        cellInfo.didUnhighlight(to: cell)

        // Then
        XCTAssertTrue(cell.didUnhighlightCalled)
        XCTAssertFalse(cellInfo.isHighlighted)
    }

    func test_cell_info_will_display_calls_cell_method() {
        // Given
        let banner = TestBanner(id: "523", title: "Item")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.willDisplay(to: cell)

        // Then
        XCTAssertTrue(cell.willDisplayCalled)
    }

    func test_cell_info_did_end_displaying_calls_cell_method() {
        // Given
        let banner = TestBanner(id: "699", title: "Hello, Swift!")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.didEndDisplaying(to: cell)

        // Then
        XCTAssertTrue(cell.didEndDisplayingCalled)
    }

    // MARK: - CellInfo Action Closure

    func test_cell_info_action_closure_initially_nil() {
        // Given
        let banner = TestBanner(id: "777", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // Then
        XCTAssertNil(cellInfo.actionClosure)
    }

    func test_cell_info_action_closure_can_be_set() {
        // Given
        let banner = TestBanner(id: "815", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))
        var actionCalled = false

        // When
        cellInfo.actionClosure = { _, _, _, _ in
            actionCalled = true
        }
        let cell = TestBannerCell()
        let indexPath = IndexPath(item: 0, section: 0)
        cellInfo.actionClosure?(indexPath, cell, "testAction", nil)

        // Then
        XCTAssertNotNil(cellInfo.actionClosure)
        XCTAssertTrue(actionCalled)
    }

    // MARK: - CellInfo Selection State

    func test_cell_info_initial_selection_state() {
        // Given
        let banner = TestBanner(id: "909", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // Then
        XCTAssertFalse(cellInfo.isSelected)
        XCTAssertFalse(cellInfo.isHighlighted)
    }

    // MARK: - CellInfo Index Title

    func test_cell_info_index_title_initial_value() {
        // Given
        let banner = TestBanner(id: "119", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // Then
        XCTAssertNil(cellInfo.indexTitle, "indexTitle should be nil by default")
    }

    func test_cell_info_index_title_can_be_set() {
        // Given
        let banner = TestBanner(id: "225", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // When
        cellInfo.indexTitle = "A"

        // Then
        XCTAssertEqual(cellInfo.indexTitle, "A")
    }

    func test_cell_info_index_title_empty_string() {
        // Given
        let banner = TestBanner(id: "337", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // When
        cellInfo.indexTitle = ""

        // Then
        XCTAssertEqual(cellInfo.indexTitle, "")
    }

    // MARK: - UICollectionViewCell.indexPath

    func test_cell_index_path_returns_nil_when_not_in_collection_view() {
        // Given
        let cell = TestBannerCell()

        // Then
        XCTAssertNil(cell.indexPath, "indexPath should be nil when cell is not in a collection view")
    }

    func test_cell_index_path_returns_correct_index_path_when_visible() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(10)
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let expectedIndexPath = IndexPath(item: 3, section: 0)

        // When
        guard let cell = cv.cellForItem(at: expectedIndexPath) as? TestBannerCell else {
            XCTFail("Could not get cell at index path")
            return
        }
        let cellIndexPath = cell.indexPath

        // Then
        XCTAssertEqual(cellIndexPath, expectedIndexPath)
    }

    func test_cell_index_path_works_with_multiple_sections() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let expectedIndexPath = IndexPath(item: 2, section: 1) // visible without scrolling

        // When
        guard let cell = cv.cellForItem(at: expectedIndexPath) as? TestBannerCell else {
            XCTFail("Could not get cell at index path")
            return
        }
        let cellIndexPath = cell.indexPath

        // Then
        XCTAssertEqual(cellIndexPath, expectedIndexPath)
    }
}
