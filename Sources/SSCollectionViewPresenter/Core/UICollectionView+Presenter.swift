//
//  UICollectionView+Presenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 01.11.2022.
//

import UIKit

extension UICollectionView {
    private struct AssociatedKeys {
        nonisolated(unsafe) static var presenter: UInt8 = 0
        nonisolated(unsafe) static var registeredCellIdentifiers: UInt8 = 0
        nonisolated(unsafe) static var registeredHeaderIdentifiers: UInt8 = 0
        nonisolated(unsafe) static var registeredFooterIdentifiers: UInt8 = 0
    }

    internal var presenter: SSCollectionViewPresenter? {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.presenter) as? SSCollectionViewPresenter {
                return obj
            } else {
                return nil
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.presenter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var registeredCellIdentifiers: Set<String> {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.registeredCellIdentifiers) as? Set<String> {
                return obj
            }
            let obj = Set<String>(minimumCapacity: 200)
            objc_setAssociatedObject(self, &AssociatedKeys.registeredCellIdentifiers, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return obj
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.registeredCellIdentifiers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var registeredHeaderIdentifiers: Set<String> {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.registeredHeaderIdentifiers) as? Set<String> {
                return obj
            }
            let obj = Set<String>(minimumCapacity: 200)
            objc_setAssociatedObject(self, &AssociatedKeys.registeredHeaderIdentifiers, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return obj
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.registeredHeaderIdentifiers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public var registeredFooterIdentifiers: Set<String> {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.registeredFooterIdentifiers) as? Set<String> {
                return obj
            }
            let obj = Set<String>(minimumCapacity: 200)
            objc_setAssociatedObject(self, &AssociatedKeys.registeredFooterIdentifiers, obj, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return obj
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.registeredFooterIdentifiers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Item size resolved from delegate (if any) or the flow layout itself.
    /// Falls back to `bounds.size` when nothing is provided.
    internal var flowLayoutItemSize: CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return bounds.size
        }
        // Prefer a visible section if we have one; otherwise use section 0.
        let section = indexPathsForVisibleItems.sorted().first?.section ?? 0
        let firstIndexPath = IndexPath(item: 0, section: section)

        // 1. Delegate override?
        if let size = (delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(self, layout: flowLayout, sizeForItemAt: firstIndexPath) {
            return size
        }
        // 2. Layout’s fixed itemSize?
        if flowLayout.itemSize.width > 0, flowLayout.itemSize.height > 0 {
            return flowLayout.itemSize
        }
        // 3. Estimated size (self-sizing) as a hint
        if flowLayout.estimatedItemSize.width > 0, flowLayout.estimatedItemSize.height > 0 {
            return flowLayout.estimatedItemSize
        }
        // 4. Sensible fallback
        return bounds.size
    }

    /// Minimum line spacing resolved from delegate -> layout default.
    internal var flowLayoutLineSpacing: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        let section = indexPathsForVisibleItems.sorted().first?.section ?? 0

        // 1. Delegate override?
        if let spacing = (delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(self, layout: flowLayout, minimumLineSpacingForSectionAt: section) {
            return spacing
        }
        // 2. Layout default
        return flowLayout.minimumLineSpacing
    }

    /// Section inset resolved from delegate -> layout default -> .zero.
    internal var flowLayoutSectionInset: UIEdgeInsets {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        let section = indexPathsForVisibleItems.sorted().first?.section ?? 0

        // 1. Delegate override?
        if let inset = (delegate as? UICollectionViewDelegateFlowLayout)?.collectionView?(self, layout: flowLayout, insetForSectionAt: section) {
            return inset
        }
        // 2. Layout default
        return flowLayout.sectionInset
    }

    public func registerDefaultCell() {
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
    }

    public func registerDefaultReusableViews(ofKind kind: String) {
        register(UICollectionReusableView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: UICollectionReusableView.self))
    }

    public func registerHeader(_ classType: Any.Type, reusableIdentifier: String? = nil, bundle: Bundle? = nil) {
        guard let headerType = classType as? UICollectionReusableView.Type else { return }
        let identifier: String
        if let reusableIdentifier {
            identifier = reusableIdentifier
        } else {
            identifier = String(describing: headerType)
        }
        guard registeredHeaderIdentifiers.contains(identifier) == false else { return }
        registeredHeaderIdentifiers.insert(identifier)
        if isNibFileExists(identifier, bundle: bundle) {
            let nib = UINib(nibName: identifier, bundle: bundle)
            register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: identifier)
        } else {
            register(headerType, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: identifier)
        }
    }

    public func registerFooter(_ classType: Any.Type, reusableIdentifier: String? = nil, bundle: Bundle? = nil) {
        guard let footerType = classType as? UICollectionReusableView.Type else { return }
        let identifier: String
        if let reusableIdentifier {
            identifier = reusableIdentifier
        } else {
            identifier = String(describing: footerType)
        }
        guard registeredFooterIdentifiers.contains(identifier) == false else { return }
        registeredFooterIdentifiers.insert(identifier)
        if isNibFileExists(identifier, bundle: bundle) {
            let nib = UINib(nibName: identifier, bundle: bundle)
            register(nib, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: identifier)
        } else {
            register(footerType, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: identifier)
        }
    }

    public func registerCell(_ classType: Any.Type, reusableIdentifier: String? = nil, for bundle: Bundle? = nil) {
        guard let cellType = classType as? UICollectionViewCell.Type else { return }
        let identifier: String
        if let reusableIdentifier {
            identifier = reusableIdentifier
        } else {
            identifier = String(describing: cellType)
        }
        guard registeredCellIdentifiers.contains(identifier) == false else { return }
        registeredCellIdentifiers.insert(identifier)
        if isNibFileExists(identifier, bundle: bundle) {
            let nib = UINib(nibName: identifier, bundle: bundle)
            register(nib, forCellWithReuseIdentifier: identifier)
        } else {
            register(cellType, forCellWithReuseIdentifier: identifier)
        }
    }

    public func dequeueDefaultCell(for indexPath: IndexPath) -> UICollectionViewCell {
        return dequeueReusableCell(
            withReuseIdentifier: String(describing: UICollectionViewCell.self),
            for: indexPath
        )
    }

    public func dequeueDefaultSupplementaryView(ofKind kind: String, for indexPath: IndexPath) -> UICollectionReusableView {
        return dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: String(describing: UICollectionViewCell.self),
            for: indexPath
        )
    }

    /// Remaps the content offset to the middle section if the scroll offset
    /// moves too close to either duplicated edge (beginning or end).
    ///
    /// This is used to create an "infinite scroll" effect by jumping
    /// back to the logical center of the content when needed.
    ///
    /// - Parameter isAlignCenter: If `true`, offsets are remapped so that
    ///                            the current item snaps to the viewport center
    ///                            (content-inset aware) after remap.
    internal func remapContentOffsetIfNeeded(duplicatedItemCount: Int = 3, isAlignCenter: Bool = false) {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let itemSize = flowLayoutItemSize
        let lineSpacing = flowLayoutLineSpacing
        let sectionInset = flowLayoutSectionInset
        let currentOffset = contentOffset

        if flowLayout.scrollDirection == .horizontal {
            // Width of a single tiled segment in a 3-part infinite layout:
            // (total content width) − (side insets) − (gap between the 3 segments = 2 * lineSpacing), then / 3.
            let segments = duplicatedItemCount
            let gaps = CGFloat(segments - 1)
            let boundOffset = ceil(
                (contentSize.width
                 - sectionInset.left - sectionInset.right
                 - (lineSpacing * gaps)) / CGFloat(segments)
            )
            // Center shift needed to keep the current item visually centered.
            let visibleWidth = bounds.width - contentInset.left - contentInset.right
            let centerShift: CGFloat = isAlignCenter ? max(0, (visibleWidth - itemSize.width) / 2) : 0
            // ---- Left boundary: we drifted into the left segment -> jump forward into the middle
            if currentOffset.x < sectionInset.left + boundOffset - centerShift {
                // Move forward by one segment (+ spacing), optionally minus center shift.
                setContentOffset(CGPoint(x: currentOffset.x + boundOffset + lineSpacing - centerShift, y: currentOffset.y), animated: false)
                reloadData()
            }
            // ---- Right boundary: we drifted into the right segment → jump back to the middle
            else if currentOffset.x > sectionInset.left + boundOffset * 2 + centerShift + lineSpacing {
                // Snap to the start of the middle segment (plus spacing), optionally plus center shift.
                setContentOffset(CGPoint(x: boundOffset + lineSpacing + centerShift, y: currentOffset.y), animated: false)
                reloadData()
            }
        } else {
            // Vertical variant: same idea as horizontal, but with heights/Y-axis.
            let segments = duplicatedItemCount
            let gaps = CGFloat(segments - 1)
            let boundOffset = ceil(
                (contentSize.height
                 - sectionInset.top - sectionInset.bottom
                 - (lineSpacing * gaps)) / CGFloat(segments)
            )
            let visibleHeight = bounds.height - contentInset.top - contentInset.bottom
            let centerShift: CGFloat = isAlignCenter ? max(0, (visibleHeight - itemSize.height) / 2) : 0
            // ---- Top boundary -> jump down into the middle
            if currentOffset.y < sectionInset.top + boundOffset {
                setContentOffset(CGPoint(x: currentOffset.x, y: currentOffset.y + boundOffset + lineSpacing - centerShift), animated: false)
                reloadData()
            }
            // ---- Bottom boundary → jump up into the middle
            else if currentOffset.y > sectionInset.top + boundOffset * 2 + lineSpacing {
                setContentOffset(CGPoint(x: currentOffset.x, y: boundOffset + lineSpacing + centerShift), animated: false)
                reloadData()
            }
        }
    }

    /// Computes the target **contentOffset (single axis)** to use inside
    /// `scrollViewWillEndDragging(_:withVelocity:targetContentOffset:)`,
    /// snapping to the nearest page and optionally center-aligning the page.
    ///
    /// - Parameters:
    ///   - velocity: Scrolling velocity in points/second. Used to bias toward
    ///               next/previous page (ceil/floor) on a fast flick.
    ///   - isAlignCenter: If `true`, returns an offset that centers the page
    ///                    (content-inset aware).
    ///                    If `false`, aligns to the leading edge.
    /// - Returns: The axis offset to set on `targetContentOffset.pointee`
    ///            (`x` when horizontal, `y` when vertical).
    internal func getRemappedTargetContentOffset(velocity: CGPoint, isAlignCenter: Bool = false) -> CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }

        let itemSize = flowLayoutItemSize
        let lineSpacing = flowLayoutLineSpacing
        let sectionInset = flowLayoutSectionInset

        if flowLayout.scrollDirection == .horizontal {
            // 1. Project a tentative x-offset using velocity (tunable factor 60.0)
            let targetOffset: CGFloat = contentOffset.x + velocity.x * 60.0
            // 2. Page size (center-to-center in this implementation)
            let pageWidth: CGFloat = itemSize.width + lineSpacing
            guard pageWidth > 0 else { return 0 }
            // 3. Convert to fractional page index (inset-aware)
            var targetIndex = (targetOffset + contentInset.left - sectionInset.left) / pageWidth
            // 4. Clamp so we don't jump more than one page relative to the current one
            targetIndex = max(targetIndex, floor(currentPage()))
            targetIndex = min(targetIndex, ceil(currentPage()))
            // 5. Compute the maximum legal offset/index (bounds/end protection)
            let maxOffset = contentSize.width - pageWidth + contentInset.right + sectionInset.right
            let maxIndex = (maxOffset + contentInset.left - sectionInset.left) / pageWidth
            // 6. Bias by swipe direction (fast flick -> commit to next/prev page)
            if velocity.x > 0 {
                targetIndex = ceil(targetIndex)
            } else if velocity.x < 0 {
                targetIndex = floor(targetIndex)
            } else {
                // No significant velocity: round to the nearest, with tail handling for the last partial page
                let (maxFloorIndex, lastInterval) = modf(maxIndex)
                if targetIndex > maxFloorIndex {
                    targetIndex = (targetIndex >= lastInterval / 2 + maxFloorIndex) ? maxIndex : maxFloorIndex
                } else {
                    targetIndex = round(targetIndex)
                }
            }

            if targetIndex < 0 { targetIndex = 0 }
            // 7. Convert page index → contentOffset.x
            var offset: CGFloat = 0
            if isAlignCenter {
                if targetIndex > 0 {
                    // Center snap: compute the first centered position, then step by page width
                    let firstOffset = sectionInset.left + pageWidth + lineSpacing - (bounds.width - pageWidth) / 2
                    offset = firstOffset + (pageWidth + lineSpacing) * (targetIndex - 1)
                } else {
                    offset = 0
                }
            } else {
                // Leading-edge alignment
                offset = targetIndex * pageWidth - contentInset.left
            }
            // 8. Clamp to content bounds
            offset = min(offset, maxOffset)
            return offset
        } else {
            // -------- Vertical variant --------
            let targetOffset: CGFloat = contentOffset.y + velocity.y * 60.0
            let pageHeight: CGFloat = itemSize.height + lineSpacing
            guard pageHeight > 0 else { return 0 }

            var targetIndex = (targetOffset + contentInset.top - sectionInset.top) / pageHeight

            targetIndex = max(targetIndex, floor(currentPage()))
            targetIndex = min(targetIndex, ceil(currentPage()))

            let maxOffset = contentSize.height - pageHeight + contentInset.bottom + sectionInset.bottom
            let maxIndex = (maxOffset + contentInset.top - sectionInset.top) / pageHeight

            if velocity.y > 0 {
                targetIndex = ceil(targetIndex)
            } else if velocity.y < 0 {
                targetIndex = floor(targetIndex)
            } else {
                let (maxFloorIndex, lastInterval) = modf(maxIndex)
                if targetIndex > maxFloorIndex {
                    targetIndex = (targetIndex >= lastInterval / 2 + maxFloorIndex) ? maxIndex : maxFloorIndex
                } else {
                    targetIndex = round(targetIndex)
                }
            }

            if targetIndex < 0 { targetIndex = 0 }

            var offset: CGFloat = 0
            if isAlignCenter {
                if targetIndex > 0 {
                    let firstOffset = sectionInset.top + pageHeight + lineSpacing - (bounds.height - pageHeight) / 2
                    offset = firstOffset + (pageHeight + lineSpacing) * (targetIndex - 1)
                } else {
                    offset = 0
                }
            } else {
                offset = targetIndex * pageHeight - contentInset.top
            }

            offset = min(offset, maxOffset)
            return offset
        }
    }

    /// Advances the `contentOffset` by **one page** for auto-rolling mode.
    ///
    /// This method is intended to be called periodically (e.g., via `perform`)
    /// to simulate automatic carousel-style scrolling behavior.
    ///
    /// - Parameter isAlignCenter: If `true`, compute the next offset
    ///                            so the item appears centered at rest
    ///                            (content-inset–aware).
    ///                            If `false`, align to the leading edge.
    internal func setAutoRollingContentOffset(isAlignCenter: Bool = false) {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }

        let itemSize = flowLayoutItemSize
        let lineSpacing = flowLayoutLineSpacing
        let sectionInset = flowLayoutSectionInset

        if flowLayout.scrollDirection == .horizontal {
            // One page width used for indexing/projection.
            let pageWidth: CGFloat = itemSize.width + lineSpacing
            guard pageWidth > 0 else { return }

            let nextIndex: CGFloat
            let nextOffset: CGFloat

            if isAlignCenter {
                // Stabilize to half-step (… , n.0, n.5, …) so small float noise doesn’t
                // push us across page thresholds. Example: 20.49/20.51 -> 20.5.
                let adjustedIndex = snap((contentOffset.x + lineSpacing) / pageWidth, toStep: 0.5)
                // Move to the next integer page from the half-step anchor.
                nextIndex = floor(adjustedIndex + 0.5) + 1

                if nextIndex > 0 {
                    // First centered position for page 1:
                    //   left inset + first page + spacing − half of (visible − page)
                    // Then step by (pageWidth + spacing) per page.
                    let firstOffset = sectionInset.left + pageWidth + lineSpacing - (bounds.width - pageWidth) / 2
                    nextOffset = firstOffset + (pageWidth + lineSpacing) * (nextIndex - 1)
                } else {
                    // Page 0 anchor
                    nextOffset = sectionInset.left
                }
            } else {
                // Leading-edge alignment: simple page multiple.
                nextIndex = floor((contentOffset.x + lineSpacing) / pageWidth) + 1
                nextOffset = sectionInset.left + nextIndex * pageWidth
            }

            // Clamp/wrap when over-scrolling past content end.
            let maxOffset = contentSize.width - pageWidth + contentInset.right + sectionInset.right
            guard nextOffset <= contentSize.width else {
                setContentOffset(CGPoint(x: sectionInset.left, y: 0), animated: true)
                return
            }

            setContentOffset(CGPoint(x: min(nextOffset, maxOffset), y: 0), animated: true)
        } else {
            // -------- Vertical variant --------
            let pageHeight: CGFloat = itemSize.height + lineSpacing
            guard pageHeight > 0 else { return }

            let nextIndex: CGFloat
            let nextOffset: CGFloat

            if isAlignCenter {
                let adjustedIndex = snap((contentOffset.y + lineSpacing) / pageHeight, toStep: 0.5)
                nextIndex = floor(adjustedIndex + 0.5) + 1

                if nextIndex > 0 {
                    let firstOffset = sectionInset.top + pageHeight + lineSpacing - (bounds.height - pageHeight) / 2
                    nextOffset = firstOffset + (pageHeight + lineSpacing) * (nextIndex - 1)
                } else {
                    nextOffset = sectionInset.top
                }
            } else {
                nextIndex = floor((contentOffset.y + lineSpacing) / pageHeight) + 1
                nextOffset = sectionInset.top + nextIndex * pageHeight
            }

            let maxOffset = contentSize.height - pageHeight + contentInset.bottom + sectionInset.bottom
            guard nextOffset <= contentSize.height else {
                setContentOffset(CGPoint(x: 0, y: sectionInset.top), animated: true)
                return
            }
            setContentOffset(CGPoint(x: 0, y: min(nextOffset, maxOffset)), animated: true)
        }
    }

    /// Returns the **fractional page index** based on the current `contentOffset`,
    /// using the FlowLayout’s item size and line spacing (0-based, inset-aware).
    /// Example: 3.0 = page 3 exactly; 3.4 = 40% toward page 4.
    ///
    /// - Returns: Fractional page index along the scrolling axis.
    ///            `0` if unavailable.
    internal func currentPage() -> CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }

        let itemSize = flowLayoutItemSize
        let lineSpacing = flowLayoutLineSpacing
        let sectionInset = flowLayoutSectionInset

        if flowLayout.scrollDirection == .horizontal {
            let pageWidth = itemSize.width + lineSpacing
            guard pageWidth > 0 else { return 0 }
            // Inset-aware leading alignment; subtract spacing so page 0 starts at 0
            return (contentOffset.x + contentInset.left - sectionInset.left - lineSpacing) / pageWidth
        } else {
            let pageHeight = itemSize.height + lineSpacing
            guard pageHeight > 0 else { return 0 }
            return (contentOffset.y + contentInset.top - sectionInset.top - lineSpacing) / pageHeight
        }
    }

    /// Checks whether a `.nib` file with the given name exists in the specified bundle.
    /// Falls back to `Bundle.main` when `bundle` is `nil`.
    ///
    /// - Parameters:
    ///   - nibName: The nib file name without extension.
    ///   - bundle:  The bundle to search in (defaults to main bundle).
    /// - Returns: `true` if the nib file exists on disk; otherwise `false`.
    /// - Note: This only checks for presence; it does not load the nib.
    ///         If you’re using Swift Package resources, consider `Bundle.module`.
    private func isNibFileExists(_ nibName: String, bundle: Bundle? = nil) -> Bool {
        // Resolve bundle (explicit or main)
        let aBundle = bundle ?? .main

        // Lookup the path for "<nibName>.nib" and verify it exists
        if let path = aBundle.path(forResource: nibName, ofType: "nib") {
            return FileManager.default.fileExists(atPath: path)
        }
        return false
     }
}

/// Snaps a scalar to the nearest multiple of `step`.
/// Uses **banker’s rounding** (`.toNearestOrEven`) to reduce tie bias.
/// Example: `snap(20.51, 0.5) → 20.5`, `snap(20.75, 0.5) → 21.0`,
///          `snap(20.25, 0.5) → 20.0` (ties go to even).
///
/// - Parameters:
///   - x: Value to snap.
///   - step: Step size (> 0).
/// - Returns: `x` rounded to the nearest multiple of `step` (or `x` if invalid).
@inline(__always)
private func snap(_ x: CGFloat, toStep step: CGFloat) -> CGFloat {
    guard step > 0, x.isFinite else { return x }
    let inv = 1 / step
    return (x * inv).rounded(.toNearestOrEven) / inv
}
