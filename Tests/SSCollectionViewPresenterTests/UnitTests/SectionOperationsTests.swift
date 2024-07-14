//
//  SectionOperationsTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 16.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class SectionOperationsTests: XCTestCase {
    // MARK: - Append

    func test_append_section() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(11), cellType: TestBannerCell.self)
            }
        }
        let newSection = SSCollectionViewModel.SectionInfo(
            items: makeCellInfos(from: makeSampleBanners(23)),
            identifier: "NewSection"
        )

        // When
        cv.ss.appendSection(newSection)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 2)
    }

    func test_append_multiple_sections() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(11), cellType: TestBannerCell.self)
            }
        }
        let sections = [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(23))),
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(67)))
        ]

        // When
        cv.ss.appendSections(contentsOf: sections)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 3)
    }

    func test_append_section_with_no_view_model_is_no_op() {
        // Given
        let cv = makeCollectionView()
        let section = SSCollectionViewModel.SectionInfo(items: [])

        // When
        cv.ss.appendSection(section)

        // Then
        XCTAssertNil(cv.ss.getViewModel())
    }

    // MARK: - Insert

    func test_insert_section_at_beginning() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Hello") {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        let newSection = SSCollectionViewModel.SectionInfo(
            items: makeCellInfos(from: makeSampleBanners(2)),
            identifier: "Swift"
        )

        // When
        cv.ss.insertSection(newSection, at: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 2)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "Swift")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].identifier, "Hello")
    }

    func test_insert_section_at_middle() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("안녕") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section("Halo") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        let newSection = SSCollectionViewModel.SectionInfo(
            items: makeCellInfos(from: makeSampleBanners(2)),
            identifier: "Hello"
        )

        // When
        cv.ss.insertSection(newSection, at: 1)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 3)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "안녕")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].identifier, "Hello")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[2].identifier, "Halo")
    }

    func test_insert_section_out_of_bounds_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        let newSection = SSCollectionViewModel.SectionInfo(items: [])

        // When
        cv.ss.insertSection(newSection, at: 99)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
    }

    func test_insert_multiple_sections() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("mango") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section("strawberry") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        let newSections = [
            SSCollectionViewModel.SectionInfo(items: [], identifier: "apple"),
            SSCollectionViewModel.SectionInfo(items: [], identifier: "banana"),
        ]

        // When
        cv.ss.insertSections(newSections, at: 1)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 4)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].identifier, "apple")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[2].identifier, "banana")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[3].identifier, "strawberry")
    }

    // MARK: - Remove

    func test_remove_section_at_index() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("climbing") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section("skating") {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        // When
        cv.ss.removeSection(at: 1)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "climbing")
    }

    func test_remove_section_out_of_bounds_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }

        // When
        cv.ss.removeSection(at: 5)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
    }

    func test_remove_sections_at_multiple_indices() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("I") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("My") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("Me") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("Mine") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
        }

        // When — remove index 1 and 3
        cv.ss.removeSections(at: IndexSet([1, 3]))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 2)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "I")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].identifier, "Me")
    }

    func test_remove_section_by_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("banner") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section("products") {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }

        // When
        cv.ss.removeSection(identifier: "banner")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "products")
    }

    func test_remove_section_by_identifier_not_found_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("products") {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        // When
        cv.ss.removeSection(identifier: "asdf")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
    }

    func test_remove_all_sections() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("a") { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
            builder.section("b") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.removeAllSections()

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 0)
    }

    // MARK: - Replace

    func test_replace_section_at_index() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("old") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        let replacement = SSCollectionViewModel.SectionInfo(
            items: makeCellInfos(from: makeSampleBanners(5)),
            identifier: "new"
        )

        // When
        cv.ss.replaceSection(replacement, at: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "new")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].count, 5)
    }

    func test_replace_section_at_index_out_of_bounds_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Original") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        let replacement = SSCollectionViewModel.SectionInfo(items: [], identifier: "Brood War")

        // When
        cv.ss.replaceSection(replacement, at: 5)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "Original")
    }

    func test_replace_section_by_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("banner") { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
            builder.section("products") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        let replacement = SSCollectionViewModel.SectionInfo(
            items: makeCellInfos(from: makeSampleBanners(10)),
            identifier: "soldout"
        )

        // When
        cv.ss.replaceSection(replacement, identifier: "products")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 2)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].identifier, "soldout")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].count, 10)
    }

    func test_replace_section_by_identifier_not_found_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("products") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }
        let replacement = SSCollectionViewModel.SectionInfo(items: [], identifier: "fake")

        // When
        cv.ss.replaceSection(replacement, identifier: "qwer")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "products")
    }

    // MARK: - Move

    func test_move_section_forward() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Chovy") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("Peyz") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("Lehends") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
        }

        // When — move index 0 -> 2
        cv.ss.moveSection(from: 0, to: 2)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "Peyz")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].identifier, "Lehends")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[2].identifier, "Chovy")
    }

    func test_move_section_backward() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Kiin") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("Canyon") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("Chovy") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
        }

        // When — move index 2 -> 0
        cv.ss.moveSection(from: 2, to: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "Chovy")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].identifier, "Kiin")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[2].identifier, "Canyon")
    }

    func test_move_section_same_index_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("topBanner") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("adBanner") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
        }

        // When
        cv.ss.moveSection(from: 0, to: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.sections[0].identifier, "topBanner")
        XCTAssertEqual(cv.ss.getViewModel()?.sections[1].identifier, "adBanner")
    }

    // MARK: - Lookup

    func test_section_count() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("topBanner") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("middleBanner") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
            builder.section("bottomBanner") { builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertEqual(cv.ss.sectionCount, 3)
    }

    func test_section_count_empty_view_model() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertEqual(cv.ss.sectionCount, 0)
    }

    func test_section_at_index() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("2024") {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(cv.ss.section(at: 0)?.identifier, "2024")
        XCTAssertEqual(cv.ss.section(at: 0)?.count, 5)
        XCTAssertNil(cv.ss.section(at: 123))
    }

    func test_section_by_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("banner") { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
            builder.section("products") { builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertEqual(cv.ss.section(identifier: "products")?.count, 7)
        XCTAssertNil(cv.ss.section(identifier: "qwerasdf"))
    }

    func test_section_index_by_identifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("banner") { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
            builder.section("products") { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
        }

        // Then
        XCTAssertEqual(cv.ss.sectionIndex(identifier: "banner"), 0)
        XCTAssertEqual(cv.ss.sectionIndex(identifier: "products"), 1)
        XCTAssertNil(cv.ss.sectionIndex(identifier: "asdfqwer"))
    }
}
