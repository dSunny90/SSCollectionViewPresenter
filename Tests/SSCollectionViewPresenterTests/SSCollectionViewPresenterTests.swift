//
//  SSCollectionViewPresenterTests.swift
//  SSCollectionViewPresenterTests
//
//  Created by SunSoo Jeon on 19.08.2023.
//

import XCTest
@testable import SSCollectionViewPresenter

import UIKit

struct TestBanner: Decodable {
    let id: String
    let title: String
}

struct TestBannerCellModel: Boundable {
    var contentData: TestBanner?
    var binderType: TestBannerCell.Type { TestBannerCell.self }
}

final class TestBannerCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    let titleLabel = UILabel()

    static func size(with input: TestBanner?, constrainedTo parentSize: CGSize?) -> CGSize? {
        return CGSize(width: 100, height: 100)
    }

    var configurer: (TestBannerCell, TestBanner) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

class SSCollectionViewPresenterTests: XCTestCase {
    var presenter: SSCollectionViewPresenter!
    var collectionView: UICollectionView!

    override func setUp() {
        super.setUp()
        DispatchQueue.main.async {
            self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
            self.collectionView.ss.setupPresenter()
        }
    }

    override func tearDown() {
        presenter = nil
        collectionView = nil
        super.tearDown()
    }

    func testNumberOfItemsMatchesViewModel() throws {
        DispatchQueue.main.async {
            let testBanners = [
                TestBanner(id: "1", title: "First"),
                TestBanner(id: "2", title: "Second"),
                TestBanner(id: "3", title: "Third")
            ]

            let cellInfos = testBanners.map { SSCollectionViewModel.CellInfo(TestBannerCellModel(contentData: $0)) }

            let section = SSCollectionViewModel.SectionInfo(items: cellInfos)
            let viewModel = SSCollectionViewModel(sections: [section])

            self.collectionView.ss.setViewModel(with: viewModel)
            self.collectionView.reloadData()

            let itemCount = self.collectionView.dataSource?.collectionView(self.collectionView, numberOfItemsInSection: 0)
            XCTAssertEqual(itemCount, testBanners.count, "Item count should match number of banners")

            let indexPath = IndexPath(item: 0, section: 0)
            guard let cell = self.collectionView.dataSource?.collectionView(self.collectionView, cellForItemAt: indexPath) as? TestBannerCell else {
                XCTFail("Failed to dequeue BannerCell")
                return
            }

            XCTAssertEqual(cell.titleLabel.text, "First", "First cell's title should be 'First'")
        }

    }
}
