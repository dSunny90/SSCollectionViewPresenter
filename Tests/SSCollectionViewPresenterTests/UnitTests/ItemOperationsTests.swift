//
//  ItemOperationsTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 16.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class ItemOperationsTests: XCTestCase {
    // MARK: - Append Item

    func test_append_item_to_section() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(59), cellType: TestBannerCell.self) }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "815", title: "Korea"))

        // When
        cv.ss.appendItem(newItem, toSection: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 60)
    }

    func test_append_item_to_invalid_section() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(63), cellType: TestBannerCell.self) }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "301", title: "Manse"))

        // When
        cv.ss.appendItem(newItem, toSection: 119)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 63, "Should be unchanged")
    }

    func test_append_items_to_section() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
        }
        let newItems = makeCellInfos(from: makeSampleBanners(19))

        // When
        cv.ss.appendItems(contentsOf: newItems, toSection: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 20)
    }

    func test_append_item_by_section_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Apple") { builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self) }
            builder.section("Banana") { builder.cells(makeSampleBanners(9), cellType: TestBannerCell.self) }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "1713", title: "Google"))

        // When
        cv.ss.appendItem(newItem, sectionIdentifier: "Apple")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 8, "Apple section should grow")
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 9, "Banana section unchanged")
    }

    func test_append_items_by_section_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("ProductList") { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
        }
        let items = makeCellInfos(from: makeSampleBanners(5))

        // When
        cv.ss.appendItems(contentsOf: items, sectionIdentifier: "ProductList")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 7)
    }

    func test_append_item_by_section_identifier_not_found_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Game") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        let item = makeCellInfo(from: TestBanner(id: "book0001", title: "One Piece"))

        // When
        cv.ss.appendItem(item, sectionIdentifier: "Book")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
    }

    func test_append_item_to_last_section() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(9), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(16), cellType: TestBannerCell.self) }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "1818", title: "TestBanner"))

        // When
        cv.ss.appendItemToLastSection(newItem)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 9, "Section 0 unchanged")
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 17, "Section 1 should grow")
    }

    func test_append_item_to_last_section_with_empty_view_model_is_no_op() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: []))
        let item = makeCellInfo(from: TestBanner(id: "1990", title: "TestItem"))

        // When
        cv.ss.appendItemToLastSection(item)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 0, "Should remain empty")
    }

    // MARK: - Insert Item

    func test_insert_item() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(), cellType: TestBannerCell.self) }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "2024", title: "TestItem"))

        // When
        cv.ss.insertItem(newItem, at: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 9)
    }

    func test_insert_item_out_of_bounds() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(), cellType: TestBannerCell.self) }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "2143", title: "InvalidItem"))

        // When
        cv.ss.insertItem(newItem, at: IndexPath(item: 11, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 8, "Out of bounds insert should be a no-op")
    }

    func test_insert_multiple_items() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(), cellType: TestBannerCell.self) }
        }
        let newItems = makeCellInfos(from: makeSampleBanners(11))

        // When
        cv.ss.insertItems(newItems, at: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 19)
    }

    func test_insert_item_at_exact_end_index() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }
        let item = makeCellInfo(from: TestBanner(id: "2323", title: "TestItem"))

        // When — insert at endIndex (== count) should succeed
        cv.ss.insertItem(item, at: IndexPath(item: 5, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 6)
    }

    func test_insert_item_by_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("TopBannerList") { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }
        let item = makeCellInfo(from: TestBanner(id: "3434", title: "TestItem"))

        // When
        cv.ss.insertItem(item, atRow: 2, sectionIdentifier: "TopBannerList")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 6)
    }

    func test_insert_items_by_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("ChannelBannerList") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        let items = makeCellInfos(from: makeSampleBanners(4))

        // When
        cv.ss.insertItems(items, atRow: 1, sectionIdentifier: "ChannelBannerList")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 7)
    }

    func test_insert_item_by_identifier_at_end() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("BottomBannerList") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        let item = makeCellInfo(from: TestBanner(id: "4989", title: "EndSale"))

        // When
        cv.ss.insertItem(item, atRow: 3, sectionIdentifier: "BottomBannerList")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 4)
    }

    func test_insert_item_by_identifier_out_of_bounds_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("BannerList") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        let item = makeCellInfo(from: TestBanner(id: "-30000", title: "InvalidBanner"))

        // When
        cv.ss.insertItem(item, atRow: 90, sectionIdentifier: "BannerList")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
    }

    func test_insert_item_by_identifier_not_found_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("BannerList") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        let item = makeCellInfo(from: TestBanner(id: "-1111", title: "Typo"))

        // When
        cv.ss.insertItem(item, atRow: 0, sectionIdentifier: "VannerList")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
    }

    // MARK: - Replace Item

    func test_replace_item() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(), cellType: TestBannerCell.self) }
        }
        let updated = makeCellInfo(from: TestBanner(id: "8080", title: "I am protocol"))

        // When
        cv.ss.replaceItem(updated, at: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 8, "Count should remain the same")
    }

    func test_replace_item_by_section_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Game") { builder.cells(makeSampleBanners(9), cellType: TestBannerCell.self) }
        }
        let updated = makeCellInfo(from: TestBanner(id: "1024", title: "2^10"))

        // When
        cv.ss.replaceItem(updated, atRow: 0, sectionIdentifier: "Game")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 9, "Count should remain the same")
    }

    func test_replace_item_by_identifier_not_found_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Animation") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        let replacement = makeCellInfo(from: TestBanner(id: "2009", title: "Beethoven Virus"))

        // When
        cv.ss.replaceItem(replacement, atRow: 0, sectionIdentifier: "Drama")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3, "Should be unchanged")
    }

    // MARK: - Remove Item

    func test_remove_item() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(63), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeItem(at: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 62)
    }

    func test_remove_item_out_of_bounds() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(71), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeItem(at: IndexPath(item: 74, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 71, "Should be unchanged")
    }

    func test_remove_multiple_items() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(11), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeItems(at: [
            IndexPath(item: 0, section: 0),
            IndexPath(item: 2, section: 0),
            IndexPath(item: 4, section: 0)
        ])

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 8)
    }

    func test_remove_items_multi_section_correct_order() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(11), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeItems(at: [
            IndexPath(item: 1, section: 0),
            IndexPath(item: 3, section: 0),
            IndexPath(item: 0, section: 1),
            IndexPath(item: 2, section: 1)
        ])

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 9, "Section 0: 11 - 2 = 9")
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 3, "Section 1: 5 - 2 = 3")
    }

    func test_remove_all_items_in_section() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeAllItems(inSection: 1)

        // Then — section still exists, but empty
        XCTAssertEqual(cv.ss.getViewModel()?.count, 2)
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 0)
    }

    func test_remove_item_by_row_and_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Favorites") { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeItem(atRow: 0, sectionIdentifier: "Favorites")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 4)
    }

    func test_remove_all_items_by_section_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Cart") { builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self) }
            builder.section("Todo") { builder.cells(makeSampleBanners(6), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeAllItems(sectionIdentifier: "Todo")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 4)
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 0)
    }

    func test_remove_item_by_section_identifier_non_existent_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Keyboard") { builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeItem(atRow: 0, sectionIdentifier: "TrackPad")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 4, "Should be unchanged")
    }

    // MARK: - Move Item

    func test_move_item_within_same_section() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }

        // When — move item 0 -> 3
        cv.ss.moveItem(from: IndexPath(item: 0, section: 0), to: IndexPath(item: 3, section: 0))

        // Then — count unchanged
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 5)
    }

    func test_move_item_across_sections() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.moveItem(from: IndexPath(item: 0, section: 0), to: IndexPath(item: 1, section: 1))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3, "Section 0 shrinks")
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 4, "Section 1 grows")
    }

    func test_move_item_out_of_bounds_source_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.moveItem(from: IndexPath(item: 99, section: 0), to: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
    }

    func test_move_item_destination_clamped_to_end() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
        }

        // When — destination row exceeds count -> clamped to end
        cv.ss.moveItem(from: IndexPath(item: 0, section: 0), to: IndexPath(item: 19, section: 1))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 3)
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 3)
    }

    // MARK: - Lookup

    func test_item_count_in_section() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertEqual(cv.ss.itemCount(inSection: 0), 7)
        XCTAssertEqual(cv.ss.itemCount(inSection: 1), 3)
        XCTAssertEqual(cv.ss.itemCount(inSection: 2), 0)
    }

    func test_item_count_by_section_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Starcraft") { builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self) }
            builder.section("Warcraft") { builder.cells(makeSampleBanners(12), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertEqual(cv.ss.itemCount(sectionIdentifier: "Starcraft"), 4)
        XCTAssertEqual(cv.ss.itemCount(sectionIdentifier: "Warcraft"), 12)
        XCTAssertEqual(cv.ss.itemCount(sectionIdentifier: "LOL"), 0)
    }

    func test_item_at_index_path() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertNotNil(cv.ss.item(at: IndexPath(item: 0, section: 0)))
        XCTAssertNotNil(cv.ss.item(at: IndexPath(item: 4, section: 0)))
        XCTAssertNil(cv.ss.item(at: IndexPath(item: 5, section: 0)))
        XCTAssertNil(cv.ss.item(at: IndexPath(item: 0, section: 1)))
    }

    func test_item_by_row_and_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Pokemon") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertNotNil(cv.ss.item(atRow: 0, sectionIdentifier: "Pokemon"))
        XCTAssertNotNil(cv.ss.item(atRow: 2, sectionIdentifier: "Pokemon"))
        XCTAssertNil(cv.ss.item(atRow: 3, sectionIdentifier: "Pokemon"))
        XCTAssertNil(cv.ss.item(atRow: 0, sectionIdentifier: "Digimon"))
    }

    func test_item_count_on_empty_presenter() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertEqual(cv.ss.itemCount(inSection: 0), 0)
        XCTAssertEqual(cv.ss.itemCount(sectionIdentifier: "zxcv"), 0)
        XCTAssertNil(cv.ss.item(at: IndexPath(item: 0, section: 0)))
    }
}
