//
//  XCTest+UICollectionView.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 23.06.2024.
//

import XCTest

@MainActor
extension XCTest {
    /// Attaches the collection view to a window and forces a full layout pass.
    func attachToWindow(_ cv: UICollectionView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        window.addSubview(cv)
        window.makeKeyAndVisible()
        cv.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        cv.setNeedsLayout()
        cv.layoutIfNeeded()
    }

    /// Returns all cell layout attributes sorted by section then item.
    func sortedCellAttributes(
        _ cv: UICollectionView,
        section: Int? = nil
    ) -> [UICollectionViewLayoutAttributes] {
        let allAttrs = cv.collectionViewLayout.layoutAttributesForElements(
            in: CGRect(x: -5000, y: 0, width: 50000, height: 50000)
        ) ?? []
        let cells = allAttrs
            .filter { $0.representedElementCategory == .cell }
            .sorted {
                if $0.indexPath.section != $1.indexPath.section {
                    return $0.indexPath.section < $1.indexPath.section
                }
                return $0.indexPath.item < $1.indexPath.item
            }
        if let section {
            return cells.filter { $0.indexPath.section == section }
        }
        return cells
    }
}
