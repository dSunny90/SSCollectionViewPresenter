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

    // MARK: - CellInfo Selection State

    func test_cell_info_initial_selection_state() {
        // Given
        let banner = TestBanner(id: "900", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(BindingStore<TestBanner, TestBannerCell>(state: banner))

        // Then
        XCTAssertFalse(cellInfo.isSelected)
        XCTAssertFalse(cellInfo.isHighlighted)
    }
}
