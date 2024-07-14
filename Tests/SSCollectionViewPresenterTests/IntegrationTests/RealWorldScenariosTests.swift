//
//  RealWorldScenariosTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 23.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

// MARK: - Scenario 1: Server-Driven UI (Decodable + Builder.sections API)
// Server-client contract (ViewModelSectionRepresentable / ViewModelUnitRepresentable)
// Parse server response via Decodable -> build with Builder.sections()

// MARK: Server Response Models (Scenario 1)

private struct ServerBanner: Decodable, Sendable {
    let bannerId: String
    let imageUrl: String
    let linkUrl: String
}

private struct ServerProduct: Decodable, Sendable {
    let productId: String
    let name: String
    let price: Int
    let thumbnailUrl: String
}

private struct ServerUnit: Decodable {
    let unitType: String
    let data: UnitPayload

    enum CodingKeys: String, CodingKey {
        case unitType
        case data
    }

    enum UnitPayload {
        case banners([ServerBanner])
        case products([ServerProduct])
        case unknown
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unitType = try container.decode(String.self, forKey: .unitType)

        switch unitType {
        case "TOP_BANNER":
            let banners = try container.decode([ServerBanner].self, forKey: .data)
            data = .banners(banners)
        case "PRODUCT_LIST":
            let products = try container.decode([ServerProduct].self, forKey: .data)
            data = .products(products)
        default:
            data = .unknown
        }
    }
}

private struct ServerSection: Decodable {
    let sectionId: String?
    let units: [ServerUnit]
}

private struct ServerDrivenResponse: Decodable {
    let sectionList: [ServerSection]
    let hasNext: Bool
    let page: Int
}

// ViewModelSectionRepresentable / ViewModelUnitRepresentable conformance

private struct AppUnit: ViewModelUnitRepresentable {
    let unitType: String
    let unitData: Any?
}

private struct AppSection: ViewModelSectionRepresentable {
    let sectionId: String?
    let units: [any ViewModelUnitRepresentable]
}

// Cells for Scenario 1

private final class BannerCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    let imageLabel = UILabel()

    static func size(with input: ServerBanner?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 375, height: 200)
    }

    var configurer: (BannerCell, ServerBanner) -> Void {
        { view, model in
            view.imageLabel.text = model.imageUrl
        }
    }
}

private final class ProductCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    let nameLabel = UILabel()
    let priceLabel = UILabel()

    static func size(with input: ServerProduct?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 375, height: 400)
    }

    var configurer: (ProductCell, ServerProduct) -> Void {
        { view, model in
            view.nameLabel.text = model.name
            view.priceLabel.text = "\(model.price)원"
        }
    }
}

// MARK: - Scenario 2: Standard Client-Driven Composition
// Standard API format: receives fields like productList, bannerList
// and the client constructs section-item ordering directly

private struct StandardBanner: Decodable, Sendable {
    let id: Int
    let title: String
    let imageUrl: String
}

private struct StandardProduct: Decodable, Sendable {
    let id: Int
    let name: String
    let price: Int
    let discountRate: Double
    let imageUrl: String
}

private struct StandardHeaderInfo: Sendable {
    let title: String
    let subtitle: String?
}

private struct StandardResponse: Decodable {
    let bannerList: [StandardBanner]
    let productList: [StandardProduct]
    let hasNext: Bool
}

// Cells for Scenario 2

private final class StandardBannerCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    let titleLabel = UILabel()

    static func size(with input: StandardBanner?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 375, height: 180)
    }

    var configurer: (StandardBannerCell, StandardBanner) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

private final class StandardProductCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    let nameLabel = UILabel()
    let priceLabel = UILabel()

    static func size(with input: StandardProduct?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 375, height: 400)
    }

    var configurer: (StandardProductCell, StandardProduct) -> Void {
        { view, model in
            view.nameLabel.text = model.name
            view.priceLabel.text = "\(model.price)원"
        }
    }
}

private final class SectionHeaderView: UICollectionReusableView, SSCollectionReusableViewProtocol {
    let titleLabel = UILabel()

    static func size(with input: StandardHeaderInfo?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 375, height: 44)
    }

    var configurer: (SectionHeaderView, StandardHeaderInfo) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

// MARK: - Tests

@MainActor
final class RealWorldScenariosTests: XCTestCase {
    // MARK: - Scenario 1: Server-Driven UI

    func test_server_driven_ui_parses_json_and_builds_view_model_via_sections_api() {
        // Given — Server response JSON
        let json = """
        {
            "sectionList": [
                {
                    "sectionId": "TopBanner",
                    "units": [
                        {
                            "unitType": "TOP_BANNER",
                            "data": [
                                { "bannerId": "10000001", "imageUrl": "https://cdn.example.com/banner1.jpg", "linkUrl": "https://example.com/event1" },
                                { "bannerId": "10000002", "imageUrl": "https://cdn.example.com/banner2.jpg", "linkUrl": "https://example.com/event2" },
                                { "bannerId": "10000003", "imageUrl": "https://cdn.example.com/banner3.jpg", "linkUrl": "https://example.com/event3" }
                            ]
                        }
                    ]
                },
                {
                    "sectionId": "WeeklyBest",
                    "units": [
                        {
                            "unitType": "PRODUCT_LIST",
                            "data": [
                                { "productId": "00000001", "name": "동물복지 유정란 15구 780g", "price": 8000, "thumbnailUrl": "https://cdn.example.com/00000001.jpg" },
                                { "productId": "00000002", "name": "나랑드사이다 제로 1.25L", "price": 1500, "thumbnailUrl": "https://cdn.example.com/00000002.jpg" },
                                { "productId": "00000003", "name": "삼다수 2L 6입", "price": 5400, "thumbnailUrl": "https://cdn.example.com/00000003.jpg" },
                                { "productId": "00000004", "name": "오뚜기 진라면 순한맛 120g*5개", "price": 3600, "thumbnailUrl": "https://cdn.example.com/00000004.jpg" },
                                { "productId": "00000005", "name": "서울우유 1L", "price": 2500, "thumbnailUrl": "https://cdn.example.com/00000005.jpg" }
                            ]
                        }
                    ]
                }
            ],
            "hasNext": true,
            "page": 0
        }
        """.data(using: .utf8)!

        // When — Parse via Decodable
        let response = try! JSONDecoder().decode(ServerDrivenResponse.self, from: json)

        // Then — Verify parsed result
        XCTAssertEqual(response.sectionList.count, 2)
        XCTAssertEqual(response.page, 0)
        XCTAssertTrue(response.hasNext)

        // Given — Convert to AppSection / AppUnit
        let appSections: [AppSection] = response.sectionList.map { serverSection in
            let appUnits: [AppUnit] = serverSection.units.map { serverUnit in
                let data: Any?
                switch serverUnit.data {
                case .banners(let banners): data = banners
                case .products(let products): data = products
                case .unknown: data = nil
                }
                return AppUnit(unitType: serverUnit.unitType, unitData: data)
            }
            return AppSection(sectionId: serverSection.sectionId, units: appUnits)
        }

        // When — Build ViewModel via Builder.sections API
        let cv = makeCollectionView()
        let result = cv.ss.buildViewModel(page: response.page, hasNext: response.hasNext) { builder in
            builder.sections(
                appSections,
                configureSection: { section, builder in
                    guard let sectionId = section.sectionId else { return }
                    switch sectionId {
                    case "TopBanner":
                        builder.sectionInset(.zero)
                        builder.minimumLineSpacing(0)
                    case "WeeklyBest":
                        builder.sectionInset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
                        builder.minimumLineSpacing(12)
                        builder.minimumInteritemSpacing(8)
                        builder.gridColumnCount(2)
                    default:
                        break
                    }
                },
                configureUnit: { unit, builder in
                    switch unit.unitType {
                    case "TOP_BANNER":
                        guard let banners = unit.unitData as? [ServerBanner] else { return }
                        builder.cells(banners, cellType: BannerCell.self)
                    case "PRODUCT_LIST":
                        guard let products = unit.unitData as? [ServerProduct] else { return }
                        builder.cells(products, cellType: ProductCell.self)
                    default:
                        break
                    }
                }
            )
        }

        // Then — Verify ViewModel structure
        XCTAssertEqual(result.count, 2, "Should have 2 sections (topBanner, weeklyBest)")
        XCTAssertEqual(result.page, 0)
        XCTAssertTrue(result.hasNext)

        // topBanner section
        XCTAssertEqual(result[0].identifier, "TopBanner")
        XCTAssertEqual(result[0].count, 3, "3 banners in topBanner section")
        XCTAssertEqual(result[0].sectionInset, .zero)
        XCTAssertEqual(result[0].minimumLineSpacing, 0)

        // weeklyBest section
        XCTAssertEqual(result[1].identifier, "WeeklyBest")
        XCTAssertEqual(result[1].count, 5, "5 products in weeklyBest section")
        XCTAssertEqual(result[1].sectionInset, UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        XCTAssertEqual(result[1].minimumLineSpacing, 12)
        XCTAssertEqual(result[1].minimumInteritemSpacing, 8)
        XCTAssertEqual(result[1].gridColumnCount, 2)

        // Cell data binding verification
        cv.reloadData()
        let bannerCell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 0, section: 0))
        XCTAssertTrue(bannerCell is BannerCell)
        if let bc = bannerCell as? BannerCell {
            XCTAssertEqual(bc.imageLabel.text, "https://cdn.example.com/banner1.jpg")
        }

        let productCell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 2, section: 1))
        XCTAssertTrue(productCell is ProductCell)
        if let pc = productCell as? ProductCell {
            XCTAssertEqual(pc.nameLabel.text, "삼다수 2L 6입")
            XCTAssertEqual(pc.priceLabel.text, "5400원")
        }
    }

    func test_server_driven_ui_pagination_with_load_page() {
        // Given — Server response Page 0
        let page0Json = """
        {
            "sectionList": [
                {
                    "sectionId": "TopBanner",
                    "units": [
                        {
                            "unitType": "TOP_BANNER",
                            "data": [
                                { "bannerId": "10000001", "imageUrl": "https://cdn.example.com/banner1.jpg", "linkUrl": "https://example.com/event1" }
                            ]
                        }
                    ]
                },
                {
                    "sectionId": "ProductList",
                    "units": [
                        {
                            "unitType": "PRODUCT_LIST",
                            "data": [
                                { "productId": "00000001", "name": "동물복지 유정란 15구 780g", "price": 8000, "thumbnailUrl": "https://cdn.example.com/00000001.jpg" },
                                { "productId": "00000002", "name": "나랑드사이다 제로 1.25L", "price": 1500, "thumbnailUrl": "https://cdn.example.com/00000002.jpg" }
                            ]
                        }
                    ]
                }
            ],
            "hasNext": true,
            "page": 0
        }
        """.data(using: .utf8)!

        let page1Json = """
        {
            "sectionList": [
                {
                    "sectionId": "ProductList",
                    "units": [
                        {
                            "unitType": "PRODUCT_LIST",
                            "data": [
                                { "productId": "00000003", "name": "삼다수 2L 6입", "price": 5400, "thumbnailUrl": "https://cdn.example.com/00000003.jpg" },
                                { "productId": "00000004", "name": "오뚜기 진라면 순한맛 120g*5개", "price": 3600, "thumbnailUrl": "https://cdn.example.com/00000004.jpg" },
                                { "productId": "00000005", "name": "서울우유 1L", "price": 2500, "thumbnailUrl": "https://cdn.example.com/00000005.jpg" }
                            ]
                        }
                    ]
                }
            ],
            "hasNext": false,
            "page": 1
        }
        """.data(using: .utf8)!

        let response0 = try! JSONDecoder().decode(ServerDrivenResponse.self, from: page0Json)
        let response1 = try! JSONDecoder().decode(ServerDrivenResponse.self, from: page1Json)

        let cv = makeCollectionView()

        // When — Load pages via loadPage
        func buildSections(from response: ServerDrivenResponse) -> (SSCollectionViewModel.Builder) -> Void {
            return { builder in
                let appSections: [AppSection] = response.sectionList.map { section in
                    let units: [AppUnit] = section.units.map { unit in
                        let data: Any?
                        switch unit.data {
                        case .banners(let b): data = b
                        case .products(let p): data = p
                        case .unknown: data = nil
                        }
                        return AppUnit(unitType: unit.unitType, unitData: data)
                    }
                    return AppSection(sectionId: section.sectionId, units: units)
                }
                builder.sections(appSections) { unit, builder in
                    switch unit.unitType {
                    case "TOP_BANNER":
                        guard let banners = unit.unitData as? [ServerBanner] else { return }
                        builder.cells(banners, cellType: BannerCell.self)
                    case "PRODUCT_LIST":
                        guard let products = unit.unitData as? [ServerProduct] else { return }
                        builder.cells(products, cellType: ProductCell.self)
                    default:
                        break
                    }
                }
            }
        }

        let result0 = cv.ss.loadPage(response0.page, hasNext: response0.hasNext, buildSections(from: response0))

        // Then — Page 0
        XCTAssertEqual(result0.count, 2)
        XCTAssertEqual(result0[0].identifier, "TopBanner")
        XCTAssertEqual(result0[0].count, 1)
        XCTAssertEqual(result0[1].identifier, "ProductList")
        XCTAssertEqual(result0[1].count, 2)
        XCTAssertTrue(result0.hasNext)

        // When — Load page 1 (productList gets merged)
        let result1 = cv.ss.loadPage(response1.page, hasNext: response1.hasNext, buildSections(from: response1))

        // Then — Page 0 + Page 1 merged
        XCTAssertEqual(result1.count, 2, "Still 2 sections (banner stays, products merged)")
        XCTAssertEqual(result1[0].identifier, "TopBanner")
        XCTAssertEqual(result1[0].count, 1, "Banner count unchanged")
        XCTAssertEqual(result1[1].identifier, "ProductList")
        XCTAssertEqual(result1[1].count, 5, "2 + 3 products merged")
        XCTAssertFalse(result1.hasNext)
    }

    // MARK: - Scenario 2: Standard Client-Driven Composition

    func test_standard_client_composition_with_build_view_model() {
        // Given — Standard API response JSON
        let json = """
        {
            "bannerList": [
                { "id": 1, "title": "Spring Clearance Sale", "imageUrl": "https://cdn.example.com/spring_sale.jpg" },
                { "id": 2, "title": "New Arrivals", "imageUrl": "https://cdn.example.com/new_arrival.jpg" }
            ],
            "productList": [
                { "id": 101, "name": "ADIDAS X FIVE TEN Hiangle Pro", "price": 199000, "discountRate": 0.2, "imageUrl": "https://cdn.example.com/hianglePro.jpg" },
                { "id": 102, "name": "SCARPA Veloce", "price": 210000, "discountRate": 0.15, "imageUrl": "https://cdn.example.com/veloce.jpg" },
                { "id": 103, "name": "UNPARALLEL Souped-up", "price": 239000, "discountRate": 0.0, "imageUrl": "https://cdn.example.com/souped_up.jpg" },
                { "id": 104, "name": "LA SPORTIVA Skwama", "price": 255000, "discountRate": 0.1, "imageUrl": "https://cdn.example.com/skwama.jpg" }
            ],
            "hasNext": false
        }
        """.data(using: .utf8)!

        // When — Parse via Decodable
        let response = try! JSONDecoder().decode(StandardResponse.self, from: json)

        // Then — Verify parsed result
        XCTAssertEqual(response.bannerList.count, 2)
        XCTAssertEqual(response.productList.count, 4)
        XCTAssertFalse(response.hasNext)

        // When — Client constructs section-item ordering directly
        let cv = makeCollectionView()
        let result = cv.ss.buildViewModel(hasNext: response.hasNext) { builder in
            // Banner section: full width, no padding
            builder.section("Banner") {
                builder.sectionInset(.zero)
                builder.minimumLineSpacing(0)
                builder.cells(response.bannerList, cellType: StandardBannerCell.self)
            }

            // Product list section: 2-column grid with header
            builder.section("ProductList") {
                builder.header(
                    StandardHeaderInfo(title: "Popular This Week", subtitle: "Updated every Monday"),
                    viewType: SectionHeaderView.self
                )
                builder.sectionInset(UIEdgeInsets(top: 20, left: 16, bottom: 0, right: 16))
                builder.minimumLineSpacing(10)
                builder.minimumInteritemSpacing(16)
                builder.gridColumnCount(2)
                builder.cells(response.productList, cellType: StandardProductCell.self)
            }
        }

        // Then — Verify ViewModel structure
        XCTAssertEqual(result.count, 2, "Should have 2 sections (Banner, ProductList)")
        XCTAssertFalse(result.hasNext)

        // Banner section
        XCTAssertEqual(result[0].identifier, "Banner")
        XCTAssertEqual(result[0].count, 2, "2 banners")
        XCTAssertNil(result[0].headerInfo())
        XCTAssertEqual(result[0].sectionInset, .zero)

        // Products section
        XCTAssertEqual(result[1].identifier, "ProductList")
        XCTAssertEqual(result[1].count, 4, "4 products")
        XCTAssertNotNil(result[1].headerInfo(), "Should have header")
        XCTAssertEqual(result[1].sectionInset, UIEdgeInsets(top: 20, left: 16, bottom: 0, right: 16))
        XCTAssertEqual(result[1].minimumLineSpacing, 10)
        XCTAssertEqual(result[1].minimumInteritemSpacing, 16)
        XCTAssertEqual(result[1].gridColumnCount, 2)

        // Cell data binding verification
        cv.reloadData()

        let bannerCell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 0, section: 0))
        XCTAssertTrue(bannerCell is StandardBannerCell)
        if let bc = bannerCell as? StandardBannerCell {
            XCTAssertEqual(bc.titleLabel.text, "Spring Clearance Sale")
        }

        let productCell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 2, section: 1))
        XCTAssertTrue(productCell is StandardProductCell)
        if let pc = productCell as? StandardProductCell {
            XCTAssertEqual(pc.nameLabel.text, "UNPARALLEL Souped-up")
            XCTAssertEqual(pc.priceLabel.text, "239000원")
        }

        // Header view verification
        let headerView = cv.dataSource?.collectionView?(
            cv,
            viewForSupplementaryElementOfKind: UICollectionView.elementKindSectionHeader,
            at: IndexPath(item: 0, section: 1)
        )
        XCTAssertTrue(headerView is SectionHeaderView)
        if let hv = headerView as? SectionHeaderView {
            XCTAssertEqual(hv.titleLabel.text, "Popular This Week")
        }

        // FlowLayout size verification
        let layout = cv.collectionViewLayout
        let bannerSize = cv.presenter?.collectionView(cv, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 0))
        XCTAssertEqual(bannerSize, CGSize(width: 375, height: 180))

        let productSize = cv.presenter?.collectionView(cv, layout: layout, sizeForItemAt: IndexPath(item: 0, section: 1))
        XCTAssertEqual(productSize, CGSize(width: (375 - 16 * 2 - 16) / 2.0, height: 400))

        let headerSize = cv.presenter?.collectionView(cv, layout: layout, referenceSizeForHeaderInSection: 1)
        XCTAssertEqual(headerSize, CGSize(width: 375, height: 44))
    }

    func test_standard_client_composition_pagination_with_extend_view_model() {
        // Given — First response
        let page0Json = """
        {
            "bannerList": [
                { "id": 1, "title": "Event Banner", "imageUrl": "https://cdn.example.com/event.jpg" }
            ],
            "productList": [
                { "id": 201, "name": "iPhone 15 Pro", "price": 1550000, "discountRate": 0.05, "imageUrl": "https://cdn.example.com/iphonepro.jpg" },
                { "id": 202, "name": "MacBook Pro 14 M3", "price": 2390000, "discountRate": 0.1, "imageUrl": "https://cdn.example.com/macbook.jpg" }
            ],
            "hasNext": true
        }
        """.data(using: .utf8)!

        // Second response (additional products only)
        let page1Json = """
        {
            "bannerList": [],
            "productList": [
                { "id": 203, "name": "AirPods Pro 2", "price": 359000, "discountRate": 0.0, "imageUrl": "https://cdn.example.com/airpods.jpg" },
                { "id": 204, "name": "Apple Watch Ultra 2", "price": 1149000, "discountRate": 0.08, "imageUrl": "https://cdn.example.com/watch.jpg" },
                { "id": 205, "name": "Mac Mini M2", "price": 850000, "discountRate": 0.0, "imageUrl": "https://cdn.example.com/macmini.jpg" }
            ],
            "hasNext": false
        }
        """.data(using: .utf8)!

        let response0 = try! JSONDecoder().decode(StandardResponse.self, from: page0Json)
        let response1 = try! JSONDecoder().decode(StandardResponse.self, from: page1Json)

        let cv = makeCollectionView()

        // When — First load (buildViewModel)
        let result0 = cv.ss.buildViewModel(page: 0, hasNext: response0.hasNext) { builder in
            builder.section("Banner") {
                builder.cells(response0.bannerList, cellType: StandardBannerCell.self)
            }
            builder.section("ProductList") {
                builder.header(
                    StandardHeaderInfo(title: "Popular Apple Products", subtitle: nil),
                    viewType: SectionHeaderView.self
                )
                builder.cells(response0.productList, cellType: StandardProductCell.self)
            }
        }

        // Then — First load verification
        XCTAssertEqual(result0.count, 2)
        XCTAssertEqual(result0[0].count, 1, "1 banner")
        XCTAssertEqual(result0[1].count, 2, "2 products")
        XCTAssertTrue(result0.hasNext)

        // When — Second load (extendViewModel appends to products)
        let result1 = cv.ss.extendViewModel(page: 1, hasNext: response1.hasNext) { builder in
            builder.section("ProductList") {
                builder.cells(response1.productList, cellType: StandardProductCell.self)
            }
        }

        // Then — Second load verification (banner preserved, products merged)
        XCTAssertEqual(result1.count, 2, "Still 2 sections")
        XCTAssertEqual(result1[0].identifier, "Banner")
        XCTAssertEqual(result1[0].count, 1, "Banner unchanged")
        XCTAssertEqual(result1[1].identifier, "ProductList")
        XCTAssertEqual(result1[1].count, 5, "2 + 3 = 5 products merged")
        XCTAssertFalse(result1.hasNext)
        XCTAssertNotNil(result1[1].headerInfo(), "Header should be preserved from page 0")

        // Verify appended product binding
        cv.reloadData()
        let lastProductCell = cv.dataSource?.collectionView(cv, cellForItemAt: IndexPath(item: 4, section: 1))
        XCTAssertTrue(lastProductCell is StandardProductCell)
        if let pc = lastProductCell as? StandardProductCell {
            XCTAssertEqual(pc.nameLabel.text, "Mac Mini M2")
            XCTAssertEqual(pc.priceLabel.text, "850000원")
        }
    }
}
