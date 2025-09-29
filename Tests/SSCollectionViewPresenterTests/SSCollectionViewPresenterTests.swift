//
//  SSCollectionViewPresenterTests.swift
//  SSCollectionViewPresenterTests
//
//  Created by SunSoo Jeon on 19.08.2023.
//

import XCTest
@testable import SSCollectionViewPresenter

import UIKit

// MARK: - Test Fixtures

struct TestBanner: Decodable, Sendable {
    let id: String
    let title: String
}

struct TestBannerCellModel: Boundable {
    var contentData: TestBanner?
    var binderType: TestBannerCell.Type { TestBannerCell.self }
}

final class TestBannerCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    let titleLabel = UILabel()
    var didSelectCalled = false
    var didDeselectCalled = false
    var didHighlightCalled = false
    var didUnhighlightCalled = false
    var willDisplayCalled = false
    var didEndDisplayingCalled = false

    static func size(with input: TestBanner?, constrainedTo parentSize: CGSize?) -> CGSize? {
        return CGSize(width: 375, height: 100)
    }

    var configurer: (TestBannerCell, TestBanner) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }

    func didSelect(with input: TestBanner?) {
        didSelectCalled = true
    }

    func didDeselect(with input: TestBanner?) {
        didDeselectCalled = true
    }

    func didHighlight(with input: TestBanner?) {
        didHighlightCalled = true
    }

    func didUnhighlight(with input: TestBanner?) {
        didUnhighlightCalled = true
    }

    func willDisplay(with input: TestBanner?) {
        willDisplayCalled = true
    }

    func didEndDisplaying(with input: TestBanner?) {
        didEndDisplayingCalled = true
    }
}

struct TestHeaderData: Sendable {
    let title: String
}

struct TestHeaderViewModel: Boundable {
    var contentData: TestHeaderData?
    var binderType: TestHeaderView.Type { TestHeaderView.self }
}

final class TestHeaderView: UICollectionReusableView, SSCollectionReusableViewProtocol {
    let titleLabel = UILabel()
    var willDisplayCalled = false
    var didEndDisplayingCalled = false

    static func size(with input: TestHeaderData?, constrainedTo parentSize: CGSize?) -> CGSize? {
        return CGSize(width: parentSize?.width ?? 375, height: 50)
    }

    var configurer: (TestHeaderView, TestHeaderData) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }

    func willDisplay(with input: TestHeaderData?) {
        willDisplayCalled = true
    }

    func didEndDisplaying(with input: TestHeaderData?) {
        didEndDisplayingCalled = true
    }
}

struct TestFooterData: Sendable {
    let text: String
}

struct TestFooterViewModel: Boundable {
    var contentData: TestFooterData?
    var binderType: TestFooterView.Type { TestFooterView.self }
}

final class TestFooterView: UICollectionReusableView, SSCollectionReusableViewProtocol {
    let textLabel = UILabel()
    var willDisplayCalled = false
    var didEndDisplayingCalled = false

    static func size(with input: TestFooterData?, constrainedTo parentSize: CGSize?) -> CGSize? {
        return CGSize(width: parentSize?.width ?? 375, height: 30)
    }

    var configurer: (TestFooterView, TestFooterData) -> Void {
        { view, model in
            view.textLabel.text = model.text
        }
    }

    func willDisplay(with input: TestFooterData?) {
        willDisplayCalled = true
    }

    func didEndDisplaying(with input: TestFooterData?) {
        didEndDisplayingCalled = true
    }
}

// MARK: - Helpers

@MainActor
private func makeCollectionView(
    frame: CGRect = CGRect(x: 0, y: 0, width: 375, height: 667),
    layoutKind: SSCollectionViewPresenter.LayoutKind = .flow,
    dataSourceMode: SSCollectionViewPresenter.DataSourceMode = .traditional
) -> UICollectionView {
    let cv = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
    cv.ss.setupPresenter(layoutKind: layoutKind, dataSourceMode: dataSourceMode)
    return cv
}

@MainActor
private func makeSampleBanners(_ count: Int = 8) -> [TestBanner] {
    (0..<count).map { TestBanner(id: "\($0)", title: "Banner \($0)") }
}

@MainActor
private func makeCellInfo(from banner: TestBanner) -> SSCollectionViewModel.CellInfo {
    SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))
}

@MainActor
private func makeCellInfos(from banners: [TestBanner]) -> [SSCollectionViewModel.CellInfo] {
    banners.map { makeCellInfo(from: $0) }
}

// MARK: - Tests

@MainActor
class SSCollectionViewPresenterTests: XCTestCase {

    // MARK: - Setup & ViewModel Basics

    func testSetupPresenterCreatesPresenter() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertNotNil(cv.presenter, "Presenter should be attached after setupPresenter()")
    }

    func testGetViewModelReturnsNilBeforeSetting() {
        // Given
        let cv = makeCollectionView()

        // Then
        XCTAssertNil(cv.ss.getViewModel(), "ViewModel should be nil before setting")
    }

    func testSetViewModelAndGetViewModel() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        let cellInfos = makeCellInfos(from: banners)
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        let viewModel = SSCollectionViewModel(sections: [section])

        // When
        cv.ss.setViewModel(with: viewModel)

        // Then
        let retrieved = cv.ss.getViewModel()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.count, 1, "Should have 1 section")
        XCTAssertEqual(retrieved?[0].count, 8, "Section should have 8 items (default)")
    }

    // MARK: - DataSource: numberOfSections / numberOfItemsInSection

    func testNumberOfSectionsMatchesViewModel() {
        // Given
        let cv = makeCollectionView()
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(23)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let viewModel = SSCollectionViewModel(sections: [section1, section2])

        // When
        cv.ss.setViewModel(with: viewModel)
        cv.reloadData()

        // Then
        let sectionCount = cv.dataSource?.numberOfSections?(in: cv)
        XCTAssertEqual(sectionCount, 2)
    }

    func testNumberOfItemsInSectionMatchesCellCount() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(10)
        let cellInfos = makeCellInfos(from: banners)
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let itemCount = cv.dataSource?.collectionView(cv, numberOfItemsInSection: 0)

        // Then
        XCTAssertEqual(itemCount, 10)
    }

    func testNumberOfItemsReturnsZeroWithNoViewModel() {
        // Given
        let cv = makeCollectionView()
        cv.reloadData()

        // When
        let sectionCount = cv.dataSource?.numberOfSections?(in: cv)

        // Then
        XCTAssertEqual(sectionCount, 0)
    }

    // MARK: - CellForItemAt & Data Binding

    func testCellForItemAtDequeuesCorrectCell() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        let cellInfos = makeCellInfos(from: banners)
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let indexPath = IndexPath(item: 0, section: 0)
        let cell = cv.dataSource?.collectionView(cv, cellForItemAt: indexPath)

        // Then
        XCTAssertTrue(cell is TestBannerCell, "Should dequeue a TestBannerCell")
    }

    func testCellDataBindingAppliesToCell() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        let cellInfos = makeCellInfos(from: banners)
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let indexPath = IndexPath(item: 1, section: 0)
        guard let cell = cv.dataSource?.collectionView(cv, cellForItemAt: indexPath) as? TestBannerCell else {
            XCTFail("Failed to dequeue TestBannerCell")
            return
        }

        // Then
        XCTAssertEqual(cell.titleLabel.text, "Banner 1")
    }

    // MARK: - Builder Pattern

    func testBuildViewModelCreatesCorrectStructure() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(7)

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section("TestSection") {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }

        // Then
        XCTAssertEqual(result.count, 1, "Should have 1 section")
        XCTAssertEqual(result[0].count, 7, "Section should have 7 items")
        XCTAssertEqual(result[0].identifier, "TestSection")
    }

    func testBuildViewModelWithMultipleSections() {
        // Given
        let cv = makeCollectionView()
        let group1 = makeSampleBanners(5)
        let group2 = makeSampleBanners(10)

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section("Alpha") {
                builder.cells(models: group1, viewModel: TestBannerCellModel())
            }
            builder.section("Beta") {
                builder.cells(models: group2, viewModel: TestBannerCellModel())
            }
        }

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].count, 5)
        XCTAssertEqual(result[1].count, 10)
    }

    func testBuildViewModelSingleCell() {
        // Given
        let cv = makeCollectionView()
        let banner = TestBanner(id: "429", title: "TestTitle")

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cell(model: banner, viewModel: TestBannerCellModel())
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 1)
    }

    func testBuildViewModelWithHeaderAndFooter() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(5)
        let headerData = TestHeaderData(title: "Section Header")
        let footerData = TestFooterData(text: "Section Footer")

        // When
        let result = cv.ss.buildViewModel { builder in
            builder.section("withSupplementary") {
                builder.header(model: headerData, viewModel: TestHeaderViewModel())
                builder.footer(model: footerData, viewModel: TestFooterViewModel())
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 5)
        XCTAssertNotNil(result[0].headerInfo())
        XCTAssertNotNil(result[0].footerInfo())
    }

    func testBuildViewModelSetsPageAndHasNext() {
        // Given
        let cv = makeCollectionView()

        // When
        let result = cv.ss.buildViewModel(page: 3, hasNext: true) { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(1), viewModel: TestBannerCellModel())
            }
        }

        // Then
        XCTAssertEqual(result.page, 3)
        XCTAssertTrue(result.hasNext)
    }

    // MARK: - ExtendViewModel

    func testExtendViewModelAppendsToExistingSection() {
        // Given
        let cv = makeCollectionView()

        _ = cv.ss.buildViewModel { builder in
            builder.section("Korea") {
                builder.cells(models: makeSampleBanners(4), viewModel: TestBannerCellModel())
            }
        }

        // When
        let extended = cv.ss.extendViewModel(page: 1, hasNext: false) { builder in
            builder.section("Korea") {
                builder.cells(models: makeSampleBanners(7), viewModel: TestBannerCellModel())
            }
        }

        // Then
        XCTAssertEqual(extended.count, 1, "Should still be 1 section")
        XCTAssertEqual(extended[0].count, 11, "Should have 4 + 7 = 11 items")
        XCTAssertEqual(extended.page, 1)
        XCTAssertFalse(extended.hasNext)
    }

    func testExtendViewModelAddsNewSection() {
        // Given
        let cv = makeCollectionView()

        _ = cv.ss.buildViewModel { builder in
            builder.section("Banners") {
                builder.cells(models: makeSampleBanners(11), viewModel: TestBannerCellModel())
            }
        }

        // When
        let extended = cv.ss.extendViewModel { builder in
            builder.section("NewSection") {
                builder.cells(models: makeSampleBanners(19), viewModel: TestBannerCellModel())
            }
        }

        // Then
        XCTAssertEqual(extended.count, 2, "Should have 2 sections")
        XCTAssertEqual(extended[0].count, 11)
        XCTAssertEqual(extended[1].count, 19)
    }

    // MARK: - SSCollectionViewModel

    func testViewModelDefaultValues() {
        // When
        let vm = SSCollectionViewModel()

        // Then
        XCTAssertEqual(vm.page, 0)
        XCTAssertFalse(vm.hasNext)
        XCTAssertTrue(vm.isEmpty)
    }

    func testViewModelSectionInfoAccess() {
        // Given
        let cellInfos = makeCellInfos(from: makeSampleBanners(7))
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos, identifier: "test")
        let vm = SSCollectionViewModel(sections: [section], page: 1, hasNext: true)

        // Then
        XCTAssertEqual(vm.count, 1)
        XCTAssertEqual(vm.page, 1)
        XCTAssertTrue(vm.hasNext)
        XCTAssertNotNil(vm.sectionInfo(at: 0))
        XCTAssertNil(vm.sectionInfo(at: 2), "Out of bounds should return nil")
    }

    func testViewModelPlusOperator() {
        // Given
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(23)))
        let vm1 = SSCollectionViewModel(sections: [section1])
        let vm2 = SSCollectionViewModel(sections: [section2])

        // When
        let combined = vm1 + vm2

        // Then
        XCTAssertEqual(combined.count, 2)
    }

    func testViewModelPlusEqualOperator() {
        // Given
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(30)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(44)))
        var vm = SSCollectionViewModel(sections: [section1])

        // When
        vm += SSCollectionViewModel(sections: [section2])

        // Then
        XCTAssertEqual(vm.count, 2)
    }

    func testViewModelPlusSectionInfo() {
        // Given
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(53)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(59)))
        let vm = SSCollectionViewModel(sections: [section1])

        // When
        let result = vm + section2

        // Then
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - SectionInfo

    func testSectionInfoDefaultInit() {
        // When
        let section = SSCollectionViewModel.SectionInfo()

        // Then
        XCTAssertTrue(section.isEmpty)
        XCTAssertNil(section.identifier)
        XCTAssertNil(section.headerInfo())
        XCTAssertNil(section.footerInfo())
    }

    func testSectionInfoCellInfoAccess() {
        // Given
        let cellInfos = makeCellInfos(from: makeSampleBanners(63))
        let section = SSCollectionViewModel.SectionInfo(items: cellInfos)

        // Then
        XCTAssertEqual(section.count, 63)
        XCTAssertNotNil(section.cellInfo(at: 0))
        XCTAssertNotNil(section.cellInfo(at: 2))
        XCTAssertNil(section.cellInfo(at: 64), "Out of bounds should return nil")
    }

    func testSectionInfoAppendCellInfo() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(1)))
        let newBanner = TestBanner(id: "1235", title: "NewBanner")

        // When
        section.appendCellInfo(model: newBanner, viewModel: TestBannerCellModel())

        // Then
        XCTAssertEqual(section.count, 2)
    }

    func testSectionInfoInsertCellInfo() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)))
        let inserted = TestBanner(id: "1233", title: "MiddleBanner")

        // When
        section.insertCellInfo(at: 1, model: inserted, viewModel: TestBannerCellModel())

        // Then
        XCTAssertEqual(section.count, 3)
    }

    func testSectionInfoInsertCellInfoOutOfRange() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let banner = TestBanner(id: "1243", title: "InvalidBanner")

        // When
        section.insertCellInfo(at: 19, model: banner, viewModel: TestBannerCellModel())

        // Then
        XCTAssertEqual(section.count, 11, "Out of range insert should be a no-op")
    }

    func testSectionInfoUpdateCellInfo() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(30)))
        let updated = TestBanner(id: "1130", title: "UpdatedBanner")

        // When
        section.updateCellInfo(at: 0, model: updated, viewModel: TestBannerCellModel())

        // Then
        XCTAssertEqual(section.count, 30, "Count should remain the same")
    }

    func testSectionInfoUpdateCellInfoOutOfBounds() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let banner = TestBanner(id: "1231", title: "InvalidBanner")

        // When
        section.updateCellInfo(at: 19, model: banner, viewModel: TestBannerCellModel())

        // Then
        XCTAssertEqual(section.count, 11, "Out of bounds update should be a no-op")
    }

    func testSectionInfoUpsertUpdatesExisting() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        let upserted = TestBanner(id: "1331", title: "UpsertTest1")

        // When
        section.upsertCellInfo(at: 0, model: upserted, viewModel: TestBannerCellModel())

        // Then
        XCTAssertEqual(section.count, 11, "Should update in place")
    }

    func testSectionInfoUpsertAppendsAtEnd() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(58)))
        let upserted = TestBanner(id: "1442", title: "UpsertTest2")

        // When
        section.upsertCellInfo(at: 58, model: upserted, viewModel: TestBannerCellModel())

        // Then
        XCTAssertEqual(section.count, 59, "Should append at endIndex")
    }

    func testSectionInfoUpsertOutOfRange() {
        // Given
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(63)))
        let banner = TestBanner(id: "1660", title: "InvalidBanner")

        // When
        section.upsertCellInfo(at: 64, model: banner, viewModel: TestBannerCellModel())

        // Then
        XCTAssertEqual(section.count, 63, "Out of range upsert should be a no-op")
    }

    func testSectionInfoSetHeader() {
        // Given
        var section = SSCollectionViewModel.SectionInfo()
        XCTAssertNil(section.headerInfo())

        // When
        section.setHeaderInfo(model: TestHeaderData(title: "Header"), viewModel: TestHeaderViewModel())

        // Then
        XCTAssertNotNil(section.headerInfo())
    }

    func testSectionInfoSetFooter() {
        // Given
        var section = SSCollectionViewModel.SectionInfo()
        XCTAssertNil(section.footerInfo())

        // When
        section.setFooterInfo(model: TestFooterData(text: "Footer"), viewModel: TestFooterViewModel())

        // Then
        XCTAssertNotNil(section.footerInfo())
    }

    func testSectionInfoPlusOperator() {
        // Given
        let section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(30)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(44)))

        // When
        let combined = section1 + section2

        // Then
        XCTAssertEqual(combined.count, 74)
    }

    func testSectionInfoFlowLayoutOptions() {
        // Given
        var section = SSCollectionViewModel.SectionInfo()
        XCTAssertNil(section.sectionInsets)
        XCTAssertNil(section.minimumLineSpacing)
        XCTAssertNil(section.minimumInteritemSpacing)

        // When
        section.sectionInsets = UIEdgeInsets(top: 11, left: 13, bottom: 17, right: 19)
        section.minimumLineSpacing = 23
        section.minimumInteritemSpacing = 29

        // Then
        XCTAssertEqual(section.sectionInsets, UIEdgeInsets(top: 11, left: 13, bottom: 17, right: 19))
        XCTAssertEqual(section.minimumLineSpacing, 23)
        XCTAssertEqual(section.minimumInteritemSpacing, 29)
    }

    // MARK: - CellInfo

    func testCellInfoStoresContentData() {
        // Given
        let banner = TestBanner(id: "523", title: "Hello, World!")
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))

        // Then
        XCTAssertNotNil(cellInfo.contentData)
        XCTAssertTrue(cellInfo.binderType == TestBannerCell.self)
    }

    func testCellInfoItemSize() {
        // Given
        let banner = TestBanner(id: "644", title: "Hello, SSCollectionViewPresenter!")
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))

        // When
        let size = cellInfo.itemSize(constrainedTo: CGSize(width: 375, height: 200))

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 100))
    }

    func testCellInfoItemSizeReturnsNilWithoutContentData() {
        // Given
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: nil))

        // When
        let size = cellInfo.itemSize(constrainedTo: CGSize(width: 375, height: 200))

        // Then
        XCTAssertNil(size, "Should return nil when contentData is nil")
    }

    func testCellInfoHashable() {
        // Given
        let banner = TestBanner(id: "777", title: "Hello, Swift!")
        let cellInfo1 = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))
        let cellInfo2 = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))

        // Then
        XCTAssertNotEqual(cellInfo1, cellInfo2, "Each CellInfo should have a unique UUID")
        XCTAssertEqual(cellInfo1, cellInfo1, "Same instance should be equal")
    }

    // MARK: - ReusableViewInfo

    func testReusableViewInfoStoresContentData() {
        // Given
        let headerData = TestHeaderData(title: "Test Header")
        let info = SSCollectionViewModel.ReusableViewInfo(TestHeaderViewModel(contentData: headerData))

        // Then
        XCTAssertNotNil(info.contentData)
        XCTAssertTrue(info.binderType == TestHeaderView.self)
    }

    func testReusableViewInfoViewSize() {
        // Given
        let headerData = TestHeaderData(title: "Test Header")
        let info = SSCollectionViewModel.ReusableViewInfo(TestHeaderViewModel(contentData: headerData))

        // When
        let size = info.viewSize(constrainedTo: CGSize(width: 375, height: 667))

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 50))
    }

    // MARK: - Granular Item Operations via `ss.*`

    func testAppendItemToSection() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(59), viewModel: TestBannerCellModel())
            }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "815", title: "NewCell"))

        // When
        cv.ss.appendItem(newItem, toSection: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 60)
    }

    func testAppendItemToInvalidSection() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(63), viewModel: TestBannerCellModel())
            }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "830", title: "NewCell"))

        // When
        cv.ss.appendItem(newItem, toSection: 119)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 63, "Should be unchanged")
    }

    func testAppendItemsToSection() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(1), viewModel: TestBannerCellModel())
            }
        }
        let newItems = makeCellInfos(from: makeSampleBanners(19))

        // When
        cv.ss.appendItems(contentsOf: newItems, toSection: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 20)
    }

    func testAppendItemBySectionIdentifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Apple") {
                builder.cells(models: makeSampleBanners(7), viewModel: TestBannerCellModel())
            }
            builder.section("Banana") {
                builder.cells(models: makeSampleBanners(9), viewModel: TestBannerCellModel())
            }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "1713", title: "Google"))

        // When
        cv.ss.appendItem(newItem, firstSectionIdentifier: "Apple")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 8, "Apple section should grow")
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 9, "Banana section unchanged")
    }

    func testAppendItemToLastSection() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Swift") {
                builder.cells(models: makeSampleBanners(9), viewModel: TestBannerCellModel())
            }
            builder.section("Objective-C") {
                builder.cells(models: makeSampleBanners(16), viewModel: TestBannerCellModel())
            }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "1818", title: "Block"))

        // When
        cv.ss.appendItemToLastSection(newItem)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 9, "Swift section unchanged")
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 17, "Objective-C section should grow")
    }

    func testInsertItem() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(), viewModel: TestBannerCellModel())
            }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "1919", title: "TestItem"))

        // When
        cv.ss.insertItem(newItem, at: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 9)
    }

    func testInsertItemOutOfBounds() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(), viewModel: TestBannerCellModel())
            }
        }
        let newItem = makeCellInfo(from: TestBanner(id: "1990", title: "InvalidItem"))

        // When
        cv.ss.insertItem(newItem, at: IndexPath(item: 11, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 8, "Out of bounds insert should be a no-op")
    }

    func testInsertMultipleItems() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(), viewModel: TestBannerCellModel())
            }
        }
        let newItems = makeCellInfos(from: makeSampleBanners(11))

        // When
        cv.ss.insertItems(newItems, at: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 19)
    }

    func testUpdateItem() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(), viewModel: TestBannerCellModel())
            }
        }
        let updated = makeCellInfo(from: TestBanner(id: "1994", title: "InvalidItem"))

        // When
        cv.ss.updateItem(updated, at: IndexPath(item: 1, section: 0))

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertEqual(vm?[0].count, 8, "Count should remain the same")
    }

    func testUpdateItemBySectionIdentifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Favorite") {
                builder.cells(models: makeSampleBanners(9), viewModel: TestBannerCellModel())
            }
        }
        let updated = makeCellInfo(from: TestBanner(id: "2025", title: "ValidItem"))

        // When
        cv.ss.updateItem(updated, atRow: 0, firstSectionIdentifier: "Favorite")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 9, "Count should remain the same")
    }

    func testDeleteItem() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(63), viewModel: TestBannerCellModel())
            }
        }

        // When
        cv.ss.deleteItem(at: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 62)
    }

    func testDeleteItemOutOfBounds() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(71), viewModel: TestBannerCellModel())
            }
        }

        // When
        cv.ss.deleteItem(at: IndexPath(item: 75, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 71, "Should be unchanged")
    }

    func testDeleteMultipleItems() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(11), viewModel: TestBannerCellModel())
            }
        }

        // When
        cv.ss.deleteItems(at: [
            IndexPath(item: 0, section: 0),
            IndexPath(item: 2, section: 0),
            IndexPath(item: 4, section: 0)
        ])

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 8)
    }

    func testDeleteAllItemsInSection() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(30), viewModel: TestBannerCellModel())
            }
        }

        // When
        cv.ss.deleteAllItems(inSection: 0)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 0)
    }

    func testDeleteAllItemsBySectionIdentifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Mine") {
                builder.cells(models: makeSampleBanners(37), viewModel: TestBannerCellModel())
            }
            builder.section("Yours") {
                builder.cells(models: makeSampleBanners(74), viewModel: TestBannerCellModel())
            }
        }

        // When
        cv.ss.deleteAllItems(firstSectionIdentifier: "Mine")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 0, "Mine should be empty")
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 74, "Yours should be unchanged")
    }

    func testDeleteItemBySectionIdentifier() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("TestSection") {
                builder.cells(models: makeSampleBanners(70), viewModel: TestBannerCellModel())
            }
        }

        // When
        cv.ss.deleteItem(atRow: 1, firstSectionIdentifier: "TestSection")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 69)
    }

    // MARK: - Section Operations

    func testAppendSection() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(11), viewModel: TestBannerCellModel())
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

    func testAppendMultipleSections() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(11), viewModel: TestBannerCellModel())
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

    // MARK: - Pagination

    func testOnNextRequestIsStored() {
        // Given
        let cv = makeCollectionView()
        var callbackInvoked = false

        // When
        cv.ss.onNextRequest { _ in
            callbackInvoked = true
        }

        let vm = SSCollectionViewModel(sections: [], hasNext: true)
        cv.ss.setViewModel(with: vm)
        cv.presenter?.nextRequestBlock?(vm)

        // Then
        XCTAssertTrue(callbackInvoked)
    }

    func testViewModelHasNextFlag() {
        // Given
        let cv = makeCollectionView()

        // When
        cv.ss.buildViewModel(page: 0, hasNext: true) { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(11), viewModel: TestBannerCellModel())
            }
        }

        // Then
        let vm = cv.ss.getViewModel()
        XCTAssertTrue(vm?.hasNext ?? false)
        XCTAssertEqual(vm?.page, 0)
    }

    // MARK: - Paging Configuration

    func testSetPagingEnabledConfiguresPresenter() {
        // Given
        let cv = makeCollectionView()

        // When
        cv.ss.setPagingEnabled(
            isAlignCenter: true,
            isLooping: true,
            isInfinitePage: true,
            isAutoRolling: true,
            autoRollingTimeInterval: 2.5
        )

        // Then
        let presenter = cv.presenter
        XCTAssertTrue(presenter?.isCustomPagingEnabled ?? false)
        XCTAssertTrue(presenter?.isAlignCenter ?? false)
        XCTAssertTrue(presenter?.isLooping ?? false)
        XCTAssertTrue(presenter?.isInfinitePage ?? false)
        XCTAssertTrue(presenter?.isAutoRolling ?? false)
        XCTAssertEqual(presenter?.pagingTimeInterval, 2.5)
    }

    func testDisablingPagingResetsDependentFlags() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(
            isAlignCenter: true,
            isInfinitePage: true,
            isAutoRolling: true
        )

        // When
        cv.ss.setPagingEnabled(false)

        // Then
        let presenter = cv.presenter
        XCTAssertFalse(presenter?.isCustomPagingEnabled ?? true)
        XCTAssertFalse(presenter?.isAlignCenter ?? true)
        XCTAssertFalse(presenter?.isInfinitePage ?? true)
        XCTAssertFalse(presenter?.isAutoRolling ?? true)
    }

    // MARK: - Page Lifecycle Callbacks

    func testPageCallbacksAreStored() {
        // Given
        let cv = makeCollectionView()

        var willAppearIndex: Int?
        var didAppearIndex: Int?
        var willDisappearIndex: Int?
        var didDisappearIndex: Int?

        // When
        cv.ss.onPageWillAppear { _, index in willAppearIndex = index }
        cv.ss.onPageDidAppear { _, index in didAppearIndex = index }
        cv.ss.onPageWillDisappear { _, index in willDisappearIndex = index }
        cv.ss.onPageDidDisappear { _, index in didDisappearIndex = index }

        cv.presenter?.pageWillAppearBlock?(cv, 0)
        cv.presenter?.pageDidAppearBlock?(cv, 1)
        cv.presenter?.pageWillDisappearBlock?(cv, 2)
        cv.presenter?.pageDidDisappearBlock?(cv, 3)

        // Then
        XCTAssertEqual(willAppearIndex, 0)
        XCTAssertEqual(didAppearIndex, 1)
        XCTAssertEqual(willDisappearIndex, 2)
        XCTAssertEqual(didDisappearIndex, 3)
    }

    // MARK: - FlowLayout Delegate

    func testFlowLayoutSizeForItem() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(11)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let indexPath = IndexPath(item: 0, section: 0)
        let size = cv.presenter?.collectionView(cv, layout: layout, sizeForItemAt: indexPath)

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 100))
    }

    func testFlowLayoutSectionInsets() {
        // Given
        let cv = makeCollectionView()
        let cellInfos = makeCellInfos(from: makeSampleBanners(11))
        var section = SSCollectionViewModel.SectionInfo(items: cellInfos)
        section.sectionInsets = UIEdgeInsets(top: 11, left: 10, bottom: 19, right: 30)
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let inset = cv.presenter?.collectionView(cv, layout: layout, insetForSectionAt: 0)

        // Then
        XCTAssertEqual(inset, UIEdgeInsets(top: 11, left: 10, bottom: 19, right: 30))
    }

    func testFlowLayoutMinimumLineSpacing() {
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

    func testFlowLayoutMinimumInteritemSpacing() {
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

    func testFlowLayoutHeaderSize() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        section.setHeaderInfo(model: TestHeaderData(title: "Header"), viewModel: TestHeaderViewModel())

        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let size = cv.presenter?.collectionView(cv, layout: layout, referenceSizeForHeaderInSection: 0)

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 50))
    }

    func testFlowLayoutFooterSize() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        section.setFooterInfo(model: TestFooterData(text: "Footer"), viewModel: TestFooterViewModel())

        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        // When
        let layout = cv.collectionViewLayout
        let size = cv.presenter?.collectionView(cv, layout: layout, referenceSizeForFooterInSection: 0)

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 30))
    }

    // MARK: - Infinite Scroll

    func testInfiniteScrollTriplicatesItemCount() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(11)

        cv.ss.setPagingEnabled(isInfinitePage: true)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()

        // When
        let itemCount = cv.dataSource?.collectionView(cv, numberOfItemsInSection: 0)

        // Then
        XCTAssertEqual(itemCount, 11 * 3, "Infinite scroll should triplicate items")
    }

    func testInfiniteScrollSingleItemNotTriplicated() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(1)

        cv.ss.setPagingEnabled(isInfinitePage: true)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()

        // When
        let itemCount = cv.dataSource?.collectionView(cv, numberOfItemsInSection: 0)

        // Then
        XCTAssertEqual(itemCount, 1, "Single item should not be triplicated")
    }

    // MARK: - Safe Subscript

    func testSafeSubscriptReturnsNilForOutOfBounds() {
        // Given
        let array = [11, 30, 90]

        // Then
        XCTAssertEqual(array[safe: 0], 11)
        XCTAssertEqual(array[safe: 2], 90)
        XCTAssertNil(array[safe: 3])
        XCTAssertNil(array[safe: -1])
    }

    func testSafeSubscriptOnEmptyCollection() {
        // Given
        let empty: [Int] = []

        // Then
        XCTAssertNil(empty[safe: 0])
    }

    // MARK: - Builder Edge Cases

    func testBuilderImplicitSectionCreation() {
        // Given
        let builder = SSCollectionViewModel.Builder()

        // When
        builder.cell(model: TestBanner(id: "90", title: "TopBanner"), viewModel: TestBannerCellModel())
        builder.cell(model: TestBanner(id: "94", title: "MainBanner"), viewModel: TestBannerCellModel())
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 1, "Should auto-create one implicit section")
        XCTAssertEqual(model[0].count, 2)
    }

    func testBuilderEmptySectionIsStillCreated() {
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

    func testBuilderChainedSections() {
        // Given
        let builder = SSCollectionViewModel.Builder()

        // When
        builder
            .section("AdBanner") {
                builder.cell(model: TestBanner(id: "2119", title: "AdBanner 1"), viewModel: TestBannerCellModel())
            }
            .section("SubBanner") {
                builder.cell(model: TestBanner(id: "2234", title: "SubBanner 1"), viewModel: TestBannerCellModel())
            }
        let model = builder.build()

        // Then
        XCTAssertEqual(model.count, 2)
        XCTAssertEqual(model[0].identifier, "AdBanner")
        XCTAssertEqual(model[1].identifier, "SubBanner")
    }

    // MARK: - FlowLayout Lifecycle — willDisplay / didEndDisplaying

    func testWillDisplayCellCallsLifecycleMethod() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
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

    func testWillDisplayCellWithNilViewModelIsNoOp() {
        // Given
        let cv = makeCollectionView()
        let cell = TestBannerCell()

        // When — no viewModel set, should not crash
        cv.presenter?.collectionView(cv, willDisplay: cell, forItemAt: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertFalse(cell.willDisplayCalled)
    }

    func testDidEndDisplayingCellCallsLifecycleMethod() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()

        let cell = TestBannerCell()
        let indexPath = IndexPath(item: 1, section: 0)

        // When
        cv.presenter?.collectionView(cv, didEndDisplaying: cell, forItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didEndDisplayingCalled)
    }

    func testWillDisplaySupplementaryViewHeader() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setHeaderInfo(model: TestHeaderData(title: "Header"), viewModel: TestHeaderViewModel())
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let headerView = TestHeaderView()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(
            cv,
            willDisplaySupplementaryView: headerView,
            forElementKind: UICollectionView.elementKindSectionHeader,
            at: indexPath
        )

        // Then
        XCTAssertTrue(headerView.willDisplayCalled)
    }

    func testWillDisplaySupplementaryViewFooter() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setFooterInfo(model: TestFooterData(text: "Footer"), viewModel: TestFooterViewModel())
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let footerView = TestFooterView()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(
            cv,
            willDisplaySupplementaryView: footerView,
            forElementKind: UICollectionView.elementKindSectionFooter,
            at: indexPath
        )

        // Then
        XCTAssertTrue(footerView.willDisplayCalled)
    }

    func testDidEndDisplayingSupplementaryViewHeader() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setHeaderInfo(model: TestHeaderData(title: "Header"), viewModel: TestHeaderViewModel())
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let headerView = TestHeaderView()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(
            cv,
            didEndDisplayingSupplementaryView: headerView,
            forElementOfKind: UICollectionView.elementKindSectionHeader,
            at: indexPath
        )

        // Then
        XCTAssertTrue(headerView.didEndDisplayingCalled)
    }

    func testDidEndDisplayingSupplementaryViewFooter() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setFooterInfo(model: TestFooterData(text: "Footer"), viewModel: TestFooterViewModel())
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))
        cv.reloadData()

        let footerView = TestFooterView()
        let indexPath = IndexPath(item: 0, section: 0)

        // When
        cv.presenter?.collectionView(
            cv,
            didEndDisplayingSupplementaryView: footerView,
            forElementOfKind: UICollectionView.elementKindSectionFooter,
            at: indexPath
        )

        // Then
        XCTAssertTrue(footerView.didEndDisplayingCalled)
    }

    func testWillDisplaySupplementaryViewUnknownKindIsNoOp() {
        // Given
        let cv = makeCollectionView()
        var section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        section.setHeaderInfo(model: TestHeaderData(title: "Header"), viewModel: TestHeaderViewModel())
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: [section]))

        let headerView = TestHeaderView()

        // When — unknown element kind should be a no-op
        cv.presenter?.collectionView(
            cv,
            willDisplaySupplementaryView: headerView,
            forElementKind: "UnknownKind",
            at: IndexPath(item: 0, section: 0)
        )

        // Then
        XCTAssertFalse(headerView.willDisplayCalled)
    }

    func testWillDisplayCellWithInfinitePageMiddleRange() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(isInfinitePage: true)
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()

        let cell = TestBannerCell()
        // Middle range: item >= count(5) and item * (3/2=1) < count(5) * (3/2+1=2)
        // item=7: 7 >= 5 ✅, 7*1=7 < 5*2=10 ✅ -> should call willDisplay
        let indexPath = IndexPath(item: 7, section: 0)

        // When
        cv.presenter?.collectionView(cv, willDisplay: cell, forItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.willDisplayCalled)
    }

    func testDidEndDisplayingCellWithInfinitePage() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(isInfinitePage: true)
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()

        let cell = TestBannerCell()
        let indexPath = IndexPath(item: 8, section: 0)

        // When
        cv.presenter?.collectionView(cv, didEndDisplaying: cell, forItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didEndDisplayingCalled)
    }

    // MARK: - FlowLayout Interaction — Highlight / Select

    func testDidSelectItemCallsCellMethod() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        guard let cell = cv.cellForItem(at: indexPath) as? TestBannerCell else {
            // Cell may not be available in headless test environment; skip assertion
            return
        }
        cv.presenter?.collectionView(cv, didSelectItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didSelectCalled)
    }

    func testDidDeselectItemCallsCellMethod() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        guard let cell = cv.cellForItem(at: indexPath) as? TestBannerCell else {
            return
        }
        cv.presenter?.collectionView(cv, didDeselectItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didDeselectCalled)
    }

    func testDidHighlightItemCallsCellMethod() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        guard let cell = cv.cellForItem(at: indexPath) as? TestBannerCell else {
            return
        }
        cv.presenter?.collectionView(cv, didHighlightItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didHighlightCalled)
    }

    func testDidUnhighlightItemCallsCellMethod() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let indexPath = IndexPath(item: 0, section: 0)

        // When
        guard let cell = cv.cellForItem(at: indexPath) as? TestBannerCell else {
            return
        }
        cv.presenter?.collectionView(cv, didUnhighlightItemAt: indexPath)

        // Then
        XCTAssertTrue(cell.didUnhighlightCalled)
    }

    func testDidSelectWithNilViewModelIsNoOp() {
        // Given
        let cv = makeCollectionView()

        // When — no viewModel set, should not crash
        cv.presenter?.collectionView(cv, didSelectItemAt: IndexPath(item: 0, section: 0))

        // Then — no crash is the assertion
    }

    func testDidSelectWithOutOfBoundsIsNoOp() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(), viewModel: TestBannerCellModel())
            }
        }

        // When — out of bounds section, should not crash
        cv.presenter?.collectionView(cv, didSelectItemAt: IndexPath(item: 0, section: 2))

        // Then — no crash is the assertion
    }

    // MARK: - FlowLayout Fallback Paths

    func testSizeForItemWithNilViewModelReturnsFlowLayoutDefault() {
        // Given
        let cv = makeCollectionView()
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = CGSize(width: 119, height: 59)

        // When — no viewModel set
        let size = cv.presenter?.collectionView(cv, layout: flowLayout, sizeForItemAt: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertEqual(size, CGSize(width: 119, height: 59))
    }

    func testSizeForItemWithNonFlowLayoutReturnsZero() {
        // Given
        let cv = makeCollectionView()
        let nonFlowLayout = UICollectionViewLayout()

        // When — non-flow layout with no viewModel
        let size = cv.presenter?.collectionView(cv, layout: nonFlowLayout, sizeForItemAt: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertEqual(size, .zero)
    }

    func testInsetForSectionWithNilViewModelReturnsFlowLayoutDefault() {
        // Given
        let cv = makeCollectionView()
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.sectionInset = UIEdgeInsets(top: 23, left: 29, bottom: 31, right: 37)

        // When — no viewModel
        let inset = cv.presenter?.collectionView(cv, layout: flowLayout, insetForSectionAt: 0)

        // Then
        XCTAssertEqual(inset, UIEdgeInsets(top: 23, left: 29, bottom: 31, right: 37))
    }

    func testMinimumLineSpacingWithNilViewModelReturnsFlowLayoutDefault() {
        // Given
        let cv = makeCollectionView()
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.minimumLineSpacing = 41

        // When — no viewModel
        let spacing = cv.presenter?.collectionView(cv, layout: flowLayout, minimumLineSpacingForSectionAt: 0)

        // Then
        XCTAssertEqual(spacing, 41)
    }

    func testHeaderSizeWithNilViewModelReturnsFlowLayoutDefault() {
        // Given
        let cv = makeCollectionView()
        let flowLayout = cv.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.headerReferenceSize = CGSize(width: 375, height: 60)

        // When — no viewModel
        let size = cv.presenter?.collectionView(cv, layout: flowLayout, referenceSizeForHeaderInSection: 0)

        // Then
        XCTAssertEqual(size, CGSize(width: 375, height: 60))
    }

    func testFooterSizeWithNonFlowLayoutReturnsZero() {
        // Given
        let cv = makeCollectionView()
        let nonFlowLayout = UICollectionViewLayout()

        // When — non-flow layout with no viewModel
        let size = cv.presenter?.collectionView(cv, layout: nonFlowLayout, referenceSizeForFooterInSection: 0)

        // Then
        XCTAssertEqual(size, .zero)
    }

    // MARK: - DataSource Edge Cases

    func testCellForItemAtWithNilViewModelReturnsDefaultCell() {
        // Given
        let cv = makeCollectionView()
        cv.reloadData()

        // When
        let cell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 0, section: 0))

        // Then
        XCTAssertNotNil(cell)
        XCTAssertFalse(cell is TestBannerCell, "Should return a default UICollectionViewCell, not TestBannerCell")
    }

    func testCellForItemAtWithInfiniteScrollModuloIndexing() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setPagingEnabled(isInfinitePage: true)
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: TestBannerCellModel())
            }
        }
        cv.reloadData()

        // When — item 12 should map to item 2 (12 % 5 = 2)
        let cell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 12, section: 0))

        // Then
        XCTAssertTrue(cell is TestBannerCell)
        if let bannerCell = cell as? TestBannerCell {
            XCTAssertEqual(bannerCell.titleLabel.text, "Banner 2")
        }
    }

    func testReusableViewInfoApplyBindsHeaderData() {
        // Given
        let headerData = TestHeaderData(title: "TestHeader")
        let info = SSCollectionViewModel.ReusableViewInfo(TestHeaderViewModel(contentData: headerData))
        let view = TestHeaderView()

        // When
        info.apply(to: view)

        // Then
        XCTAssertEqual(view.titleLabel.text, "TestHeader")
    }

    func testReusableViewInfoApplyBindsFooterData() {
        // Given
        let footerData = TestFooterData(text: "TestFooter")
        let info = SSCollectionViewModel.ReusableViewInfo(TestFooterViewModel(contentData: footerData))
        let view = TestFooterView()

        // When
        info.apply(to: view)

        // Then
        XCTAssertEqual(view.textLabel.text, "TestFooter")
    }

    // MARK: - CellInfo Interaction Methods

    func testCellInfoApplyBindsDataToCorrectBinder() {
        // Given
        let banner = TestBanner(id: "211", title: "ApplyTestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.apply(to: cell)

        // Then
        XCTAssertEqual(cell.titleLabel.text, "ApplyTestItem")
    }

    func testCellInfoApplyWithWrongBinderTypeIsNoOp() {
        // Given
        let banner = TestBanner(id: "312", title: "SomeItem")
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))
        let wrongCell = UICollectionViewCell()

        // When — wrong cell type, should be no-op
        cellInfo.apply(to: wrongCell)

        // Then — no crash is the assertion
    }

    func testCellInfoDidSelectCallsCellMethod() {
        // Given
        let banner = TestBanner(id: "423", title: "TestItem")
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.didSelect(to: cell)

        // Then
        XCTAssertTrue(cell.didSelectCalled)
    }

    func testCellInfoWillDisplayCallsCellMethod() {
        // Given
        let banner = TestBanner(id: "523", title: "Item")
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.willDisplay(to: cell)

        // Then
        XCTAssertTrue(cell.willDisplayCalled)
    }

    func testCellInfoDidEndDisplayingCallsCellMethod() {
        // Given
        let banner = TestBanner(id: "699", title: "Hello, Swift!")
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: banner))
        let cell = TestBannerCell()

        // When
        cellInfo.didEndDisplaying(to: cell)

        // Then
        XCTAssertTrue(cell.didEndDisplayingCalled)
    }

    func testCellInfoInteractionWithNilContentDataIsNoOp() {
        // Given
        let cellInfo = SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: nil))
        let cell = TestBannerCell()

        // When — all interactions with nil contentData should be no-ops
        cellInfo.apply(to: cell)
        cellInfo.didSelect(to: cell)
        cellInfo.willDisplay(to: cell)
        cellInfo.didEndDisplaying(to: cell)
        cellInfo.didHighlight(to: cell)
        cellInfo.didUnhighlight(to: cell)
        cellInfo.didDeselect(to: cell)

        // Then
        XCTAssertFalse(cell.didSelectCalled)
        XCTAssertFalse(cell.willDisplayCalled)
        XCTAssertFalse(cell.didEndDisplayingCalled)
        XCTAssertFalse(cell.didHighlightCalled)
        XCTAssertFalse(cell.didUnhighlightCalled)
        XCTAssertFalse(cell.didDeselectCalled)
        XCTAssertNil(cell.titleLabel.text)
    }

    // MARK: - ReusableViewInfo Methods

    func testReusableViewInfoApplyBindsData() {
        // Given
        let headerData = TestHeaderData(title: "TestHeader")
        let info = SSCollectionViewModel.ReusableViewInfo(TestHeaderViewModel(contentData: headerData))
        let view = TestHeaderView()

        // When
        info.apply(to: view)

        // Then
        XCTAssertEqual(view.titleLabel.text, "TestHeader")
    }

    func testReusableViewInfoWillDisplayCallsViewMethod() {
        // Given
        let headerData = TestHeaderData(title: "Hello, World!")
        let info = SSCollectionViewModel.ReusableViewInfo(TestHeaderViewModel(contentData: headerData))
        let view = TestHeaderView()

        // When
        info.willDisplay(to: view)

        // Then
        XCTAssertTrue(view.willDisplayCalled)
    }

    func testReusableViewInfoDidEndDisplayingCallsViewMethod() {
        // Given
        let headerData = TestHeaderData(title: "Hello, SSCollectionViewPresenter!")
        let info = SSCollectionViewModel.ReusableViewInfo(TestHeaderViewModel(contentData: headerData))
        let view = TestHeaderView()

        // When
        info.didEndDisplaying(to: view)

        // Then
        XCTAssertTrue(view.didEndDisplayingCalled)
    }

    func testReusableViewInfoViewSizeWithNilContentDataReturnsNil() {
        // Given
        let info = SSCollectionViewModel.ReusableViewInfo(TestHeaderViewModel(contentData: nil))

        // When
        let size = info.viewSize(constrainedTo: CGSize(width: 375, height: 667))

        // Then
        XCTAssertNil(size, "Should return nil when contentData is nil")
    }

    // MARK: - SSCollectionViewModel Collection Conformance

    func testViewModelStartIndexAndEndIndex() {
        // Given
        let sections = (0..<3).map { _ in
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(2)))
        }
        let vm = SSCollectionViewModel(sections: sections)

        // Then
        XCTAssertEqual(vm.startIndex, 0)
        XCTAssertEqual(vm.endIndex, 3)
    }

    func testViewModelIndexAfterAndBefore() {
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

    func testViewModelReplaceSubrange() {
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

    func testViewModelPlusSectionInfoArrayOperator() {
        // Given
        let vm = SSCollectionViewModel(sections: [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))
        ])
        let newSections = [
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(19))),
            SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(23)))
        ]

        // When
        let result = vm + newSections

        // Then
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].count, 11)
        XCTAssertEqual(result[1].count, 19)
        XCTAssertEqual(result[2].count, 23)
    }

    func testSectionInfoHashableUsesUUID() {
        // Given — two SectionInfos with same data but different UUIDs
        let items = makeCellInfos(from: makeSampleBanners(3))
        let section1 = SSCollectionViewModel.SectionInfo(items: items, identifier: "SameSection")
        let section2 = SSCollectionViewModel.SectionInfo(items: items, identifier: "SameSection")

        // Then
        XCTAssertNotEqual(section1, section2, "Different SectionInfo instances should have different UUIDs")
        XCTAssertEqual(section1, section1, "Same instance should be equal")
    }

    // MARK: - Granular Operations Edge Cases

    func testAppendItemToLastSectionWithEmptyViewModelIsNoOp() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setViewModel(with: SSCollectionViewModel(sections: []))
        let item = makeCellInfo(from: TestBanner(id: "830", title: "TestItem"))

        // When
        cv.ss.appendItemToLastSection(item)

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?.count, 0, "Should remain empty")
    }

    func testAppendItemBySectionIdentifierNonExistentIsNoOp() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("TestSection") {
                builder.cells(models: makeSampleBanners(11), viewModel: TestBannerCellModel())
            }
        }
        let item = makeCellInfo(from: TestBanner(id: "951", title: "TestItem"))

        // When
        cv.ss.appendItem(item, firstSectionIdentifier: "InvalidSection")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 11, "Should be unchanged")
    }

    func testDeleteItemsMultiSectionCorrectOrder() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("Hi") {
                builder.cells(models: makeSampleBanners(11), viewModel: TestBannerCellModel())
            }
            builder.section("Bye") {
                builder.cells(models: makeSampleBanners(5), viewModel: TestBannerCellModel())
            }
        }

        // When — delete from multiple sections, reverse sorting ensures correct index handling
        cv.ss.deleteItems(at: [
            IndexPath(item: 1, section: 0),
            IndexPath(item: 3, section: 0),
            IndexPath(item: 0, section: 1),
            IndexPath(item: 2, section: 1)
        ])

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 9, "Hi section: 11 - 2 = 9")
        XCTAssertEqual(cv.ss.getViewModel()?[1].count, 3, "Bye section: 5 - 2 = 3")
    }

    func testDeleteItemBySectionIdentifierNonExistentIsNoOp() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("ValidSection") {
                builder.cells(models: makeSampleBanners(4), viewModel: TestBannerCellModel())
            }
        }

        // When
        cv.ss.deleteItem(atRow: 0, firstSectionIdentifier: "InvalidSection")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 4, "Should be unchanged")
    }

    func testUpdateItemBySectionIdentifierNonExistentIsNoOp() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section("TestSection") {
                builder.cells(models: makeSampleBanners(5), viewModel: TestBannerCellModel())
            }
        }
        let updated = makeCellInfo(from: TestBanner(id: "1030", title: "TestItem"))

        // When
        cv.ss.updateItem(updated, atRow: 0, firstSectionIdentifier: "InvalidSection")

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 5, "Should be unchanged")
    }

    func testInsertItemAtExactEndIndex() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: makeSampleBanners(5), viewModel: TestBannerCellModel())
            }
        }
        let item = makeCellInfo(from: TestBanner(id: "1104", title: "TestItem"))

        // When — insert at endIndex (== count) should succeed
        cv.ss.insertItem(item, at: IndexPath(item: 5, section: 0))

        // Then
        XCTAssertEqual(cv.ss.getViewModel()?[0].count, 6)
    }

    func testExtendViewModelWithNoExistingViewModel() {
        // Given
        let cv = makeCollectionView()
        XCTAssertNil(cv.ss.getViewModel())

        // When — extend with no existing viewModel, should create from scratch
        let result = cv.ss.extendViewModel { builder in
            builder.section("NewSection") {
                builder.cells(models: makeSampleBanners(23), viewModel: TestBannerCellModel())
            }
        }

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].count, 23)
        XCTAssertEqual(result[0].identifier, "NewSection")
    }

    // MARK: - Additional Operator Tests

    func testSectionInfoPlusEqualOperator() {
        // Given
        var section1 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(8)))
        let section2 = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(11)))

        // When
        section1 += section2

        // Then
        XCTAssertEqual(section1.count, 19)
    }

    func testSectionInfoPlusCellInfoOperator() {
        // Given
        let section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(8)))
        let cellInfo = makeCellInfo(from: TestBanner(id: "1130", title: "MyItem"))

        // When
        let result = section + cellInfo

        // Then
        XCTAssertEqual(result.count, 9)
    }

    func testSectionInfoPlusCellInfoArrayOperator() {
        // Given
        let section = SSCollectionViewModel.SectionInfo(items: makeCellInfos(from: makeSampleBanners(3)))
        let newCells = makeCellInfos(from: makeSampleBanners(10))

        // When
        let result = section + newCells

        // Then
        XCTAssertEqual(result.count, 13)
    }
}
