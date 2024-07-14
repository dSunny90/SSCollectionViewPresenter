//
//  BuilderTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 16.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class BuilderTests: XCTestCase {
    // MARK: - Basic Builder

    func test_build_view_model_creates_correct_structure() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(7)

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section("TestSection") {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1, "Should have 1 section")
        XCTAssertEqual(result[0].count, 7, "Section should have 7 items")
        XCTAssertEqual(result[0].identifier, "TestSection")
    }

    func test_build_view_model_with_multiple_sections() {
        // Given
        let cv = makeCollectionView()
        let group1 = makeSampleBanners(5)
        let group2 = makeSampleBanners(10)

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section("Alpha") {
                builder.cells(group1, cellType: TestBannerCell.self)
            }
            builder.section("Beta") {
                builder.cells(group2, cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].count, 5)
        XCTAssertEqual(result[1].count, 10)
    }

    func test_build_view_model_single_cell() {
        // Given
        let cv = makeCollectionView()
        let banner = TestBanner(id: "429", title: "TestTitle")

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cell(banner, cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 1)
    }

    func test_build_view_model_with_header_and_footer() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(5)
        let headerData = TestHeaderData(title: "Section Header")
        let footerData = TestFooterData(text: "Section Footer")

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section("withSupplementary") {
                builder.header(headerData, viewType: TestHeaderView.self)
                builder.footer(footerData, viewType: TestFooterView.self)
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 5)
        XCTAssertNotNil(result[0].headerInfo())
        XCTAssertNotNil(result[0].footerInfo())
    }

    func test_build_view_model_sets_page_and_has_next() {
        // Given
        let cv = makeCollectionView()

        // When
        let result = cv.ss.buildViewModel(page: 3, hasNext: true) { builder in
            builder.section {
                builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.page, 3)
        XCTAssertTrue(result.hasNext)
    }

    func test_builder_implicit_section_creation() {
        // Given
        let builder = SSCollectionViewModel.Builder()

        // When
        builder.cell(TestBanner(id: "90", title: "TopBanner"), cellType: TestBannerCell.self)
        builder.cell(TestBanner(id: "30", title: "MainBanner"), cellType: TestBannerCell.self)
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 1, "Should auto-create one implicit section")
        XCTAssertEqual(model[0].count, 2)
    }

    func test_builder_empty_section_is_still_created() {
        // Given
        let builder = SSCollectionViewModel.Builder()

        // When
        builder.section("EmptySection") { }
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 1, "Empty section should still be present")
        XCTAssertEqual(model[0].count, 0)
        XCTAssertEqual(model[0].identifier, "EmptySection")
    }

    func test_builder_chained_sections() {
        // Given
        let builder = SSCollectionViewModel.Builder()

        // When
        builder
            .section("AdBanner") {
                builder.cell(TestBanner(id: "2119", title: "AdBanner 1"), cellType: TestBannerCell.self)
            }
            .section("SubBanner") {
                builder.cell(TestBanner(id: "2234", title: "SubBanner 1"), cellType: TestBannerCell.self)
            }
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 2)
        XCTAssertEqual(model[0].identifier, "AdBanner")
        XCTAssertEqual(model[1].identifier, "SubBanner")
    }

    func test_builder_section_insets() {
        // Given
        let builder = SSCollectionViewModel.Builder()
        let insets = UIEdgeInsets(top: 10, left: 15, bottom: 20, right: 25)

        // When
        builder.section("newDesign") {
            builder.sectionInset(insets)
            builder.minimumLineSpacing(8)
            builder.minimumInteritemSpacing(4)
            builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
        }
        let model = builder.build()

        // Then
        XCTAssertEqual(model[0].sectionInset, insets)
        XCTAssertEqual(model[0].minimumLineSpacing, 8)
        XCTAssertEqual(model[0].minimumInteritemSpacing, 4)
    }

    func test_builder_no_section_no_items_produces_empty_model() {
        // Given
        let builder = SSCollectionViewModel.Builder()

        // When
        let model = builder.build()

        // Then
        XCTAssertTrue(model.isEmpty)
    }

    func test_builder_multiple_cells_then_section_auto_closes() {
        // Given
        let builder = SSCollectionViewModel.Builder()

        // When
        builder.cell(TestBanner(id: "0001", title: "Event Banner"), cellType: TestBannerCell.self)
        builder.section("adBannerList") {
            builder.cell(TestBanner(id: "0002", title: "Ad Banner"), cellType: TestBannerCell.self)
        }
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 2, "Implicit section + explicit section")
        XCTAssertEqual(model[0].count, 1)
        XCTAssertEqual(model[1].count, 1)
        XCTAssertEqual(model[1].identifier, "adBannerList")
    }

    func test_build_view_model_has_no_page_data() {
        // Given
        let cv = makeCollectionView()

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section("World") {
                builder.cells(makeSampleBanners(10), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 10)
        XCTAssertFalse(result.hasPageData, "buildViewModel should not use pageMap")
    }

    func test_builder_cell_actionClosure_is_called() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()

        let banners = makeSampleBanners(3)
        var received: (indexPath: IndexPath, action: String, input: Any?)?

        _ = cv.ss.buildViewModel { builder in
            builder.section("actions") {
                builder.cells(banners, cellType: TestBannerCell.self) { indexPath, cell, action, input in
                    received = (indexPath, action, input)
                }
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        // Dequeue cell through data source to ensure provider sets actionClosure
        let indexPath = IndexPath(item: 1, section: 0)
        guard let cell = cv.dataSource?.collectionView(cv, cellForItemAt: indexPath) as? UICollectionViewCell else {
            XCTFail("Failed to dequeue cell")
            return
        }

        // When — manually invoke the actionClosure on cell
        cell.actionClosure?("tap", nil)

        // Then
        XCTAssertEqual(received?.indexPath, indexPath)
        XCTAssertEqual(received?.action, "tap")
    }

    func test_builder_header_footer_actionClosure_are_called() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()

        let banners = makeSampleBanners(1)
        var headerReceived: (section: Int, action: String)?
        var footerReceived: (section: Int, action: String)?

        _ = cv.ss.buildViewModel { builder in
            builder.section("supplementary") {
                builder.header(TestHeaderData(title: "H"), viewType: TestHeaderView.self) { section, view, action, _ in
                    headerReceived = (section, action)
                }
                builder.footer(TestFooterData(text: "F"), viewType: TestFooterView.self) { section, view, action, _ in
                    footerReceived = (section, action)
                }
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let header = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? TestHeaderView
        let footer = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: 0)) as? TestFooterView

        // When — manually invoke the actionClosure on views
        header?.actionClosure?("headerTap", nil)
        footer?.actionClosure?("footerTap", nil)

        // Then
        XCTAssertEqual(headerReceived?.section, 0)
        XCTAssertEqual(headerReceived?.action, "headerTap")

        XCTAssertEqual(footerReceived?.section, 0)
        XCTAssertEqual(footerReceived?.action, "footerTap")
    }

    // MARK: - ExtendViewModel

    func test_extend_view_model_appends_to_existing_section() {
        // Given
        let cv = makeCollectionView()

        _ = cv.ss.buildViewModel { builder in
            builder.section("Korea") {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }

        // When
        let extended = cv.ss.extendViewModel(page: 1, hasNext: false) { builder in
            builder.section("Korea") {
                builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(extended.count, 1, "Should still be 1 section")
        XCTAssertEqual(extended[0].count, 11, "Should have 4 + 7 = 11 items")
        XCTAssertEqual(extended.page, 1)
        XCTAssertFalse(extended.hasNext)
    }

    func test_extend_view_model_adds_new_section() {
        // Given
        let cv = makeCollectionView()

        _ = cv.ss.buildViewModel { builder in
            builder.section("Banners") {
                builder.cells(makeSampleBanners(11), cellType: TestBannerCell.self)
            }
        }

        // When
        let extended = cv.ss.extendViewModel { builder in
            builder.section("MiddleBanners") {
                builder.cells(makeSampleBanners(19), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(extended.count, 2, "Should have 2 sections")
        XCTAssertEqual(extended[0].count, 11)
        XCTAssertEqual(extended[1].count, 19)
    }

    func test_extend_view_model_with_no_existing_view_model() {
        // Given
        let cv = makeCollectionView()
        XCTAssertNil(cv.ss.getViewModel())

        // When
        let result = cv.ss.extendViewModel { builder in
            builder.section("TimeDeal") {
                builder.cells(makeSampleBanners(23), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 23)
        XCTAssertEqual(result[0].identifier, "TimeDeal")
    }

    func test_extend_view_model_has_no_page_data() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("products") {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }

        // When
        let result = cv.ss.extendViewModel(page: 1, hasNext: false) { builder in
            builder.section("products") {
                builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 11)
        XCTAssertFalse(result.hasPageData, "extendViewModel should not use pageMap")
    }

    func test_extend_view_model_replaces_header_and_footer() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("products") {
                builder.header(TestHeaderData(title: "OldHeader"), viewType: TestHeaderView.self)
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        // When
        let result = cv.ss.extendViewModel { builder in
            builder.section("products") {
                builder.header(TestHeaderData(title: "NewHeader"), viewType: TestHeaderView.self)
                builder.footer(TestFooterData(text: "NewFooter"), viewType: TestFooterView.self)
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }

        // Then
        XCTAssertEqual(result[0].count, 5, "3 + 2 items")
        XCTAssertNotNil(result[0].headerInfo())
        XCTAssertNotNil(result[0].footerInfo())
    }

    // MARK: - Builder sections() API (Server-Driven)

    func test_builder_sections_api_with_view_model_section_representable() {
        // Given
        struct MockUnit: ViewModelUnitRepresentable {
            let unitType: String
            let unitData: Any?
        }
        struct MockSection: ViewModelSectionRepresentable {
            let sectionId: String?
            let units: [any ViewModelUnitRepresentable]
        }

        let sectionList: [MockSection] = [
            MockSection(sectionId: "banner", units: [
                MockUnit(unitType: "BANNER", unitData: [TestBanner(id: "0001", title: "Top Banner")])
            ]),
            MockSection(sectionId: "products", units: [
                MockUnit(unitType: "PRODUCT", unitData: makeSampleBanners(5))
            ])
        ]

        let builder = SSCollectionViewModel.Builder()

        // When
        builder.sections(
            sectionList,
            configureUnit: { unit, builder in
                switch unit.unitType {
                case "BANNER":
                    guard let banners = unit.unitData as? [TestBanner] else { return }
                    builder.cells(banners, cellType: TestBannerCell.self)
                case "PRODUCT":
                    guard let products = unit.unitData as? [TestBanner] else { return }
                    builder.cells(products, cellType: TestBannerCell.self)
                default:
                    break
                }
            }
        )
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 2)
        XCTAssertEqual(model[0].identifier, "banner")
        XCTAssertEqual(model[0].count, 1)
        XCTAssertEqual(model[1].identifier, "products")
        XCTAssertEqual(model[1].count, 5)
    }

    func test_builder_sections_api_with_configure_section() {
        // Given
        struct MockUnit: ViewModelUnitRepresentable {
            let unitType: String
            let unitData: Any?
        }
        struct MockSection: ViewModelSectionRepresentable {
            let sectionId: String?
            let units: [any ViewModelUnitRepresentable]
        }

        let sectionList: [MockSection] = [
            MockSection(sectionId: "designSystemTest", units: [
                MockUnit(unitType: "ITEM", unitData: makeSampleBanners(3))
            ])
        ]

        let builder = SSCollectionViewModel.Builder()

        // When
        builder.sections(
            sectionList,
            configureSection: { section, builder in
                builder.sectionInset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
                builder.minimumLineSpacing(5)
            },
            configureUnit: { unit, builder in
                guard let items = unit.unitData as? [TestBanner] else { return }
                builder.cells(items, cellType: TestBannerCell.self)
            }
        )
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 1)
        XCTAssertEqual(model[0].sectionInset, UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        XCTAssertEqual(model[0].minimumLineSpacing, 5)
    }
}
