//
//  DataSourceTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class DataSourceTests: XCTestCase {
    // MARK: - numberOfSections / numberOfItemsInSection

    func test_number_of_sections_matches_view_model() {
        // Given
        let cv = makeCollectionView()
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(23)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let viewModel = SSCollectionViewModel(sections: [section1, section2])

        // When
        cv.ss.setViewModel(with: viewModel)
        cv.reloadData()

        // Then
        let sectionCount = cv.dataSource?.numberOfSections?(in: cv)
        XCTAssertEqual(sectionCount, 2)
    }

    func test_number_of_items_in_section_matches_cell_count() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(10)
        let cellInfos = makeCellInfos(from: banners)
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let itemCount = cv.dataSource?.collectionView(cv, numberOfItemsInSection: 0)

        // Then
        XCTAssertEqual(itemCount, 10)
    }

    func test_number_of_items_returns_zero_with_no_view_model() {
        // Given
        let cv = makeCollectionView()
        cv.reloadData()

        // When
        let sectionCount = cv.dataSource?.numberOfSections?(in: cv)

        // Then
        XCTAssertEqual(sectionCount, 0)
    }

    func test_number_of_sections_with_multiple_sections() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Water") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("Beer") { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
            builder.section("Juice") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        cv.reloadData()

        // Then
        XCTAssertEqual(cv.dataSource?.numberOfSections?(in: cv), 3)
        XCTAssertEqual(cv.dataSource?.collectionView(cv, numberOfItemsInSection: 0), 1)
        XCTAssertEqual(cv.dataSource?.collectionView(cv, numberOfItemsInSection: 1), 2)
        XCTAssertEqual(cv.dataSource?.collectionView(cv, numberOfItemsInSection: 2), 3)
    }

    // MARK: - CellForItemAt & Data Binding

    func test_cell_for_item_at_dequeues_correct_cell() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        let cellInfos = makeCellInfos(from: banners)
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let indexPath = IndexPath(item: 0, section: 0)
        let cell = cv.dataSource?.collectionView(cv, cellForItemAt: indexPath)

        // Then
        XCTAssertTrue(cell is TestBannerCell, "Should dequeue a TestBannerCell")
    }

    func test_cell_data_binding_applies_to_cell() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        let cellInfos = makeCellInfos(from: banners)
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let indexPath = IndexPath(item: 1, section: 0)
        guard let cell = cv.dataSource?.collectionView(cv, cellForItemAt: indexPath) as? TestBannerCell else {
            XCTFail("Failed to dequeue TestBannerCell")
            return
        }

        // Then
        XCTAssertEqual(cell.titleLabel.text, "Banner 1")
    }

    func test_cell_for_item_at_with_nil_view_model_returns_default_cell() {
        // Given
        let cv = makeCollectionView()
        cv.reloadData()

        // When
        let cell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertNotNil(cell)
        XCTAssertFalse(cell is TestBannerCell, "Should return a default UICollectionViewCell, not TestBannerCell")
    }

    func test_cell_for_item_at_with_infinite_scroll_modulo_indexing() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isInfinitePage: true))
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()

        // When — item 12 should map to item 2 (12 % 5 = 2)
        let cell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 12, section: 0))

        // Then
        XCTAssertTrue(cell is TestBannerCell)
        if let bannerCell = cell as? TestBannerCell {
            XCTAssertEqual(bannerCell.titleLabel.text, "Banner 2")
        }
    }

    // MARK: - Supplementary Views

    func test_supplementary_view_header_dequeues_correctly() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setHeaderInfo(TestHeaderData(title: "TestHeader"), viewType: TestHeaderView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()
        cv.layoutIfNeeded()

        // When
        let headerView = cv.dataSource?.collectionView?(
            cv,
            viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 0)
        )

        // Then
        XCTAssertNotNil(headerView)
        XCTAssertTrue(headerView is TestHeaderView)
    }

    func test_supplementary_view_footer_dequeues_correctly() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setFooterInfo(TestFooterData(text: "TestFooter"), viewType: TestFooterView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()
        cv.layoutIfNeeded()

        // When
        let footerView = cv.dataSource?.collectionView?(
            cv,
            viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter,
            at: IndexPath(item: 0, section: 0)
        )

        // Then
        XCTAssertNotNil(footerView)
        XCTAssertTrue(footerView is TestFooterView)
    }
}
