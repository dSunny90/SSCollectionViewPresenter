//
//  PageBasedLoadingTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class PageBasedLoadingTests: XCTestCase {
    // MARK: - ViewModel Page Management

    func test_set_page_stores_and_merges_sections() {
        // Given
        var vm = SSCollectionViewModel()
        let section = SSCollectionViewModel.SectionInfo(
            items: makeCellInfos(from: makeSampleBanners(3)),
            identifier: "products"
        )

        // When
        vm.setPage(0, sections: [section])

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm[0].count, 3)
        XCTAssertEqual(vm[0].identifier, "products")
        XCTAssertTrue(vm.hasPageData)
        XCTAssertEqual(vm.pageCount, 1)
    }

    func test_multiple_pages_with_same_identifier_merge_items() {
        // Given
        var vm = SSCollectionViewModel()

        // When
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products")
        ])
        vm.setPage(1, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(5)), identifier: "products")
        ])

        // Then
        XCTAssertEqual(vm.count, 1, "Should merge into one section")
        XCTAssertEqual(vm[0].count, 8, "Should have 3 + 5 = 8 items")
    }

    func test_pages_with_different_identifiers_append_sections() {
        // Given
        var vm = SSCollectionViewModel()

        // When
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)), identifier: "banner"),
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(4)), identifier: "products")
        ])
        vm.setPage(1, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products")
        ])

        // Then
        XCTAssertEqual(vm.count, 2, "Should have 2 distinct sections")
        XCTAssertEqual(vm[0].identifier, "banner")
        XCTAssertEqual(vm[0].count, 2)
        XCTAssertEqual(vm[1].identifier, "products")
        XCTAssertEqual(vm[1].count, 7, "4 from page 0 + 3 from page 1")
    }

    func test_nil_identifier_sections_never_merge() {
        // Given
        var vm = SSCollectionViewModel()

        // When
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)))
        ])
        vm.setPage(1, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        ])

        // Then
        XCTAssertEqual(vm.count, 2, "Nil-identifier sections should not merge")
        XCTAssertEqual(vm[0].count, 2)
        XCTAssertEqual(vm[1].count, 3)
    }

    func test_remove_page_rebuilds() {
        // Given
        var vm = SSCollectionViewModel()
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products")
        ])
        vm.setPage(1, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(5)), identifier: "products")
        ])
        XCTAssertEqual(vm[0].count, 8)

        // When
        vm.removePage(1)

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm[0].count, 3, "Only page 0 items should remain")
        XCTAssertEqual(vm.pageCount, 1)
    }

    func test_remove_all_pages_clears_everything() {
        // Given
        var vm = SSCollectionViewModel()
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products")
        ])
        vm.setPage(1, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(5)), identifier: "products")
        ])

        // When
        vm.removeAllPages()

        // Then
        XCTAssertTrue(vm.isEmpty)
        XCTAssertFalse(vm.hasPageData)
        XCTAssertEqual(vm.pageCount, 0)
        XCTAssertEqual(vm.page, 0)
        XCTAssertFalse(vm.hasNext)
    }

    func test_page_replacement_rebuilds_correctly() {
        // Given
        var vm = SSCollectionViewModel()
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products")
        ])
        XCTAssertEqual(vm[0].count, 3)

        // When — replace page 0 with different data
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(7)), identifier: "products")
        ])

        // Then
        XCTAssertEqual(vm[0].count, 7, "Replaced page should use new items")
        XCTAssertEqual(vm.pageCount, 1)
    }

    func test_empty_page_does_not_affect_merge() {
        // Given
        var vm = SSCollectionViewModel()
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(5)), identifier: "products")
        ])

        // When
        vm.setPage(1, sections: [])

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm[0].count, 5)
    }

    func test_sections_for_page_returns_correct_data() {
        // Given
        var vm = SSCollectionViewModel()
        let sections0 = [SSCollectionViewModel.SectionInfo(
            items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products"
        )]
        vm.setPage(0, sections: sections0)

        // Then
        XCTAssertNotNil(vm.sections(forPage: 0))
        XCTAssertEqual(vm.sections(forPage: 0)?.count, 1)
        XCTAssertNil(vm.sections(forPage: 4))
    }

    func test_out_of_order_page_loading_merges_in_sorted_order() {
        // Given
        var vm = SSCollectionViewModel()

        // When — load page 2 before page 1
        vm.setPage(2, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)), identifier: "products")
        ])
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "banner"),
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(4)), identifier: "products")
        ])
        vm.setPage(1, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(5)), identifier: "products")
        ])

        // Then — merged order should be page 0, 1, 2
        XCTAssertEqual(vm.count, 2)
        XCTAssertEqual(vm[0].identifier, "banner")
        XCTAssertEqual(vm[0].count, 3)
        XCTAssertEqual(vm[1].identifier, "products")
        XCTAssertEqual(vm[1].count, 11, "4 + 5 + 2 items from pages 0, 1, 2")
    }

    func test_header_footer_override_from_later_page() {
        // Given
        var vm = SSCollectionViewModel()
        let header0 = SSCollectionViewModel.ReusableViewInfo(
            BindingStore<TestHeaderData, TestHeaderView>(state: TestHeaderData(title: "Page0Header"))
        )
        let header1 = SSCollectionViewModel.ReusableViewInfo(
            BindingStore<TestHeaderData, TestHeaderView>(state: TestHeaderData(title: "Page1Header"))
        )

        // When
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)), header: header0, identifier: "products")
        ])
        vm.setPage(1, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), header: header1, identifier: "products")
        ])

        // Then
        XCTAssertNotNil(vm[0].headerInfo(), "Header should exist")
        XCTAssertEqual(vm[0].count, 5)
    }

    func test_set_page_updates_page_property() {
        // Given
        var vm = SSCollectionViewModel()

        // When
        vm.setPage(0, sections: [])
        XCTAssertEqual(vm.page, 0)

        vm.setPage(3, sections: [])
        XCTAssertEqual(vm.page, 3)
    }

    func test_find_page_for_section_identifier() {
        // Given
        var vm = SSCollectionViewModel()
        vm.setPage(0, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)), identifier: "banner"),
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products")
        ])
        vm.setPage(1, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products")
        ])
        vm.setPage(2, sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "products")
        ])

        // Then
        XCTAssertEqual(vm.findPage(forSectionIdentifier: "banner"), 0)
        XCTAssertEqual(vm.findPage(forSectionIdentifier: "products"), 2)
        XCTAssertNil(vm.findPage(forSectionIdentifier: "nonexistent"))
    }

    // MARK: - Presenter Page-Based API

    func test_load_page_via_presenter() {
        // Given
        let cv = makeCollectionView()

        // When
        let result = cv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("products") {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 5)
        XCTAssertTrue(result.hasNext)
        XCTAssertTrue(result.hasPageData)
    }

    func test_load_multiple_pages_via_presenter() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("banner") { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
            builder.section("products") { builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self) }
        }

        // When
        let result = cv.ss.loadPage(1, hasNext: false) { builder in
            builder.section("products") { builder.cells(makeSampleBanners(6), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].count, 2, "Banner section unchanged")
        XCTAssertEqual(result[1].count, 10, "Products: 4 + 6")
        XCTAssertFalse(result.hasNext)
    }

    func test_reset_pages_via_presenter() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("products") { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.setViewModel(with: SSCollectionViewModel())

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertNotNil(vm)
        XCTAssertTrue(vm?.isEmpty ?? false)
        XCTAssertFalse(vm?.hasPageData ?? true)
    }

    func test_remove_page_via_presenter() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("products") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        _ = cv.ss.loadPage(1, hasNext: false) { builder in
            builder.section("products") { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }

        // When
        let result = cv.ss.removePage(1)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?[0].count, 3, "Only page 0 items remain")
    }

    func test_load_page_after_reset_starts_fresh() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("products") { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }
        _ = cv.ss.loadPage(1, hasNext: false) { builder in
            builder.section("products") { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }

        // When — simulate pull-to-refresh
        cv.ss.setViewModel(with: SSCollectionViewModel())
        let result = cv.ss.loadPage(0, hasNext: true) { builder in
            builder.section("products") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 3, "Should only have new page 0 data")
        XCTAssertEqual(result.pageCount, 1)
        XCTAssertTrue(result.hasNext)
    }
}
