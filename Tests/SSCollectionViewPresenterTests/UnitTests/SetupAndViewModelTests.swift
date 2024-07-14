//
//  SetupAndViewModelTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class SetupAndViewModelTests: XCTestCase {
    // MARK: - Presenter Setup

    func test_setup_presenter_creates_presenter() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertNotNil(cv.presenter, "Presenter should be attached after setupPresenter()")
    }

    func test_setup_presenter_with_flow_layout() {
        // Given
        let cv = makeCollectionView(layoutKind: .flow)

        // Then
        XCTAssertNotNil(cv.presenter)
        XCTAssertTrue(cv.collectionViewLayout is UICollectionViewFlowLayout)
    }

    func test_setup_presenter_sets_delegate() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertTrue(cv.delegate === cv.presenter)
    }

    func test_setup_presenter_sets_data_source() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertTrue(cv.dataSource === cv.presenter)
    }

    // MARK: - Get / Set ViewModel

    func test_get_view_model_returns_nil_before_setting() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertNil(cv.ss.getViewModel(), "ViewModel should be nil before setting")
    }

    func test_set_view_model_and_get_view_model() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        let cellInfos = makeCellInfos(from: banners)
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        let viewModel = SSCollectionViewModel(sections: [section])

        // When
        cv.ss.setViewModel(with: viewModel)

        // Then
        let retrieved = cv.ss.getViewModel()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.count, 1, "Should have 1 section")
        XCTAssertEqual(retrieved?[0].count, 8, "Section should have 8 items (default)")
    }

    func test_reset_view_model_clears_all_data() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("products") {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)

        // When
        cv.ss.resetViewModel()

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertNotNil(vm)
        XCTAssertTrue(vm?.isEmpty ?? false)
    }

    func test_set_view_model_replaces_existing() {
        // Given
        let cv = makeCollectionView()
        let first = SSCollectionViewModel(sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        ])
        cv.ss.setViewModel(with: first)
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)

        // When
        let second = SSCollectionViewModel(sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(7)))
        ])
        cv.ss.setViewModel(with: second)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 7)
    }

    // MARK: - ViewModel Basics

    func test_view_model_default_values() {
        // When
        let vm = SSCollectionViewModel()

        // Then
        XCTAssertEqual(vm.page, 0)
        XCTAssertFalse(vm.hasNext)
        XCTAssertTrue(vm.isEmpty)
    }

    func test_view_model_section_info_access() {
        // Given
        let cellInfos = makeCellInfos(from: makeSampleBanners(7))
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos, identifier: "test")
        let vm = SSCollectionViewModel(sections: [section], page: 1, hasNext: true)

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm.page, 1)
        XCTAssertTrue(vm.hasNext)
        XCTAssertNotNil(vm.sectionInfo(at: 0))
        XCTAssertNil(vm.sectionInfo(at: 2), "Out of bounds should return nil")
    }

    // MARK: - ViewModel Operators

    func test_view_model_plus_operator() {
        // Given
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(23)))
        let vm1 = SSCollectionViewModel(sections: [section1])
        let vm2 = SSCollectionViewModel(sections: [section2])

        // When
        let combined = vm1 + vm2

        // Then
        XCTAssertEqual(combined.count, 2)
    }

    func test_view_model_plus_equal_operator() {
        // Given
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(30)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(44)))
        var vm = SSCollectionViewModel(sections: [section1])

        // When
        vm += SSCollectionViewModel(sections: [section2])

        // Then
        XCTAssertEqual(vm.count, 2)
    }

    func test_view_model_plus_section_info() {
        // Given
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(53)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(59)))
        let vm = SSCollectionViewModel(sections: [section1])

        // When
        let result = vm + section2

        // Then
        XCTAssertEqual(result.count, 2)
    }

    func test_view_model_plus_section_info_array_operator() {
        // Given
        let vm = SSCollectionViewModel(sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        ])
        let newSections = [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(19))),
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(23)))
        ]

        // When
        let result = vm + newSections

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].count, 11)
        XCTAssertEqual(result[1].count, 19)
        XCTAssertEqual(result[2].count, 23)
    }

    // MARK: - Selected Items

    func test_selected_items_initially_empty() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertTrue(cv.ss.selectedItems.isEmpty)
    }

    // MARK: - Clear Selected Items

    func test_clear_selected_items_with_no_view_model_is_no_op() {
        // Given
        let cv = makeCollectionView()

        // When — should not crash
        cv.ss.clearSelectedItems()

        // Then
        XCTAssertTrue(cv.ss.selectedItems.isEmpty)
    }

    // MARK: - Scroll Delegate Proxy

    func test_set_scroll_view_delegate_proxy() {
        // Given
        let cv = makeCollectionView()
        let proxy = MockScrollViewDelegate()

        // When
        cv.ss.setScrollViewDelegateProxy(proxy)

        // Then
        XCTAssertTrue(cv.presenter?.scrollViewDelegateProxy === proxy)
    }
}

// MARK: - Mock

private class MockScrollViewDelegate: NSObject, UIScrollViewDelegate {}
