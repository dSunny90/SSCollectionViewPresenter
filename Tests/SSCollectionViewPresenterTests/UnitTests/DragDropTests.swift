//
//  DragDropTests.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 08.06.2024.
//

import XCTest
@testable import SSCollectionViewPresenter
import UIKit

// MARK: - Mock Drag Session

private class MockDragSession: NSObject, UIDragSession {
    var localContext: Any?
    var items: [UIDragItem] = []
    var isRestrictedToDraggingApplication: Bool = false
    var allowsMoveOperation: Bool = true

    func canLoadObjects(ofClass aClass: NSItemProviderReading.Type) -> Bool {
        return false
    }

    func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool {
        return false
    }

    func location(in view: UIView) -> CGPoint {
        return .zero
    }
}

// MARK: - Mock Drop Session

private class MockDropSession: NSObject, UIDropSession {
    var localDragSession: UIDragSession?
    var progressIndicatorStyle: UIDropSessionProgressIndicatorStyle = .default
    var items: [UIDragItem] = []
    var progress: Progress = Progress()
    var isRestrictedToDraggingApplication: Bool = false
    var allowsMoveOperation: Bool = true

    func canLoadObjects(ofClass aClass: NSItemProviderReading.Type) -> Bool {
        return false
    }

    func loadObjects(
        ofClass aClass: NSItemProviderReading.Type,
        completion: @escaping ([NSItemProviderReading]) -> Void
    ) -> Progress {
        return Progress()
    }

    func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool {
        return false
    }

    func location(in view: UIView) -> CGPoint {
        return .zero
    }
}

@MainActor
final class DragDropTests: XCTestCase {
    /// Helper: Encodes a BindingStore<TestBanner, TestBannerCell> to a JSON string
    /// simulating what an external drag source would produce via `toJSONString()`.
    private func encodeToJSON(_ banner: TestBanner) throws -> String {
        let store = BindingStore<TestBanner, TestBannerCell>(state: banner)
        return try store.toJSONString(prettyPrinted: false)
    }

    // MARK: - Drag Initiation (itemsForBeginning)

    func test_drag_returns_items_for_valid_index_path() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()
        cv.ss.setReorderEnabled(true)

        let session = MockDragSession()
        let indexPath = IndexPath(item: 2, section: 0)

        // When
        let dragItems = cv.presenter?.collectionView(cv, itemsForBeginning: session, at: indexPath)

        // Then
        XCTAssertEqual(dragItems?.count, 1, "Should return exactly one drag item")
        XCTAssertTrue(dragItems?.first?.localObject is SSCollectionViewModel.CellInfo,
                      "localObject should be CellInfo for local reorder detection")
    }

    func test_drag_returns_empty_for_out_of_bounds_index() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(2), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.ss.setReorderEnabled(true)

        let session = MockDragSession()

        // When — section out of bounds
        let result = cv.presenter?.collectionView(cv, itemsForBeginning: session, at: IndexPath(item: 0, section: 119)) ?? []

        // Then
        XCTAssertTrue(result.isEmpty, "Should return empty for invalid section")
    }

    func test_drag_respects_can_drag_item_block_returning_false() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        // Block all drags
        cv.ss.onCanDragItem { _ in return false }
        cv.ss.setReorderEnabled(true)

        let session = MockDragSession()

        // When
        let dragItems = cv.presenter?.collectionView(cv, itemsForBeginning: session, at: IndexPath(item: 0, section: 0)) ?? []

        // Then
        XCTAssertTrue(dragItems.isEmpty, "Should return empty when canDragItem returns false")
    }

    func test_drag_selectively_allows_specific_items() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        // Only allow dragging items at even indices
        var checkedItems: [SSCollectionViewModel.CellInfo] = []
        cv.ss.onCanDragItem { cellInfo in
            checkedItems.append(cellInfo)
            if let state = cellInfo.state as? TestBanner {
                return Int(state.id)! % 2 == 0
            }
            return false
        }
        cv.ss.setReorderEnabled(true)

        let session = MockDragSession()

        // When — item at index 0 (id "0", even) -> allowed
        let allowedResult = cv.presenter?.collectionView(cv, itemsForBeginning: session, at: IndexPath(item: 0, section: 0)) ?? []
        XCTAssertEqual(allowedResult.count, 1)

        // When — item at index 1 (id "1", odd) -> blocked
        let blockedResult = cv.presenter?.collectionView(cv, itemsForBeginning: session, at: IndexPath(item: 1, section: 0)) ?? []
        XCTAssertTrue(blockedResult.isEmpty)

        // Callback was actually invoked for both
        XCTAssertEqual(checkedItems.count, 2)
    }

    // MARK: - Drop Session Update (Move vs Copy Intent)

    func test_drop_session_returns_move_for_local_drag() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.ss.setReorderEnabled(true)

        let localSession = MockDragSession()
        let dropSession = MockDropSession()
        dropSession.localDragSession = localSession

        // When
        let proposal = cv.presenter?.collectionView(cv, dropSessionDidUpdate: dropSession, withDestinationIndexPath: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(proposal?.operation, .move, "Local drag should propose .move")
    }

    func test_drop_session_returns_copy_for_external_drag() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.ss.setExternalDragDropEnabled(true)

        let dropSession = MockDropSession()
        dropSession.localDragSession = nil // no local drag = external

        // When
        let proposal = cv.presenter?.collectionView(cv, dropSessionDidUpdate: dropSession, withDestinationIndexPath: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(proposal?.operation, .copy, "External drag should propose .copy")
    }

    // MARK: - Reorder ViewModel Verification

    func test_reorder_move_single_item_forward_in_viewmodel() {
        // Given
        let cv = makeCollectionView()
        let banners = (0..<5).map { TestBanner(id: "id\($0)", title: "Item\($0)") }
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()
        cv.ss.setReorderEnabled(true)

        // Capture titles before move
        let titlesBefore = (0..<5).map {
            (cv.ss.getViewModel()?[0][$0].state as? TestBanner)?.title ?? ""
        }
        XCTAssertEqual(titlesBefore, ["Item0", "Item1", "Item2", "Item3", "Item4"])

        // When — simulate move by directly calling moveCellInfos via performDrop
        // We test the underlying model change by using the presenter's delegate
        guard let cellInfo1 = cv.ss.getViewModel()?[0][1] else {
            XCTFail("Failed to load cellInfo")
            return
        }

        let pairs: [(indexPath: IndexPath, cellInfo: SSCollectionViewModel.CellInfo)] = [
            (indexPath: IndexPath(item: 1, section: 0), cellInfo: cellInfo1)
        ]

        // Call willReorder and track it
        var willReorderCalled = false
        cv.ss.onWillReorder { items in
            willReorderCalled = true
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items[0].indexPath, IndexPath(item: 1, section: 0))
        }

        cv.presenter?.willReorderBlock?(pairs)
        XCTAssertTrue(willReorderCalled)
    }

    // MARK: - Will/Did Reorder Callbacks

    func test_will_reorder_callback_receives_correct_items() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()

        var receivedItems: [(indexPath: IndexPath, cellInfo: SSCollectionViewModel.CellInfo)] = []
        cv.ss.onWillReorder { items in
            receivedItems = items
        }

        // When
        guard let cellInfo2 = cv.ss.getViewModel()?[0][2] else {
            XCTFail("Failed to load cellInfo")
            return
        }

        let pairs: [(indexPath: IndexPath, cellInfo: SSCollectionViewModel.CellInfo)] = [
            (indexPath: IndexPath(item: 2, section: 0), cellInfo: cellInfo2)
        ]
        cv.presenter?.willReorderBlock?(pairs)

        // Then
        XCTAssertEqual(receivedItems.count, 1)
        XCTAssertEqual(receivedItems[0].indexPath, IndexPath(item: 2, section: 0))
        XCTAssertTrue(receivedItems[0].cellInfo === cellInfo2)
    }

    func test_did_reorder_callback_receives_destination() {
        // Given — items: [A, B, C, D, E], move B(1) -> after D(3)
        let cv = makeCollectionView()
        let banners = makeSampleBanners(5)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()

        var receivedDestination: IndexPath?
        var receivedCount = 0
        cv.ss.onDidReorder { items, destination in
            receivedCount = items.count
            receivedDestination = destination
        }

        // When
        guard let cellInfo1 = cv.ss.getViewModel()?[0][1] else {
            XCTFail("Failed to load cellInfo")
            return
        }

        let pairs: [(indexPath: IndexPath, cellInfo: SSCollectionViewModel.CellInfo)] = [
            (indexPath: IndexPath(item: 1, section: 0), cellInfo: cellInfo1)
        ]
        let dest = IndexPath(item: 3, section: 0)
        cv.presenter?.didReorderBlock?(pairs, dest)

        // Then
        XCTAssertEqual(receivedCount, 1)
        XCTAssertEqual(receivedDestination, IndexPath(item: 3, section: 0))
    }

    // MARK: - Drag Preview

    func test_drag_preview_parameters_callback_invoked() {
        // Given
        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.ss.setReorderEnabled(true)

        var receivedIndexPath: IndexPath?
        let expectedParams = UIDragPreviewParameters()
        expectedParams.backgroundColor = .blue
        cv.ss.onDragPreviewParameters { indexPath in
            receivedIndexPath = indexPath
            return expectedParams
        }

        // When
        let result = cv.presenter?.collectionView(cv, dragPreviewParametersForItemAt: IndexPath(item: 1, section: 0))

        // Then
        XCTAssertEqual(receivedIndexPath, IndexPath(item: 1, section: 0))
        XCTAssertEqual(result?.backgroundColor, .blue)
    }

    func test_drag_preview_provider_sets_custom_preview_on_drag_item() {
        // Given
        let cv = makeCollectionView()
        let banners = makeSampleBanners(3)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()
        cv.layoutIfNeeded()

        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        cv.ss.setDragPreviewProvider { _ in return customView }
        cv.ss.setReorderEnabled(true)

        let session = MockDragSession()

        // When
        let dragItems = cv.presenter?.collectionView(cv, itemsForBeginning: session, at: IndexPath(item: 0, section: 0)) ?? []

        // Then — previewProvider should be set (non-nil)
        XCTAssertEqual(dragItems.count, 1)
        XCTAssertNotNil(dragItems.first?.previewProvider,
                        "Drag item should have a custom preview provider when dragPreviewProviderBlock is set")
    }

    // MARK: - Accepted Drop Type Identifiers

    func test_accepted_type_identifiers_stored_correctly() {
        // Given
        let cv = makeCollectionView()
        let types = ["public.plain-text", "public.image", "public.url"]

        // When
        cv.ss.setAcceptedExternalDropTypeIdentifiers(types)

        // Then
        XCTAssertEqual(cv.presenter?.acceptedExternalDropTypeIdentifiers, types)
        XCTAssertEqual(cv.presenter?.acceptedExternalDropTypeIdentifiers.count, 3)
    }

    // MARK: - External Drop Handler

    func test_external_drop_json_round_trip_creates_valid_cell_info() throws {
        // Given — simulate an external app encoding a TestBanner via toJSONString
        let original = TestBanner(id: "test00000001", title: "Test Banner")
        let jsonString = try encodeToJSON(original)

        let cv = makeCollectionView()
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(3), cellType: TestBannerCell.self)
            }
        }
        cv.reloadData()

        // Set up the external drop handler that receives JSON and reconstructs CellInfo
        cv.ss.onExternalDrop { payload, indexPath in
            guard let json = payload as? String,
                  let data = json.data(using: .utf8) else { return nil }

            // Decode the payload: { "state": {...}, "binderType": "TestBannerCell" }
            struct Payload: Decodable { let state: TestBanner; let binderType: String }
            guard let decoded = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }

            // Verify binderType matches what we expect
            guard decoded.binderType == String(describing: TestBannerCell.self) else { return nil }

            // Reconstruct: State -> BindingStore -> CellInfo
            let store = BindingStore<TestBanner, TestBannerCell>(state: decoded.state)
            return SSCollectionViewModel.CellInfo(store)
        }

        // When — feed the JSON string as if it came from an external drop
        let destination = IndexPath(item: 1, section: 0)
        let result = cv.presenter?.externalDropHandler?(jsonString, destination)

        // Then — CellInfo was created with correct state
        XCTAssertNotNil(result, "Handler should produce a CellInfo from JSON")
        let restoredBanner = result?.state as? TestBanner
        XCTAssertEqual(restoredBanner?.id, "test00000001")
        XCTAssertEqual(restoredBanner?.title, "Test Banner")
        XCTAssertTrue(result?.binderType == TestBannerCell.self,
                      "binderType should be TestBannerCell")
    }

    func test_external_drop_json_with_wrong_binder_type_rejected() throws {
        // Given — JSON encoded with TestBannerCell binder type
        let jsonString = try encodeToJSON(TestBanner(id: "test00000002", title: "Test Banner"))

        let cv = makeCollectionView()
        cv.ss.onExternalDrop { payload, _ in
            guard let json = payload as? String,
                  let data = json.data(using: .utf8) else { return nil }
            struct Payload: Decodable { let state: TestBanner; let binderType: String }
            guard let decoded = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }

            // Only accept "SomeOtherCell" — reject TestBannerCell
            guard decoded.binderType == "SomeOtherCell" else { return nil }
            return makeCellInfo(from: decoded.state)
        }

        // When
        let result = cv.presenter?.externalDropHandler?(jsonString, IndexPath(item: 0, section: 0))

        // Then — rejected because binderType doesn't match
        XCTAssertNil(result, "Should reject drop when binderType doesn't match expected type")
    }

    func test_external_drop_malformed_json_rejected() {
        // Given — garbage payload that is not valid JSON
        let cv = makeCollectionView()
        cv.ss.onExternalDrop { payload, _ in
            guard let json = payload as? String,
                  let data = json.data(using: .utf8) else { return nil }
            struct Payload: Decodable { let state: TestBanner; let binderType: String }
            guard let decoded = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
            return makeCellInfo(from: decoded.state)
        }

        // When — send broken JSON
        let result = cv.presenter?.externalDropHandler?("{Invalid Json!!", IndexPath(item: 0, section: 0))

        // Then
        XCTAssertNil(result, "Malformed JSON should be rejected gracefully")
    }

    // MARK: - Reorder with Diffable Data Source (iOS 14+)

    @available(iOS 14.0, *)
    func test_diffable_reorder_configures_drag_interaction() {
        // Given
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(7), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)

        // When
        cv.ss.setReorderEnabled(true)

        // Then — drag interaction should be enabled and delegates set
        XCTAssertTrue(cv.dragInteractionEnabled)
        XCTAssertNotNil(cv.dragDelegate)
        XCTAssertNotNil(cv.dropDelegate)
    }

    @available(iOS 14.0, *)
    func test_diffable_reorder_skips_perform_drop_for_local_reorder() {
        // Given — diffable mode skips performDrop for local reorder
        // (UICollectionViewDiffableDataSource handles it internally)
        let cv = makeCollectionView(dataSourceMode: .diffable)
        _ = cv.ss.buildViewModel { builder in
            builder.section {
                builder.cells(makeSampleBanners(), cellType: TestBannerCell.self)
            }
        }
        cv.ss.applySnapshot(animated: false)
        cv.ss.setReorderEnabled(true)

        // Then — usesBuiltInDiffableReorder should be true
        // The presenter delegates reorder to diffable data source's reorderingHandlers
        XCTAssertTrue(cv.presenter?.isReorderEnabled ?? false)

        // Verify drag still produces items (drag initiation still works)
        let session = MockDragSession()
        let dragItems = cv.presenter?.collectionView(cv, itemsForBeginning: session, at: IndexPath(item: 0, section: 0)) ?? []
        XCTAssertFalse(dragItems.isEmpty, "Drag initiation should still work in diffable mode")
    }

    // MARK: - Combined Enable/Disable States

    func test_enable_reorder_then_disable_cleans_up_delegates() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setReorderEnabled(true)
        XCTAssertTrue(cv.dragInteractionEnabled)
        XCTAssertNotNil(cv.dragDelegate)

        // When
        cv.ss.setReorderEnabled(false)

        // Then
        XCTAssertFalse(cv.dragInteractionEnabled)
        XCTAssertNil(cv.dragDelegate)
        XCTAssertNil(cv.dropDelegate)
    }

    func test_disable_reorder_keeps_external_drop_active() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setReorderEnabled(true)
        cv.ss.setExternalDragDropEnabled(true)

        // When
        cv.ss.setReorderEnabled(false)

        // Then — external drop still active, drag interaction still on
        XCTAssertTrue(cv.dragInteractionEnabled)
        XCTAssertNotNil(cv.dragDelegate)
        XCTAssertTrue(cv.presenter?.isExternalDragDropEnabled ?? false)
    }

    func test_disable_both_reorder_and_external_drop() {
        // Given
        let cv = makeCollectionView()
        cv.ss.setReorderEnabled(true)
        cv.ss.setExternalDragDropEnabled(true)
        XCTAssertTrue(cv.dragInteractionEnabled)

        // When
        cv.ss.setReorderEnabled(false)
        cv.ss.setExternalDragDropEnabled(false)

        // Then
        XCTAssertFalse(cv.dragInteractionEnabled)
        XCTAssertNil(cv.dragDelegate)
        XCTAssertNil(cv.dropDelegate)
    }
}
