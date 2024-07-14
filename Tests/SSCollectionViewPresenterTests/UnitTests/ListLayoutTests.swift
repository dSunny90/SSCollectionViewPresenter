//
//  ListLayoutTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 23.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

// MARK: - Self-Sizing Cell (Auto Layout)

/// A model whose `text` length drives the cell height through Auto Layout.
private struct VariableHeightItem: Sendable {
    let text: String
}

/// A cell that uses a multi-line UILabel pinned to contentView edges.
/// Because `size(with:constrainedTo:)` is NOT overridden (returns nil),
/// the list layout relies on Auto Layout for self-sizing.
private final class SelfSizingCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    private let label: UILabel = {
        let l = UILabel()
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 16)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    var configurer: (SelfSizingCell, VariableHeightItem) -> Void {
        { cell, model in
            cell.label.text = model.text
        }
    }
}

/// A cell that enforces a **fixed** height of 60pt.
///
/// `static func size(with:constrainedTo:)` is only called by FlowLayout's
/// `sizeForItemAt` delegate — CompositionalLayout / ListLayout ignores it.
/// To fix the height in list layout, we override `preferredLayoutAttributesFitting`
/// which is the hook CompositionalLayout actually calls for self-sizing.
private final class FixedHeightCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    static let fixedHeight: CGFloat = 60

    private let label = UILabel()

    static func size(with input: VariableHeightItem?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 375, height: fixedHeight)
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let attrs = super.preferredLayoutAttributesFitting(layoutAttributes)
        attrs.frame.size.height = Self.fixedHeight
        return attrs
    }

    var configurer: (FixedHeightCell, VariableHeightItem) -> Void {
        { cell, model in
            cell.label.text = model.text
        }
    }
}

@MainActor
final class ListLayoutTests: XCTestCase {
    typealias Config = SSCollectionViewPresenter.ListLayoutConfig
    // MARK: - ListLayoutConfig Init

    @available(iOS 14.0, *)
    func test_list_layout_config_default_values() {
        // When
        let config = Config()

        // Then
        XCTAssertEqual(config.appearance, .plain)
        XCTAssertTrue(config.showsSeparators)
        XCTAssertEqual(config.headerMode, .none)
        XCTAssertEqual(config.footerMode, .none)
    }

    @available(iOS 14.0, *)
    func test_list_layout_config_custom_values() {
        // When
        let config = Config(
            appearance: .insetGrouped,
            showsSeparators: false,
            headerMode: .supplementary,
            footerMode: .supplementary
        )

        // Then
        XCTAssertEqual(config.appearance, .insetGrouped)
        XCTAssertFalse(config.showsSeparators)
        XCTAssertEqual(config.headerMode, .supplementary)
        XCTAssertEqual(config.footerMode, .supplementary)
    }

    // MARK: - Appearance Enum

    func test_appearance_raw_values() {
        XCTAssertEqual(Config.Appearance.plain.rawValue, 0)
        XCTAssertEqual(Config.Appearance.grouped.rawValue, 1)
        XCTAssertEqual(Config.Appearance.insetGrouped.rawValue, 2)
        XCTAssertEqual(Config.Appearance.sidebar.rawValue, 3)
        XCTAssertEqual(Config.Appearance.sidebarPlain.rawValue, 4)
    }

    // MARK: - HeaderMode / FooterMode Enums

    func test_header_mode_raw_values() {
        XCTAssertEqual(Config.HeaderMode.none.rawValue, 0)
        XCTAssertEqual(Config.HeaderMode.supplementary.rawValue, 1)
        XCTAssertEqual(Config.HeaderMode.firstItemInSection.rawValue, 2)
    }

    func test_footer_mode_raw_values() {
        XCTAssertEqual(Config.FooterMode.none.rawValue, 0)
        XCTAssertEqual(Config.FooterMode.supplementary.rawValue, 1)
    }

    // MARK: - Make Layout

    @available(iOS 14.0, *)
    func test_list_layout_config_make_layout_grouped() {
        // Given
        let config = Config(appearance: .grouped)

        // When
        let layout = config.makeLayout()

        // Then
        XCTAssertNotNil(layout)
    }

    @available(iOS 14.0, *)
    func test_list_layout_config_make_layout_inset_grouped() {
        // Given
        let config = Config(appearance: .insetGrouped)

        // When
        let layout = config.makeLayout()

        // Then
        XCTAssertNotNil(layout)
    }

    @available(iOS 14.0, *)
    func test_list_layout_config_make_layout_sidebar() {
        // Given
        let config = Config(appearance: .sidebar)

        // When
        let layout = config.makeLayout()

        // Then
        XCTAssertNotNil(layout)
    }

    @available(iOS 14.0, *)
    func test_list_layout_config_make_layout_sidebar_plain() {
        // Given
        let config = Config(appearance: .sidebarPlain)

        // When
        let layout = config.makeLayout()

        // Then
        XCTAssertNotNil(layout)
    }

    @available(iOS 14.0, *)
    func test_list_layout_config_with_separators_disabled() {
        // Given
        let config = Config(
            appearance: .plain,
            showsSeparators: false
        )

        // When
        let layout = config.makeLayout()

        // Then
        XCTAssertNotNil(layout)
    }

    @available(iOS 14.0, *)
    func test_list_layout_config_with_supplementary_header_and_footer() {
        // Given
        let config = Config(
            appearance: .grouped,
            headerMode: .supplementary,
            footerMode: .supplementary
        )

        // When
        let layout = config.makeLayout()

        // Then
        XCTAssertNotNil(layout)
    }

    @available(iOS 14.0, *)
    func test_list_layout_config_with_first_item_in_section_header() {
        // Given
        let config = Config(
            appearance: .plain,
            headerMode: .firstItemInSection
        )

        // When
        let layout = config.makeLayout()

        // Then
        XCTAssertNotNil(layout)
    }

    // MARK: - Setup Presenter with List Layout

    @available(iOS 14.0, *)
    func test_setup_presenter_with_list_layout() {
        // Given
        let config = Config(appearance: .insetGrouped)
        let cv = makeCollectionView(layoutKind: .list(config))

        // Then
        XCTAssertNotNil(cv.presenter)
        XCTAssertTrue(cv.collectionViewLayout is UICollectionViewCompositionalLayout)
    }

    @available(iOS 14.0, *)
    func test_setup_presenter_with_list_nil_config() {
        // Given — nil config, should keep existing layout
        let cv = makeCollectionView(layoutKind: .list(nil))

        // Then
        XCTAssertNotNil(cv.presenter)
    }

    @available(iOS 14.0, *)
    func test_list_layout_with_viewmodel() {
        // Given
        let config = Config(appearance: .plain)
        let cv = makeCollectionView(layoutKind: .list(config))

        // When
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(5), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        let attrs = sortedCellAttributes(cv)

        // Full container width
        for attr in attrs {
            XCTAssertEqual(attr.frame.width, 375, accuracy: 1)
        }

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 1)
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 5)
    }

    @available(iOS 14.0, *)
    func test_list_layout_with_diffable_data_source() {
        // Given
        let config = Config(
            appearance: .insetGrouped,
            showsSeparators: true,
            headerMode: .supplementary
        )
        let cv = makeCollectionView(layoutKind: .list(config), dataSourceMode: .diffable)

        // When
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.header(TestHeaderData(title: "Test"), viewType: TestHeaderView.self)
                builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertEqual(vm?.count, 1)
        XCTAssertEqual(vm?[0].count, 4)
        XCTAssertNotNil(vm?[0].header)
    }

    @available(iOS 14.0, *)
    func test_list_layout_multiple_sections() {
        // Given
        let config = Config(appearance: .grouped)
        let cv = makeCollectionView(layoutKind: .list(config))

        // When
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self) }
            builder.section { builder.cells(makeSampleBanners(4), cellType: TestBannerCell.self) }
        }
        cv.reloadData()

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 3)
    }

    // MARK: - Self-Sizing Cell Tests

    /// Short text vs long multi-line text should produce different cell heights
    /// because SelfSizingCell has no `size(with:constrainedTo:)` override
    /// and relies entirely on Auto Layout.
    @available(iOS 14.0, *)
    func test_self_sizing_cell_height_varies_with_content_length() {
        // Given
        let shortItem = VariableHeightItem(text: "Short")
        let longItem = VariableHeightItem(text: String(repeating: "Long text that wraps to multiple lines. ", count: 10))
        let config = Config(appearance: .plain)
        let cv = makeCollectionView(layoutKind: .list(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells([shortItem], cellType: SelfSizingCell.self)
                builder.cells([longItem], cellType: SelfSizingCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)
        XCTAssertEqual(attrs.count, 2, "Should have 2 cells")

        let shortHeight = attrs[0].frame.height
        let longHeight = attrs[1].frame.height

        // Then — the long-text cell must be taller than the short-text cell
        XCTAssertGreaterThan(shortHeight, 0, "Short cell should have positive height")
        XCTAssertGreaterThan(longHeight, shortHeight,
                             "Long multi-line text (\(longHeight)pt) should be taller than short text (\(shortHeight)pt)")
    }

    /// Verify that self-sizing cells span the full list width (minus insets).
    @available(iOS 14.0, *)
    func test_self_sizing_cell_width_matches_list_width() {
        // Given
        let items = [
            VariableHeightItem(text: "Hello"),
            VariableHeightItem(text: "World"),
        ]
        let config = Config(appearance: .plain)
        let cv = makeCollectionView(layoutKind: .list(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(items, cellType: SelfSizingCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)

        // Then — each cell should fill the container width (375pt for plain appearance)
        for attr in attrs {
            XCTAssertEqual(attr.frame.width, 375, accuracy: 1,
                           "Self-sizing cell should span full list width")
        }
    }

    /// Fixed-height cells should all have the same height regardless of content.
    @available(iOS 14.0, *)
    func test_fixed_height_cell_ignores_content_length() {
        // Given
        let shortItem = VariableHeightItem(text: "Short")
        let longItem = VariableHeightItem(text: String(repeating: "Very long text. ", count: 20))
        let config = Config(appearance: .plain)
        let cv = makeCollectionView(layoutKind: .list(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells([shortItem, longItem], cellType: FixedHeightCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)
        XCTAssertEqual(attrs.count, 2)

        // Then — both cells must be exactly 60pt via preferredLayoutAttributesFitting
        XCTAssertEqual(attrs[0].frame.height, FixedHeightCell.fixedHeight, accuracy: 1,
                       "Short-text cell should be fixed at \(FixedHeightCell.fixedHeight)pt")
        XCTAssertEqual(attrs[1].frame.height, FixedHeightCell.fixedHeight, accuracy: 1,
                       "Long-text cell should be fixed at \(FixedHeightCell.fixedHeight)pt")
    }

    /// Mix self-sizing and fixed-height cells in the same section.
    /// Self-sizing cell with long text should be taller than the fixed 60pt cell.
    @available(iOS 14.0, *)
    func test_mixed_self_sizing_and_fixed_height_in_same_list() {
        // Given
        let longText = String(repeating: "This is a long sentence that should wrap. ", count: 8)
        let config = Config(appearance: .plain)
        let cv = makeCollectionView(layoutKind: .list(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                // Self-sizing cell with long content
                builder.cells([VariableHeightItem(text: longText)], cellType: SelfSizingCell.self)
                // Fixed-height cell (always 60pt)
                builder.cells([VariableHeightItem(text: longText)], cellType: FixedHeightCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)
        XCTAssertEqual(attrs.count, 2)

        let selfSizingHeight = attrs[0].frame.height
        let fixedHeight = attrs[1].frame.height

        // Then — fixed cell is exactly 60pt, self-sizing cell with long text exceeds it
        XCTAssertEqual(fixedHeight, FixedHeightCell.fixedHeight, accuracy: 1,
                       "Fixed cell should be \(FixedHeightCell.fixedHeight)pt")
        XCTAssertGreaterThan(selfSizingHeight, fixedHeight,
                             "Self-sizing cell with long text (\(selfSizingHeight)pt) should exceed fixed \(fixedHeight)pt")
    }

    /// Self-sizing cells should be stacked vertically with no overlap.
    @available(iOS 14.0, *)
    func test_self_sizing_cells_stacked_vertically_without_overlap() {
        // Given
        let items = [
            VariableHeightItem(text: "First row"),
            VariableHeightItem(text: String(repeating: "Second row content. ", count: 6)),
            VariableHeightItem(text: "Third row"),
        ]
        let config = Config(appearance: .plain)
        let cv = makeCollectionView(layoutKind: .list(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(items, cellType: SelfSizingCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)
        XCTAssertEqual(attrs.count, 3)

        // Then — each cell's top should be >= previous cell's bottom (no vertical overlap)
        for i in 1..<attrs.count {
            let prevBottom = attrs[i - 1].frame.maxY
            let currentTop = attrs[i].frame.minY
            XCTAssertGreaterThanOrEqual(currentTop, prevBottom - 1,
                                         "Cell \(i) (y=\(currentTop)) should not overlap cell \(i-1) (bottom=\(prevBottom))")
        }
    }

    /// Three lines of text should produce a taller cell than one line.
    @available(iOS 14.0, *)
    func test_self_sizing_cell_three_lines_taller_than_one_line() {
        // Given — explicitly use newlines to guarantee line count
        let oneLine = VariableHeightItem(text: "Single line")
        let threeLines = VariableHeightItem(text: "Line one\nLine two\nLine three")
        let config = Config(appearance: .plain)
        let cv = makeCollectionView(layoutKind: .list(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells([oneLine, threeLines], cellType: SelfSizingCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)
        XCTAssertEqual(attrs.count, 2)

        // Then
        let oneLineHeight = attrs[0].frame.height
        let threeLinesHeight = attrs[1].frame.height
        XCTAssertGreaterThan(threeLinesHeight, oneLineHeight,
                             "3-line cell (\(threeLinesHeight)pt) should be taller than 1-line cell (\(oneLineHeight)pt)")
    }

    /// Content size should reflect the sum of all self-sizing cell heights.
    @available(iOS 14.0, *)
    func test_self_sizing_cells_content_size_reflects_total_height() {
        // Given
        let items = (0..<5).map { VariableHeightItem(text: "Item \($0): " + String(repeating: "text ", count: ($0 + 1) * 5)) }
        let config = Config(appearance: .plain)
        let cv = makeCollectionView(layoutKind: .list(config))

        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(items, cellType: SelfSizingCell.self)
            }
        }
        cv.reloadData()
        attachToWindow(cv)

        // When
        let attrs = sortedCellAttributes(cv)
        let sumOfHeights = attrs.reduce(CGFloat(0)) { $0 + $1.frame.height }
        let contentHeight = cv.contentSize.height

        // Then — content height should be at least the sum of all cell heights
        XCTAssertGreaterThanOrEqual(contentHeight, sumOfHeights,
                                     "Content height (\(contentHeight)) should be >= sum of cell heights (\(sumOfHeights))")
        // Items with progressively longer text should yield increasing heights
        for i in 1..<attrs.count {
            XCTAssertGreaterThanOrEqual(attrs[i].frame.height, attrs[i - 1].frame.height,
                                         "Cell \(i) should be >= cell \(i-1) in height (more text)")
        }
    }
}
