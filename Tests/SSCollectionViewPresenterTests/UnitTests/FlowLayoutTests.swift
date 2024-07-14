//
//  FlowLayoutTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class FlowLayoutTests: XCTestCase {
    // MARK: - Size For Item

    func test_flow_layout_size_for_item() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(11)
        _ = cv.ss.buildViewModel { builder in
            builder.section { builder.cells(banners, cellType: TestBannerCell.self) }
        }
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let indexPath = IndexPath(item: 0, section: 0)
        let size = cv.presenter?.collectionView(cv, layout: layout, sizeForItemAt: indexPath)

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 100))
    }

    // MARK: - Section Insets

    func test_flow_layout_section_insets() {
        // Given
        let cv = makeCollectionView()
        let cellInfos = makeCellInfos(from: makeSampleBanners(11))
        var section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        section.sectionInset = UIEdgeInsets(top: 11, left: 10, bottom: 19, right: 30)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let inset = cv.presenter?.collectionView(cv, layout: layout, insetForSectionAt: 0)

        // Then
        XCTAssertEqual(inset, UIEdgeInsets(top: 11, left: 10, bottom: 19, right: 30))
    }

    // MARK: - Minimum Line Spacing

    func test_flow_layout_minimum_line_spacing() {
        // Given
        let cv = makeCollectionView()
        let cellInfos = makeCellInfos(from: makeSampleBanners())
        var section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        section.minimumLineSpacing = 21
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let spacing = cv.presenter?.collectionView(cv, layout: layout, minimumLineSpacingForSectionAt: 0)

        // Then
        XCTAssertEqual(spacing, 21)
    }

    // MARK: - Minimum Interitem Spacing

    func test_flow_layout_minimum_interitem_spacing() {
        // Given
        let cv = makeCollectionView()
        let cellInfos = makeCellInfos(from: makeSampleBanners(11))
        var section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        section.minimumInteritemSpacing = 30
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let spacing = cv.presenter?.collectionView(cv, layout: layout, minimumInteritemSpacingForSectionAt: 0)

        // Then
        XCTAssertEqual(spacing, 30)
    }

    // MARK: - Header / Footer Size

    func test_flow_layout_header_size() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        section.setHeaderInfo(TestHeaderData(title: "Header"), viewType: TestHeaderView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let size = cv.presenter?.collectionView(cv, layout: layout, referenceSizeForHeaderInSection: 0)

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 50))
    }

    func test_flow_layout_footer_size() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        section.setFooterInfo(TestFooterData(text: "Footer"), viewType: TestFooterView.self)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let size = cv.presenter?.collectionView(cv, layout: layout, referenceSizeForFooterInSection: 0)

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 30))
    }

    // MARK: - Fallback Paths (nil ViewModel)

    func test_size_for_item_with_nil_view_model_returns_flow_layout_default() {
        // Given
        let cv = makeCollectionView()
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = CGSize(width: 119, height: 59)

        // When
        let size = cv.presenter?.collectionView(cv, layout: flowLayout, sizeForItemAt: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertEqual(size, CGSize(width: 119, height: 59))
    }

    func test_size_for_item_with_non_flow_layout_returns_zero() {
        // Given
        let cv = makeCollectionView()
        let nonFlowLayout = UICollectionViewLayout()

        // When
        let size = cv.presenter?.collectionView(cv, layout: nonFlowLayout, sizeForItemAt: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertEqual(size, .zero)
    }

    func test_inset_for_section_with_nil_view_model_returns_flow_layout_default() {
        // Given
        let cv = makeCollectionView()
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.sectionInset = UIEdgeInsets(top: 23, left: 29, bottom: 31, right: 37)

        // When
        let inset = cv.presenter?.collectionView(cv, layout: flowLayout, insetForSectionAt: 0)

        // Then
        XCTAssertEqual(inset, UIEdgeInsets(top: 23, left: 29, bottom: 31, right: 37))
    }

    func test_minimum_line_spacing_with_nil_view_model_returns_flow_layout_default() {
        // Given
        let cv = makeCollectionView()
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.minimumLineSpacing = 41

        // When
        let spacing = cv.presenter?.collectionView(cv, layout: flowLayout, minimumLineSpacingForSectionAt: 0)

        // Then
        XCTAssertEqual(spacing, 41)
    }

    func test_header_size_with_nil_view_model_returns_flow_layout_default() {
        // Given
        let cv = makeCollectionView()
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.headerReferenceSize = CGSize(width: 375, height: 60)

        // When
        let size = cv.presenter?.collectionView(cv, layout: flowLayout, referenceSizeForHeaderInSection: 0)

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 60))
    }

    func test_footer_size_with_non_flow_layout_returns_zero() {
        // Given
        let cv = makeCollectionView()
        let nonFlowLayout = UICollectionViewLayout()

        // When
        let size = cv.presenter?.collectionView(cv, layout: nonFlowLayout, referenceSizeForFooterInSection: 0)

        // Then
        XCTAssertEqual(size, .zero)
    }

    // MARK: - Section Insets Nil Fallback

    func test_section_insets_nil_falls_back_to_flow_layout_default() {
        // Given
        let cv = makeCollectionView()
        let cellInfos = makeCellInfos(from: makeSampleBanners(3))
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)

        // When — section has no custom insets
        let inset = cv.presenter?.collectionView(cv, layout: flowLayout, insetForSectionAt: 0)

        // Then
        XCTAssertEqual(inset, UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
    }
}
