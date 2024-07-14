//
//  SectionControlTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 23.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class SectionControlTests: XCTestCase {
    // MARK: - Reconfigure Item/Header/Footer

    func test_reconfigure_item_updates_visible_cell() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()

        let banners = makeSampleBanners(3)
        _ = cv.ss.buildViewModel { builder in
            builder.section("reconfig") {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }

        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 1, section: 0)
        let cell = cv.cellForItem(at: indexPath) as? TestBannerCell
        XCTAssertEqual(cell?.titleLabel.text, banners[1].title)

        // When — reconfigure with updated state
        let updated = TestBanner(id: banners[1].id, title: "Updated Banner")
        cv.ss.reconfigureItem(updated, at: indexPath)

        // Then — cell should reflect new title
        XCTAssertEqual(cell?.titleLabel.text, "Updated Banner")
    }

    func test_reconfigure_header_and_footer_update_visible_views() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()

        let banners = makeSampleBanners(1)
        _ = cv.ss.buildViewModel { builder in
            builder.section("reconfig-supplementary") {
                builder.header(TestHeaderData(title: "Header-Old"), viewType: TestHeaderView.self)
                builder.footer(TestFooterData(text: "Footer-Old"), viewType: TestFooterView.self)
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }

        cv.reloadData()
        cv.layoutIfNeeded()

        let header = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? TestHeaderView
        let footer = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: 0)) as? TestFooterView
        XCTAssertEqual(header?.titleLabel.text, "Header-Old")
        XCTAssertEqual(footer?.textLabel.text, "Footer-Old")

        // When
        cv.ss.reconfigureHeader(TestHeaderData(title: "Header-New"), at: 0)
        cv.ss.reconfigureFooter(TestFooterData(text: "Footer-New"), at: 0)

        // Then
        XCTAssertEqual(header?.titleLabel.text, "Header-New")
        XCTAssertEqual(footer?.textLabel.text, "Footer-New")
    }

    // MARK: - toggleSection

    func test_toggleSection_call_manually_and_reconfigure_header() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()

        _ = cv.ss.buildViewModel { builder in
            builder.section("toggle") {
                builder.header(TestHeaderData(title: "expanded"), viewType: TestHeaderView.self)
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        cv.reloadData()
        cv.layoutIfNeeded()

        // Initially not collapsed
        XCTAssertEqual(cv.ss.getViewModel()?[0].isCollapsed, false)

        // When
        cv.ss.toggleSection(0) { collapsed in
            // Then
            XCTAssertEqual(cv.ss.getViewModel()?[0].isCollapsed, true)

            let title = collapsed ? "collapsed" : "expanded"

            let newState = TestHeaderData(title: title)
            cv.ss.reconfigureHeader(newState, at: 0)

            let aHeader = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? TestHeaderView
            XCTAssertEqual(aHeader?.ss.state()?.title, title)
        }
    }

    func test_toggleSection_in_action_closure_and_reconfigure_header() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setupPresenter()

        _ = cv.ss.buildViewModel { builder in
            builder.section("toggle") {
                builder.header(TestHeaderData(title: "expanded"), viewType: TestHeaderView.self) { section, view, action, input in
                    cv.ss.toggleSection(0) { collapsed in
                        // Then
                        XCTAssertEqual(cv.ss.getViewModel()?[0].isCollapsed, true)

                        let title = collapsed ? "collapsed" : "expanded"

                        let newState = TestHeaderData(title: title)
                        cv.ss.reconfigureHeader(newState, at: section)

                        let aHeader = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? TestHeaderView
                        XCTAssertEqual(aHeader?.ss.state()?.title, title)
                    }
                }
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }

        cv.reloadData()
        cv.layoutIfNeeded()

        // Initially not collapsed
        XCTAssertEqual(cv.ss.getViewModel()?[0].isCollapsed, false)

        // When
        let header = cv.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? TestHeaderView
        header?.actionClosure?("toggle", nil)

        // Then - toggleSection in completion closure
    }
}
