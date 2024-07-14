//
//  TestFixtures.swift
//  SSCollectionViewPresenter
// 
//  Created by SunSoo Jeon on 24.04.2021.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

// MARK: - Test Models

struct TestBanner: Decodable, Sendable {
    let id: String
    let title: String
}

struct TestHeaderData: Sendable {
    let title: String
}

struct TestFooterData: Sendable {
    let text: String
}

// MARK: - Test Cells

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

// MARK: - Test Supplementary Views

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
func makeCollectionView(
    frame: CGRect = CGRect(x: 0, y: 0, width: 375, height: 667),
    layoutKind: SSCollectionViewPresenter.LayoutKind = .flow,
    dataSourceMode: SSCollectionViewPresenter.DataSourceMode = .traditional
) -> UICollectionView {
    let cv = UICollectionView(frame: frame, collectionViewLayout: UICollectionViewFlowLayout())
    cv.ss.setupPresenter(layoutKind: layoutKind, dataSourceMode: dataSourceMode)
    return cv
}

@MainActor
func makeSampleBanners(_ count: Int = 8) -> [TestBanner] {
    (0..<count).map { TestBanner(id: "\($0)", title: "Banner \($0)") }
}

@MainActor
func makeCellInfo(from banner: TestBanner) -> SSCollectionViewModel.CellInfo {
    .init(BindingStore<TestBanner, TestBannerCell>(state: banner))
}

@MainActor
func makeCellInfos(from banners: [TestBanner]) -> [SSCollectionViewModel.CellInfo] {
    banners.map { makeCellInfo(from: $0) }
}
