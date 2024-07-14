//
//  SectionInfoTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class SectionInfoTests: XCTestCase {
    // MARK: - Default Init

    func test_section_info_default_init() {
        // When
        let section = SSCollectionViewModel.SectionInfo()

        // Then
        XCTAssertTrue(section.isEmpty)
        XCTAssertNil(section.identifier)
        XCTAssertNil(section.headerInfo())
        XCTAssertNil(section.footerInfo())
    }

    // MARK: - Cell Access

    func test_section_info_cell_info_access() {
        // Given
        let cellInfos = makeCellInfos(from: makeSampleBanners(63))
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)

        // Then
        XCTAssertEqual(section.count, 63)
        XCTAssertNotNil(section.cellInfo(at: 0))
        XCTAssertNotNil(section.cellInfo(at: 2))
        XCTAssertNil(section.cellInfo(at: 64), "Out of bounds should return nil")
    }

    // MARK: - Append

    func test_section_info_append_cell_info() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(1)))
        let newBanner = TestBanner(id: "1235", title: "NewBanner")

        // When
        section.appendCellInfo(newBanner, cellType: TestBannerCell.self)

        // Then
        XCTAssertEqual(section.count, 2)
    }

    // MARK: - Insert

    func test_section_info_insert_cell_info() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)))
        let inserted = TestBanner(id: "1233", title: "MiddleBanner")

        // When
        section.insertCellInfo(inserted, cellType: TestBannerCell.self, at: 1)

        // Then
        XCTAssertEqual(section.count, 3)
    }

    func test_section_info_insert_cell_info_out_of_range() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let banner = TestBanner(id: "1243", title: "InvalidBanner")

        // When
        section.insertCellInfo(banner, cellType: TestBannerCell.self, at: 19)

        // Then
        XCTAssertEqual(section.count, 11, "Out of range insert should be a no-op")
    }

    // MARK: - Update

    func test_section_info_update_cell_info() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(30)))
        let updated = TestBanner(id: "1130", title: "UpdatedBanner")

        // When
        section.updateCellInfo(updated, cellType: TestBannerCell.self, at: 0)

        // Then
        XCTAssertEqual(section.count, 30, "Count should remain the same")
    }

    func test_section_info_update_cell_info_out_of_bounds() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let banner = TestBanner(id: "1231", title: "InvalidBanner")

        // When
        section.updateCellInfo(banner, cellType: TestBannerCell.self, at: 19)

        // Then
        XCTAssertEqual(section.count, 11, "Out of bounds update should be a no-op")
    }

    // MARK: - Upsert

    func test_section_info_upsert_updates_existing() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let upserted = TestBanner(id: "1331", title: "UpsertTest1")

        // When
        section.upsertCellInfo(upserted, cellType: TestBannerCell.self, at: 0)

        // Then
        XCTAssertEqual(section.count, 11, "Should update in place")
    }

    func test_section_info_upsert_appends_at_end() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(58)))
        let upserted = TestBanner(id: "1442", title: "UpsertTest2")

        // When
        section.upsertCellInfo(upserted, cellType: TestBannerCell.self, at: 58)

        // Then
        XCTAssertEqual(section.count, 59, "Should append at endIndex")
    }

    func test_section_info_upsert_out_of_range() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(63)))
        let banner = TestBanner(id: "1660", title: "InvalidBanner")

        // When
        section.upsertCellInfo(banner, cellType: TestBannerCell.self, at: 64)

        // Then
        XCTAssertEqual(section.count, 63, "Out of range upsert should be a no-op")
    }

    // MARK: - Header / Footer

    func test_section_info_set_header() {
        // Given
        var section = SSCollectionViewModel.SectionInfo()
        XCTAssertNil(section.headerInfo())

        // When
        section.setHeaderInfo(TestHeaderData(title: "Header"), viewType: TestHeaderView.self)

        // Then
        XCTAssertNotNil(section.headerInfo())
    }

    func test_section_info_set_footer() {
        // Given
        var section = SSCollectionViewModel.SectionInfo()
        XCTAssertNil(section.footerInfo())

        // When
        section.setFooterInfo(TestFooterData(text: "Footer"), viewType: TestFooterView.self)

        // Then
        XCTAssertNotNil(section.footerInfo())
    }

    // MARK: - Operators

    func test_section_info_plus_operator() {
        // Given
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(30)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(44)))

        // When
        let combined = section1 + section2

        // Then
        XCTAssertEqual(combined.count, 74)
    }

    func test_section_info_plus_equal_operator() {
        // Given
        var section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(8)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))

        // When
        section1 += section2

        // Then
        XCTAssertEqual(section1.count, 19)
    }

    func test_section_info_plus_cell_info_operator() {
        // Given
        let section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(8)))
        let cellInfo = makeCellInfo(from: TestBanner(id: "1130", title: "MyItem"))

        // When
        let result = section + cellInfo

        // Then
        XCTAssertEqual(result.count, 9)
    }

    func test_section_info_plus_cell_info_array_operator() {
        // Given
        let section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        let newCells = makeCellInfos(from: makeSampleBanners(10))

        // When
        let result = section + newCells

        // Then
        XCTAssertEqual(result.count, 13)
    }

    // MARK: - FlowLayout Options

    func test_section_info_flow_layout_options() {
        // Given
        var section = SSCollectionViewModel.SectionInfo()
        XCTAssertNil(section.sectionInset)
        XCTAssertNil(section.minimumLineSpacing)
        XCTAssertNil(section.minimumInteritemSpacing)

        // When
        section.sectionInset = UIEdgeInsets(top: 11, left: 13, bottom: 17, right: 19)
        section.minimumLineSpacing = 23
        section.minimumInteritemSpacing = 29

        // Then
        XCTAssertEqual(section.sectionInset, UIEdgeInsets(top: 11, left: 13, bottom: 17, right: 19))
        XCTAssertEqual(section.minimumLineSpacing, 23)
        XCTAssertEqual(section.minimumInteritemSpacing, 29)
    }

    // MARK: - Hashable

    func test_section_info_hashable_uses_uuid() {
        // Given — two SectionInfos with same data but different UUIDs
        let items = makeCellInfos(from: makeSampleBanners(3))
        let section1 = SSCollectionViewModel.SectionInfo(items: items, identifier: "SameSection")
        let section2 = SSCollectionViewModel.SectionInfo(items: items, identifier: "SameSection")

        // Then
        XCTAssertNotEqual(section1, section2, "Different SectionInfo instances should have different UUIDs")
        XCTAssertEqual(section1, section1, "Same instance should be equal")
    }
}
