//
//  SSCollectionViewPresenter+DragDrop.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 08.06.2024.
//

import UIKit

// MARK: - UICollectionViewDragDelegate

extension SSCollectionViewPresenter: UICollectionViewDragDelegate {
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let items = viewModel?[safe: indexPath.section]?.items,
              let cellInfo = items[safe: indexPath.item % items.count]
        else { return [] }

        if let canDrag = canDragItemBlock, !canDrag(cellInfo) {
            return []
        }

        let itemProvider: NSItemProvider = {
            if let json = try? cellInfo.toJSONString() {
                NSItemProvider(object: "\(json)" as NSString)
            } else {
                NSItemProvider(object: "\(indexPath)" as NSString)
            }
        }()
        let dragItem = UIDragItem(itemProvider: itemProvider)

        if let view = dragPreviewProviderBlock?(cellInfo) {
            dragItem.previewProvider = { UIDragPreview(view: view) }
        }
        dragItem.localObject = cellInfo

        return [dragItem]
    }

    public func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        return dragPreviewParametersBlock?(indexPath)
    }
}

// MARK: - UICollectionViewDropDelegate

extension SSCollectionViewPresenter: UICollectionViewDropDelegate {
    private typealias ReorderSourceContext = (
        indexPath: IndexPath,
        cellInfo: CellInfo,
        dragItem: UIDragItem
    )

    private var usesBuiltInDiffableReorder: Bool {
        if #available(iOS 14.0, *) {
            return dataSourceMode == .diffable
        } else {
            return false
        }
    }

    public func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(
            operation: .move,
            intent: .insertAtDestinationIndexPath
        )
    }

    public func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let isLocalReorder =
                coordinator.proposal.operation == .move &&
                coordinator.items.allSatisfy { $0.sourceIndexPath != nil }

        // iOS 14+ uses diffable snapshot automatically elsewhere.
        guard !(usesBuiltInDiffableReorder && isLocalReorder) else { return }

        let destination: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destination = indexPath
        } else {
            let section = collectionView.numberOfSections - 1
            let item = collectionView.numberOfItems(inSection: section)
            destination = IndexPath(item: item, section: section)
        }

        let sourceItems: [ReorderSourceContext] = coordinator.items.compactMap {
            guard let source = $0.sourceIndexPath,
                  let item = $0.dragItem.localObject as? CellInfo
            else { return nil }
            return (
                indexPath: source,
                cellInfo: item,
                dragItem: $0.dragItem
            )
        }
        let items = sourceItems.map {
            (indexPath: $0.indexPath, cellInfo: $0.cellInfo)
        }

        self.willReorderBlock?(items)

        let insertedIndexPaths = moveCellInfos(items, to: destination)
        if dataSourceMode == .traditional {
            collectionView.performBatchUpdates {
                collectionView.deleteItems(at: sourceItems.map(\.indexPath))
                collectionView.insertItems(at: insertedIndexPaths)
            }
        } else if #available(iOS 13.0, *) {
            applySnapshot(animated: true)
        }

        for (item, indexPath) in zip(sourceItems, insertedIndexPaths) {
            coordinator.drop(item.dragItem, toItemAt: indexPath)
        }

        self.didReorderBlock?(items, destination)
    }

    private func moveCellInfos(
        _ pairs: [(indexPath: IndexPath, cellInfo: CellInfo)],
        to destination: IndexPath
    ) -> [IndexPath] {
        guard var newViewModel = self.viewModel, !pairs.isEmpty else { return [] }

        let sortedSourcesDescending = pairs
            .map(\.indexPath)
            .sorted {
                if $0.section != $1.section {
                    return $0.section > $1.section
                }
                return $0.item > $1.item
            }

        let movedItems = pairs
            .sorted {
                if $0.indexPath.section != $1.indexPath.section {
                    return $0.indexPath.section < $1.indexPath.section
                }
                return $0.indexPath.item < $1.indexPath.item
            }
            .map(\.cellInfo)

        let removedBeforeDestinationCount = pairs.reduce(into: 0) { count, pair in
            guard pair.indexPath.section == destination.section else { return }
            if pair.indexPath.item < destination.item {
                count += 1
            }
        }

        for source in sortedSourcesDescending {
            newViewModel[source.section].remove(at: source.item)
        }

        let adjustedDestinationItem: Int
        if destination.section < newViewModel.count {
            adjustedDestinationItem = max(
                0,
                min(
                    destination.item - removedBeforeDestinationCount,
                    newViewModel[destination.section].count
                )
            )
        } else {
            adjustedDestinationItem = 0
        }

        for (offset, item) in movedItems.enumerated() {
            newViewModel[destination.section].insert(
                item,
                at: adjustedDestinationItem + offset
            )
        }

        self.viewModel = newViewModel

        return movedItems.enumerated().map {
            IndexPath(item: adjustedDestinationItem + $0.offset,
                      section: destination.section)
        }
    }
}
