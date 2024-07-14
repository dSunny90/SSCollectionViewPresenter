//
//  CompositionalLayoutTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 23.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class CompositionalLayoutTests: XCTestCase {
    // MARK: - SSCompositionalLayoutSection Init

    func test_compositional_layout_section_with_all_parameters() {
        let section = SSCompositionalLayoutSection(
            direction: .horizontal,
            itemSize: .uniform(columns: 3, width: 120, height: 200),
            scrolling: .paging,
            isUniformAcrossSiblings: true,
            uniformEstimatedHeight: 180
        )

        XCTAssertEqual(section.direction, .horizontal)
        guard case let .uniform(columns, width, height) = section.itemSize else {
            return XCTFail("itemSize should be .uniform")
        }
        XCTAssertEqual(columns, 3)
        XCTAssertEqual(width, 120)
        XCTAssertEqual(height, 200)
        XCTAssertEqual(section.scrolling, .paging)
        XCTAssertTrue(section.isUniformAcrossSiblings)
        XCTAssertEqual(section.uniformEstimatedHeight, 180)
    }

    // MARK: - Vertical Single Column: Full-Width Stacked

    @available(iOS 13.0, *)
    func test_vertical_single_column_cells_are_full_width_and_stacked() {
        // Given — single-column vertical, height 100
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 100)
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        XCTAssertEqual(attrs.count, 3, "Should have 3 cells")

        for attr in attrs {
            // Then - Full container width
            XCTAssertEqual(attr.frame.width, 375, accuracy: 1)
            XCTAssertEqual(attr.frame.height, 100, accuracy: 1)
        }

        // Vertically stacked: each cell below the previous
        XCTAssertGreaterThanOrEqual(attrs[1].frame.origin.y, attrs[0].frame.maxY - 1)
        XCTAssertGreaterThanOrEqual(attrs[2].frame.origin.y, attrs[1].frame.maxY - 1)
    }

    // MARK: - Horizontal Grid: Items Side-By-Side

    @available(iOS 13.0, *)
    func test_horizontal_2_column_grid_items_side_by_side() {
        // Given — horizontal 2-column grid: items placed left-to-right
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 2, height: 120)
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        // First group (items 0 & 1) should always be computed
        guard attrs.count >= 2 else {
            return XCTFail("At least first group of 2 cells should be laid out, got \(attrs.count)")
        }

        let expectedWidth = 375.0 / 2.0

        // Then - Each cell width should be half of container
        XCTAssertEqual(attrs[0].frame.width, expectedWidth, accuracy: 1)
        XCTAssertEqual(attrs[1].frame.width, expectedWidth, accuracy: 1)

        // Then - Height should match config
        XCTAssertEqual(attrs[0].frame.height, 120, accuracy: 1)
        XCTAssertEqual(attrs[1].frame.height, 120, accuracy: 1)

        // Then - Same row: same Y, left item then right item
        XCTAssertEqual(attrs[0].frame.origin.y, attrs[1].frame.origin.y, accuracy: 1)
        XCTAssertLessThan(attrs[0].frame.origin.x, attrs[1].frame.origin.x)

        // Then - Items should not overlap
        XCTAssertFalse(attrs[0].frame.intersects(attrs[1].frame))
    }

    @available(iOS 13.0, *)
    func test_horizontal_3_column_grid_items_arranged_left_to_right() {
        // Given — 3-column horizontal grid
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 3, height: 100)
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(6), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard attrs.count >= 3 else {
            return XCTFail("First group of 3 cells should exist, got \(attrs.count)")
        }

        let expectedWidth = 375.0 / 3.0

        // Then - Width ~1/3 of container
        for i in 0..<3 {
            XCTAssertEqual(attrs[i].frame.width, expectedWidth, accuracy: 1)
            XCTAssertEqual(attrs[i].frame.height, 100, accuracy: 1)
        }

        // Then - All 3 items at same Y
        XCTAssertEqual(attrs[0].frame.origin.y, attrs[1].frame.origin.y, accuracy: 1)
        XCTAssertEqual(attrs[1].frame.origin.y, attrs[2].frame.origin.y, accuracy: 1)

        // Then - X ordering: left to right
        XCTAssertLessThan(attrs[0].frame.origin.x, attrs[1].frame.origin.x)
        XCTAssertLessThan(attrs[1].frame.origin.x, attrs[2].frame.origin.x)
    }

    // MARK: - Multi-Section with Different Configs

    @available(iOS 13.0, *)
    func test_multi_section_layout_sections_stacked_vertically() {
        // Given — Section 0: 1-col vertical h=80, Section 1: 2-col horizontal h=120
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 80)
            ),
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 2, height: 120)
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(1), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let allAttrs = sortedCellAttributes(cv)
        let s0 = allAttrs.filter { $0.indexPath.section == 0 }
        let s1 = allAttrs.filter { $0.indexPath.section == 1 }

        guard !s0.isEmpty else { return XCTFail("Section 0 should have cells") }
        guard s1.count >= 2 else { return XCTFail("Section 1 should have 2 cells, got \(s1.count)") }

        // Then - Section 0: full-width, 80pt height
        XCTAssertEqual(s0[0].frame.width, 375, accuracy: 1)
        XCTAssertEqual(s0[0].frame.height, 80, accuracy: 1)

        // Then - Section 1: half-width grid, 120pt height
        XCTAssertEqual(s1[0].frame.width, 375.0 / 2.0, accuracy: 1)
        XCTAssertEqual(s1[0].frame.height, 120, accuracy: 1)

        // Then - Section 1 below Section 0
        XCTAssertGreaterThan(s1[0].frame.origin.y, s0[0].frame.origin.y)

        // Then - Section 1 items side-by-side
        XCTAssertEqual(s1[0].frame.origin.y, s1[1].frame.origin.y, accuracy: 1)
        XCTAssertLessThan(s1[0].frame.origin.x, s1[1].frame.origin.x)

        // 80 + 120 = 200pt total content height
        XCTAssertEqual(cv.contentSize.height, 200, accuracy: 1)
    }

    // MARK: - Orthogonal Scrolling

    @available(iOS 13.0, *)
    func test_horizontal_paging_section_cell_dimensions() {
        // Given — 3 columns with paging
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 3, height: 180),
                scrolling: .paging
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(6), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let expectedWidth = 375.0 / 3.0

        let attrs = sortedCellAttributes(cv)
        guard !attrs.isEmpty else { return XCTFail("Cells should exist") }

        // Then
        XCTAssertEqual(attrs[0].frame.height, 180, accuracy: 1)
        XCTAssertEqual(attrs[0].frame.width, expectedWidth, accuracy: 1)
        XCTAssertEqual(attrs[5].frame.origin.x, expectedWidth * 5, accuracy: 1)
    }

    // MARK: - Uniform Across Siblings (iOS 17+)

    @available(iOS 17.0, *)
    func test_uniform_siblings_have_matching_heights() {
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 2, height: 100),
                isUniformAcrossSiblings: true,
                uniformEstimatedHeight: 120
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard attrs.count >= 2 else { return XCTFail("Should have cells") }

        XCTAssertEqual(attrs[0].frame.height, attrs[1].frame.height, accuracy: 1,
                       "Uniform siblings should have matching heights")
        XCTAssertEqual(attrs[0].frame.width, 375.0 / 2.0, accuracy: 1)
    }

    // MARK: - ContentSize Verification

    @available(iOS 13.0, *)
    func test_single_column_content_size() {
        // Given — 3 items stacked vertically at 100pt each
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 100)
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // 3 * 100pt = 300pt
        XCTAssertEqual(cv.contentSize.height, 300, accuracy: 1)
        XCTAssertEqual(cv.contentSize.width, 375, accuracy: 1)
    }

    @available(iOS 13.0, *)
    func test_horizontal_grid_content_size() {
        // Given — 4 items in 2-column grid, height 100 -> 2 rows = 200pt
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 2, height: 100)
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        XCTAssertEqual(cv.contentSize.height, 200, accuracy: 1)
        XCTAssertEqual(cv.contentSize.width, 375, accuracy: 1)
    }

    @available(iOS 13.0, *)
    func test_horizontal_grid_6_items_3_columns_content_size() {
        // Given — 6 items / 3 columns = 2 rows * 100pt = 200pt
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 3, height: 100)
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(6), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        XCTAssertEqual(cv.contentSize.height, 200, accuracy: 1)
    }

    // MARK: - Orthogonal Scrolling: Items Laid Out Horizontally

    @available(iOS 13.0, *)
    func test_orthogonal_paging_items_share_same_y() {
        // Given — 5 full-width items in a paging orthogonal section
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 1, height: 200),
                scrolling: .paging
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard attrs.count >= 2 else {
            return XCTFail("At least 2 orthogonal items should be laid out, got \(attrs.count)")
        }

        // All items should share the same Y (single horizontal strip)
        let baseY = attrs[0].frame.origin.y
        for attr in attrs {
            XCTAssertEqual(attr.frame.origin.y, baseY, accuracy: 1,
                           "Orthogonal item \(attr.indexPath.item) should be on the same Y")
        }
    }

    @available(iOS 13.0, *)
    func test_orthogonal_paging_items_extend_beyond_viewport() {
        // Given — 5 full-width items each 375pt -> total 1875pt > 375pt viewport
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 1, height: 200),
                scrolling: .paging
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard let last = attrs.last else {
            return XCTFail("Should have items")
        }

        // Last item's right edge should exceed the 375pt viewport
        XCTAssertGreaterThan(last.frame.maxX, 375,
                             "Orthogonal content should extend beyond viewport width")

        // Each item should be 375pt wide (fractionalWidth 1/1)
        XCTAssertEqual(attrs[0].frame.width, 375, accuracy: 1)
    }

    @available(iOS 13.0, *)
    func test_orthogonal_paging_items_arranged_sequentially() {
        // Given — paging section, each item = 375pt wide
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 1, height: 200),
                scrolling: .paging
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard attrs.count >= 2 else {
            return XCTFail("Need at least 2 items")
        }

        // Each subsequent item should start where the previous one ends
        for i in 1..<attrs.count {
            XCTAssertGreaterThan(
                attrs[i].frame.origin.x, attrs[i - 1].frame.origin.x,
                "Item \(i) should be to the right of item \(i - 1)"
            )
            // Items should be adjacent (next item starts at or very near previous maxX)
            XCTAssertEqual(
                attrs[i].frame.origin.x, attrs[i - 1].frame.maxX, accuracy: 1,
                "Item \(i) should start where item \(i - 1) ends"
            )
        }
    }

    // MARK: - Orthogonal Scrolling: .continuous Behavior

    @available(iOS 13.0, *)
    func test_orthogonal_continuous_items_share_same_y_and_extend() {
        // Given — continuous scrolling with 2 columns, 6 items
        // group = fractionalWidth(1.0) with 2 items -> 3 groups total
        // total horizontal content = 3 * 375 = 1125pt
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 2, height: 150),
                scrolling: .continuous
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(6), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard attrs.count >= 2 else {
            return XCTFail("Should have at least first group items, got \(attrs.count)")
        }

        // All items at the same Y
        let baseY = attrs[0].frame.origin.y
        for attr in attrs {
            XCTAssertEqual(attr.frame.origin.y, baseY, accuracy: 1)
        }

        // Each item width = 375 / 2 = 187.5
        XCTAssertEqual(attrs[0].frame.width, 375.0 / 2.0, accuracy: 1)
        XCTAssertEqual(attrs[0].frame.height, 150, accuracy: 1)

        // Content extends beyond viewport
        if let last = attrs.last {
            XCTAssertGreaterThan(last.frame.maxX, 375)
        }
    }

    // MARK: - Orthogonal Scrolling: .groupPaging Behavior

    @available(iOS 13.0, *)
    func test_orthogonal_group_paging_items_laid_out_horizontally() {
        // Given — groupPaging with 3 columns, 9 items -> 3 groups
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 3, height: 180),
                scrolling: .groupPaging
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(9), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard attrs.count >= 3 else {
            return XCTFail("First group (3 items) should be laid out, got \(attrs.count)")
        }

        // First group: 3 items side by side, each 375/3 = 125pt
        let expectedWidth = 375.0 / 3.0
        for i in 0..<3 {
            XCTAssertEqual(attrs[i].frame.width, expectedWidth, accuracy: 1)
            XCTAssertEqual(attrs[i].frame.height, 180, accuracy: 1)
        }

        // Same Y for first group
        XCTAssertEqual(attrs[0].frame.origin.y, attrs[1].frame.origin.y, accuracy: 1)
        XCTAssertEqual(attrs[1].frame.origin.y, attrs[2].frame.origin.y, accuracy: 1)

        // Left-to-right within the first group
        XCTAssertLessThan(attrs[0].frame.origin.x, attrs[1].frame.origin.x)
        XCTAssertLessThan(attrs[1].frame.origin.x, attrs[2].frame.origin.x)

        // If second group visible, it should start after the first group
        if attrs.count >= 6 {
            XCTAssertGreaterThan(
                attrs[3].frame.origin.x, attrs[2].frame.origin.x,
                "Second group should start after first group"
            )
        }
    }

    // MARK: - Orthogonal Scrolling: .groupPagingCentered Behavior

    @available(iOS 13.0, *)
    func test_orthogonal_group_paging_centered_same_y_and_height() {
        // Given — groupPagingCentered with 2 columns, 6 items
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 2, height: 160),
                scrolling: .groupPagingCentered
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(6), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard attrs.count >= 2 else {
            return XCTFail("Should have at least first group, got \(attrs.count)")
        }

        // All share same Y
        let baseY = attrs[0].frame.origin.y
        for attr in attrs {
            XCTAssertEqual(attr.frame.origin.y, baseY, accuracy: 1)
            XCTAssertEqual(attr.frame.height, 160, accuracy: 1)
        }

        // Half-width items
        XCTAssertEqual(attrs[0].frame.width, 375.0 / 2.0, accuracy: 1)
    }

    // MARK: - Orthogonal Scrolling: .continuousGroupLeadingBoundary Behavior

    @available(iOS 13.0, *)
    func test_orthogonal_continuous_group_leading_boundary() {
        // Given — continuousGroupLeadingBoundary, 1 column (full-width pages), 4 items
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 1, height: 220),
                scrolling: .continuousGroupLeadingBoundary
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)
        guard attrs.count >= 2 else {
            return XCTFail("Should have multiple items, got \(attrs.count)")
        }

        // Full-width items
        XCTAssertEqual(attrs[0].frame.width, 375, accuracy: 1)
        XCTAssertEqual(attrs[0].frame.height, 220, accuracy: 1)

        // Sequential horizontal arrangement
        for i in 1..<attrs.count {
            XCTAssertGreaterThan(attrs[i].frame.origin.x, attrs[i - 1].frame.origin.x)
        }
    }

    // MARK: - Mixed Layout: Vertical Main + Horizontal Orthogonal Sections

    @available(iOS 13.0, *)
    func test_mixed_vertical_and_orthogonal_sections_stacked() {
        // Given
        // Section 0: vertical single-column (normal vertical scroll), h=80
        // Section 1: horizontal paging carousel (orthogonal scroll), h=200
        // Section 2: vertical single-column (normal vertical scroll), h=60
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 80)
            ),
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 1, height: 200),
                scrolling: .paging
            ),
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 60)
            ),
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // --- Section 0: vertical list ---
        let s0 = sortedCellAttributes(cv, section: 0)
        guard s0.count == 2 else {
            return XCTFail("Section 0 should have 2 cells, got \(s0.count)")
        }

        // Full-width, stacked vertically
        XCTAssertEqual(s0[0].frame.width, 375, accuracy: 1)
        XCTAssertEqual(s0[0].frame.height, 80, accuracy: 1)
        XCTAssertGreaterThanOrEqual(s0[1].frame.origin.y, s0[0].frame.maxY - 1)

        // --- Section 1: orthogonal carousel ---
        let s1 = sortedCellAttributes(cv, section: 1)
        guard s1.count >= 2 else {
            return XCTFail("Section 1 (carousel) should have items, got \(s1.count)")
        }

        // All carousel items at same Y, below section 0
        let carouselY = s1[0].frame.origin.y
        XCTAssertGreaterThan(carouselY, s0.last?.frame.origin.y ?? 9999,
                             "Carousel section should be below the top list")
        for attr in s1 {
            XCTAssertEqual(attr.frame.origin.y, carouselY, accuracy: 1)
            XCTAssertEqual(attr.frame.height, 200, accuracy: 1)
        }

        // Carousel items extend horizontally beyond viewport
        if let lastCarousel = s1.last {
            XCTAssertGreaterThan(lastCarousel.frame.maxX, 375,
                                 "Carousel should extend beyond viewport")
        }

        // --- Section 2: vertical list below carousel ---
        let s2 = sortedCellAttributes(cv, section: 2)
        guard !s2.isEmpty else {
            return XCTFail("Section 2 should have cells")
        }

        // Section 2 should be below section 1 (carousel takes only its height)
        XCTAssertGreaterThan(s2[0].frame.origin.y, carouselY,
                             "Bottom list should be below the carousel")
        XCTAssertEqual(s2[0].frame.width, 375, accuracy: 1)
        XCTAssertEqual(s2[0].frame.height, 60, accuracy: 1)
    }

    @available(iOS 13.0, *)
    func test_mixed_layout_overall_content_size() {
        // Given — same 3-section mixed layout
        // Section 0: 2 items * 80pt = 160pt
        // Section 1: carousel h=200pt (orthogonal section = 1 row)
        // Section 2: 2 items * 60pt = 120pt
        // Total: 160 + 200 + 120 = 480pt
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 80)
            ),
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 1, height: 200),
                scrolling: .paging
            ),
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 60)
            ),
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // Main scroll direction is vertical, so contentSize.height includes all sections
        XCTAssertEqual(cv.contentSize.height, 480, accuracy: 1)
    }

    @available(iOS 13.0, *)
    func test_mixed_grid_and_carousel_layout() {
        // Given
        // Section 0: 2-col horizontal grid (no orthogonal scrolling), h=100
        // Section 1: full-width paging carousel (orthogonal), h=250
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 2, height: 100)
            ),
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .uniform(columns: 1, height: 250),
                scrolling: .paging
            ),
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // Section 0: 2-col grid -> 2 rows * 100 = 200pt
        // Section 1: carousel -> 250pt
        // Total = 450pt
        XCTAssertEqual(cv.contentSize.height, 450, accuracy: 1)

        // Grid section items: half-width
        let gridAttrs = sortedCellAttributes(cv, section: 0)
        guard !gridAttrs.isEmpty else { return XCTFail("Grid should have items") }
        XCTAssertEqual(gridAttrs[0].frame.width, 375.0 / 2.0, accuracy: 1)
        XCTAssertEqual(gridAttrs[0].frame.height, 100, accuracy: 1)

        // Carousel items: full-width, same Y, extending beyond viewport
        let carouselAttrs = sortedCellAttributes(cv, section: 1)
        guard carouselAttrs.count >= 2 else { return XCTFail("Carousel should have items") }
        XCTAssertEqual(carouselAttrs[0].frame.width, 375, accuracy: 1)
        XCTAssertEqual(carouselAttrs[0].frame.height, 250, accuracy: 1)

        let carouselY = carouselAttrs[0].frame.origin.y
        for (i, attr) in carouselAttrs.enumerated() {
            XCTAssertEqual(attr.frame.origin.x, 375 * CGFloat(i), accuracy: 1)
            XCTAssertEqual(attr.frame.origin.y, carouselY, accuracy: 1)
        }

        if let lastBanner = carouselAttrs.last, carouselAttrs.count > 1 {
            XCTAssertGreaterThan(lastBanner.frame.maxX, 375)
        }
    }

    // MARK: - Dynamic Height (itemSize: .dynamic → cell's static size)

    /// When `itemSize` is `.dynamic`, the layout should use TestBannerCell's
    /// `static func size(with:constrainedTo:)` which returns 100pt.
    @available(iOS 13.0, *)
    func test_dynamic_height_uses_cell_static_size() {
        // Given — dynamic sizing, cell returns 100pt
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(direction: .vertical, itemSize: .dynamic)
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)

        // Then — each cell should be 100pt (from TestBannerCell.size)
        XCTAssertEqual(attrs.count, 3)
        for attr in attrs {
            XCTAssertEqual(attr.frame.height, 100, accuracy: 1,
                           "Cell height should come from TestBannerCell.size(with:constrainedTo:)")
            XCTAssertEqual(attr.frame.width, 375, accuracy: 1)
        }
    }

    /// Explicit `.uniform` height should override the cell's static size.
    @available(iOS 13.0, *)
    func test_explicit_height_overrides_cell_static_size() {
        // Given — explicit height 200pt, even though cell returns 100pt
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 200)
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)

        // Then — 200pt, not 100pt
        XCTAssertEqual(attrs.count, 2)
        for attr in attrs {
            XCTAssertEqual(attr.frame.height, 200, accuracy: 1,
                           "Explicit height should override cell's static size")
        }
    }

    /// Dynamic sizing with horizontal scrolling (carousel).
    /// Since all TestBannerCell instances return the same size (375x100),
    /// the layout uses the efficient `repeatingSubitem` path internally.
    @available(iOS 13.0, *)
    func test_dynamic_height_with_orthogonal_carousel() {
        // Given — horizontal paging, dynamic sizing
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .horizontal,
                itemSize: .dynamic,
                scrolling: .paging
            )
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let wideAttrs = sortedCellAttributes(cv)

        // Then — items sized from cell's static size (375x100)
        XCTAssertGreaterThanOrEqual(wideAttrs.count, 1)
        for attr in wideAttrs {
            XCTAssertEqual(attr.frame.width, 375, accuracy: 1)
            XCTAssertEqual(attr.frame.height, 100, accuracy: 1)
        }
    }

    /// Mixed sections: section 0 uses explicit `.uniform`, section 1 uses `.dynamic`.
    @available(iOS 13.0, *)
    func test_mixed_explicit_and_dynamic_height_sections() {
        // Given
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .uniform(columns: 1, height: 50)
            ),
            SSCompositionalLayoutSection(
                direction: .vertical,
                itemSize: .dynamic
            ),
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section("explicit") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
            builder.section("dynamic") {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let s0 = sortedCellAttributes(cv, section: 0)
        let s1 = sortedCellAttributes(cv, section: 1)

        // Then
        XCTAssertEqual(s0.count, 2)
        XCTAssertEqual(s1.count, 2)
        // Section 0: explicit 50pt
        for attr in s0 {
            XCTAssertEqual(attr.frame.height, 50, accuracy: 1)
        }
        // Section 1: dynamic 100pt from TestBannerCell.size
        for attr in s1 {
            XCTAssertEqual(attr.frame.height, 100, accuracy: 1)
        }
    }

    /// Content size should reflect the dynamic heights.
    @available(iOS 13.0, *)
    func test_dynamic_height_content_size() {
        // Given — 4 cells stacked, each 100pt from static size
        let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: [
            SSCompositionalLayoutSection(direction: .vertical, itemSize: .dynamic)
        ])
        let cv = makeCollectionView(layoutKind: .compositional(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // Then — content height = 4 × 100pt
        XCTAssertEqual(cv.contentSize.height, 400, accuracy: 2,
                       "Content height should be 4 × 100pt from cell's static size")
    }
}
