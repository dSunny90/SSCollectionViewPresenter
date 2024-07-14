//
//  ViewModelCollectionTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 11.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

@MainActor
final class ViewModelCollectionTests: XCTestCase {
    // MARK: - Collection Conformance

    func test_view_model_start_index_and_end_index() {
        // Given
        let sections = (0..<3).map { _ in
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)))
        }
        let vm = SSCollectionViewModel(sections: sections)

        // Then
        XCTAssertEqual(vm.startIndex, 0)
        XCTAssertEqual(vm.endIndex, 3)
    }

    func test_view_model_index_after_and_before() {
        // Given
        let sections = (0..<3).map { _ in
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(1)))
        }
        let vm = SSCollectionViewModel(sections: sections)

        // Then
        XCTAssertEqual(vm.index(after: 0), 1)
        XCTAssertEqual(vm.index(after: 1), 2)
        XCTAssertEqual(vm.index(before: 2), 1)
        XCTAssertEqual(vm.index(before: 1), 0)
    }

    func test_view_model_replace_subrange() {
        // Given
        let section0 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)), identifier: "안녕")
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(10)), identifier: "Hi")
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(8)), identifier: "!")
        var vm = SSCollectionViewModel(sections: [section0, section1, section2])
        let replacement = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(30)), identifier: "하세요")

        // When
        vm.replaceSubrange(1..<2, with: [replacement])

        // Then
        XCTAssertEqual(vm.count, 3)
        XCTAssertEqual(vm[0].identifier, "안녕")
        XCTAssertEqual(vm[1].identifier, "하세요")
        XCTAssertEqual(vm[1].count, 30)
        XCTAssertEqual(vm[2].identifier, "!")
    }

    func test_view_model_subscript_access() {
        // Given
        let sections = [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)), identifier: "first"),
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(5)), identifier: "second")
        ]
        let vm = SSCollectionViewModel(sections: sections)

        // Then
        XCTAssertEqual(vm[0].identifier, "first")
        XCTAssertEqual(vm[1].identifier, "second")
        XCTAssertEqual(vm[0].count, 3)
        XCTAssertEqual(vm[1].count, 5)
    }

    func test_view_model_iteration() {
        // Given
        let sections = (0..<4).map { i in
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(i + 1)), identifier: "s\(i)")
        }
        let vm = SSCollectionViewModel(sections: sections)

        // When
        var identifiers: [String] = []
        for section in vm {
            identifiers.append(section.identifier ?? "")
        }

        // Then
        XCTAssertEqual(identifiers, ["s0", "s1", "s2", "s3"])
    }

    func test_view_model_is_empty() {
        // Given
        let emptyVM = SSCollectionViewModel()
        let nonEmptyVM = SSCollectionViewModel(sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(1)))
        ])

        // Then
        XCTAssertTrue(emptyVM.isEmpty)
        XCTAssertFalse(nonEmptyVM.isEmpty)
    }

    // MARK: - Safe Subscript

    func test_safe_subscript_returns_nil_for_out_of_bounds() {
        // Given
        let array = [11, 30, 90]

        // Then
        XCTAssertEqual(array[safe: 0], 11)
        XCTAssertEqual(array[safe: 2], 90)
        XCTAssertNil(array[safe: 3])
        XCTAssertNil(array[safe: -1])
    }

    func test_safe_subscript_on_empty_collection() {
        // Given
        let empty: [Int] = []

        // Then
        XCTAssertNil(empty[safe: 0])
    }
}
