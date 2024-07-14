//
//  CellLifecycleTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class CellLifecycleTests: XCTestCase {
    // MARK: - willDisplay / didEndDisplaying (Cell)

    func test_will_display_cell_calls_lifecycle_method() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let cell = TestBannerCell()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(cv, willDisplay: cell, forItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.willDisplayCalled)
    }

    func test_will_display_cell_with_nil_view_model_is_no_op() {
        // Given
        let cv = makeCollectionView()
        let cell = TestBannerCell()

        // When — no viewModel set, should not crash
        cv.presenter?.collectionView(cv, willDisplay: cell, forItemAt: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertFalse(cell.willDisplayCalled)
    }

    func test_did_end_displaying_cell_calls_lifecycle_method() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()

        let cell = TestBannerCell()
        let indexPath = IndexPath(item: 1, section: 0)

        // When
        cv.presenter?.collectionView(cv, didEndDisplaying: cell, forItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didEndDisplayingCalled)
    }

    // MARK: - willDisplay / didEndDisplaying (Supplementary)

    func test_will_display_supplementary_view_header() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setHeaderInfo(TestHeaderData(title: "Header"), viewType: TestHeaderView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let headerView = TestHeaderView()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(
            cv, willDisplaySupplementaryView: headerView,
            forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath
        )

        // Then
        XCTAssertTrue(headerView.willDisplayCalled)
    }

    func test_will_display_supplementary_view_footer() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setFooterInfo(TestFooterData(text: "Footer"), viewType: TestFooterView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let footerView = TestFooterView()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(
            cv, willDisplaySupplementaryView: footerView,
            forElementKind: UICollectionView.elementKindSectionFooter, at: indexPath
        )

        // Then
        XCTAssertTrue(footerView.willDisplayCalled)
    }

    func test_did_end_displaying_supplementary_view_header() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setHeaderInfo(TestHeaderData(title: "Header"), viewType: TestHeaderView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let headerView = TestHeaderView()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(
            cv, didEndDisplayingSupplementaryView: headerView,
            forElementOfKind: UICollectionView.elementKindSectionHeader, at: indexPath
        )

        // Then
        XCTAssertTrue(headerView.didEndDisplayingCalled)
    }

    func test_did_end_displaying_supplementary_view_footer() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setFooterInfo(TestFooterData(text: "Footer"), viewType: TestFooterView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let footerView = TestFooterView()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(
            cv, didEndDisplayingSupplementaryView: footerView,
            forElementOfKind: UICollectionView.elementKindSectionFooter, at: indexPath
        )

        // Then
        XCTAssertTrue(footerView.didEndDisplayingCalled)
    }

    func test_will_display_supplementary_view_unknown_kind_is_no_op() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setHeaderInfo(TestHeaderData(title: "Header"), viewType: TestHeaderView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))

        let headerView = TestHeaderView()

        // When — unknown element kind should be a no-op
        cv.presenter?.collectionView(
            cv, willDisplaySupplementaryView: headerView,
            forElementKind: "UnknownKind", at: IndexPath(item: 0, section: 0)
        )

        // Then
        XCTAssertFalse(headerView.willDisplayCalled)
    }

    // MARK: - Infinite Page Lifecycle

    func test_will_display_cell_with_infinite_page_middle_range() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isInfinitePage: true))
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()

        let cell = TestBannerCell()
        let indexPath = IndexPath(item: 7, section: 0)

        // When
        cv.presenter?.collectionView(cv, willDisplay: cell, forItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.willDisplayCalled)
    }

    func test_did_end_displaying_cell_with_infinite_page() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(SSCollectionViewPresenter.PagingConfiguration(isInfinitePage: true))
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()

        let cell = TestBannerCell()
        let indexPath = IndexPath(item: 8, section: 0)

        // When
        cv.presenter?.collectionView(cv, didEndDisplaying: cell, forItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didEndDisplayingCalled)
    }

    // MARK: - Should Highlight / Select / Deselect

    func test_should_highlight_returns_true_by_default() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        let shouldHighlight = cv.presenter?.collectionView(cv, shouldHighlightItemAt: indexPath)

        // Then
        XCTAssertTrue(shouldHighlight ?? false)
    }

    func test_should_select_returns_true_by_default() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        let shouldSelect = cv.presenter?.collectionView(cv, shouldSelectItemAt: indexPath)

        // Then
        XCTAssertTrue(shouldSelect ?? false)
    }

    func test_should_deselect_returns_true_by_default() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        let shouldDeselect = cv.presenter?.collectionView(cv, shouldDeselectItemAt: indexPath)

        // Then
        XCTAssertTrue(shouldDeselect ?? false)
    }

    // MARK: - Highlight / Select

    func test_did_select_item_calls_cell_method() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        guard let cell = cv.cellForItem(at: indexPath) as? TestBannerCell else {
            return
        }
        cv.presenter?.collectionView(cv, didSelectItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didSelectCalled)
    }

    func test_did_deselect_item_calls_cell_method() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        guard let cell = cv.cellForItem(at: indexPath) as? TestBannerCell else { return }
        cv.presenter?.collectionView(cv, didDeselectItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didDeselectCalled)
    }

    func test_did_highlight_item_calls_cell_method() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        guard let cell = cv.cellForItem(at: indexPath) as? TestBannerCell else { return }
        cv.presenter?.collectionView(cv, didHighlightItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didHighlightCalled)
    }

    func test_did_unhighlight_item_calls_cell_method() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        guard let cell = cv.cellForItem(at: indexPath) as? TestBannerCell else { return }
        cv.presenter?.collectionView(cv, didUnhighlightItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didUnhighlightCalled)
    }

    func test_did_select_with_nil_view_model_is_no_op() {
        // Given
        let cv = makeCollectionView()

        // When — no viewModel set, should not crash
        cv.presenter?.collectionView(cv, didSelectItemAt: IndexPath(item: 0, section: 0))

        // Then — no crash is the assertion
    }

    func test_did_select_with_out_of_bounds_is_no_op() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(makeSampleBanners(), cellType: TestBannerCell.self) }
        }

        // When — out of bounds section, should not crash
        cv.presenter?.collectionView(cv, didSelectItemAt: IndexPath(item: 0, section: 2))

        // Then — no crash is the assertion
    }
}
