//
//  ReusableViewInfoTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class ReusableViewInfoTests: XCTestCase {
    // MARK: - ReusableViewInfo Stores Data

    func test_reusable_view_info_stores_content_data() {
        // Given
        let headerData = TestHeaderData(title: "Test Header")
        let headerInfo = SSCollectionViewModel.ReusableViewInfo(BindingStore<TestHeaderData, TestHeaderView>(state: headerData))

        // Then
        XCTAssertTrue(headerInfo.binderType == TestHeaderView.self)
    }

    func test_reusable_view_info_view_size() {
        // Given
        let headerData = TestHeaderData(title: "Test Header")
        let headerInfo = SSCollectionViewModel.ReusableViewInfo(BindingStore<TestHeaderData, TestHeaderView>(state: headerData))

        // When
        let size = headerInfo.size(constrainedTo: CGSize(width: 375, height: 667))

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 50))
    }

    func test_reusable_view_info_apply_binds_header_data() {
        // Given
        let headerData = TestHeaderData(title: "TestHeader")
        let info = SSCollectionViewModel.ReusableViewInfo(BindingStore<TestHeaderData, TestHeaderView>(state: headerData))
        let view = TestHeaderView()

        // When
        info.apply(to: view)

        // Then
        XCTAssertEqual(view.titleLabel.text, "TestHeader")
    }

    func test_reusable_view_info_apply_binds_footer_data() {
        // Given
        let footerData = TestFooterData(text: "TestFooter")
        let info = SSCollectionViewModel.ReusableViewInfo(BindingStore<TestFooterData, TestFooterView>(state: footerData))
        let view = TestFooterView()

        // When
        info.apply(to: view)

        // Then
        XCTAssertEqual(view.textLabel.text, "TestFooter")
    }

    func test_reusable_view_info_will_display_calls_view_method() {
        // Given
        let headerData = TestHeaderData(title: "Hello, World!")
        let info = SSCollectionViewModel.ReusableViewInfo(BindingStore<TestHeaderData, TestHeaderView>(state: headerData))
        let view = TestHeaderView()

        // When
        info.willDisplay(to: view)

        // Then
        XCTAssertTrue(view.willDisplayCalled)
    }

    func test_reusable_view_info_did_end_displaying_calls_view_method() {
        // Given
        let headerData = TestHeaderData(title: "Hello, SSCollectionViewPresenter!")
        let info = SSCollectionViewModel.ReusableViewInfo(BindingStore<TestHeaderData, TestHeaderView>(state: headerData))
        let view = TestHeaderView()

        // When
        info.didEndDisplaying(to: view)

        // Then
        XCTAssertTrue(view.didEndDisplayingCalled)
    }
}
