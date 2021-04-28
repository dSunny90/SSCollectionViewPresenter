//
//  SSCollectionViewPresenterTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 24.04.2021.
//

import XCTest
@testable import SSCollectionViewPresenter

import UIKit

class SSCollectionViewPresenterTests: XCTestCase {
    func test_presenter() {
        let cv = UICollectionView(frame: CGRect(x: 0, y: 0, width: 375, height: 667), collectionViewLayout: UICollectionViewFlowLayout())
        cv.ss.setupPresenter()
        XCTAssertNotNil(cv.presenter, "Presenter should be attached after setupPresenter()")

        let models = (0..<5).map { TestModel(id: "\($0)", title: "Model \($0)") }
        let items = models.map { BindingStore<TestModel, TestCell>(state: $0).eraseToAnyBindingStore() }
        let header = BindingStore<TestModel, TestReusableView>(state: TestModel(id: "10", title: "Header 10")).eraseToAnyBindingStore()
        let footer = BindingStore<TestModel, TestReusableView>(state: TestModel(id: "20", title: "Footer 20")).eraseToAnyBindingStore()
        let section = SSCollectionViewModel.SectionInfo(items: items, header: header, footer: footer)
        let viewModel = SSCollectionViewModel(sections: [section])

        cv.ss.setViewModel(with: viewModel)

        let retrieved = cv.ss.getViewModel()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.count, 1, "Should have 1 section")
        XCTAssertEqual(retrieved?[0].count, 5, "Section should have 5 items (default)")

        cv.reloadData()

        let cellCount = cv.dataSource?.collectionView(cv, numberOfItemsInSection: 0)
        XCTAssertEqual(cellCount, 5)

        guard let cell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 2, section: 0)) as? TestCell else {
            XCTFail("Failed to dequeue TestCell")
            return
        }

        XCTAssertEqual(cell.titleLabel.text, "Model 2")

        guard let headerView = cv.dataSource?.collectionView?(cv, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? TestReusableView else {
            XCTFail("Failed to dequeue TestReusableView")
            return
        }

        XCTAssertEqual(headerView.titleLabel.text, "Header 10")

        guard let footerView = cv.dataSource?.collectionView?(cv, viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: 0)) as? TestReusableView else {
            XCTFail("Failed to dequeue TestReusableView")
            return
        }

        XCTAssertEqual(footerView.titleLabel.text, "Footer 20")
    }
}

final class TestReusableView: UICollectionReusableView, Configurable {
    let titleLabel = UILabel()

    var configurer: (TestReusableView, TestModel) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

final class TestCell: UICollectionViewCell, Configurable {
    let titleLabel = UILabel()

    var configurer: (TestCell, TestModel) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

struct TestModel {
    let id: String
    let title: String
}
