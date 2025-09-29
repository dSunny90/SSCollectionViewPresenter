//
//  UICollectionView+Presenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 01.11.2022.
//

import UIKit

extension UICollectionView {
    private struct AssociatedKeys {
        nonisolated(unsafe) static var registeredCellIdentifiers: UInt8 = 0
        nonisolated(unsafe) static var registeredHeaderIdentifiers: UInt8 = 0
        nonisolated(unsafe) static var registeredFooterIdentifiers: UInt8 = 0
        nonisolated(unsafe) static var presenter: UInt8 = 0
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

    /// Item size resolved from delegate (if any) or the flow layout itself.
    /// Falls back to `bounds.size` when nothing is provided.
    internal var flowLayoutItemSize: CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return bounds.size }

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

    /// Returns fractional page index from current offset.
    internal var currentPage: CGFloat {
        guard pageLength > 0 else { return 0 }

        var adjustedOffset = currentOffset - sectionInsetLeading
        if isAlignCenter {
            adjustedOffset += (boundsLength - itemLength) / 2
        }
        return adjustedOffset / pageLength
    }

    /// Returns the first fractional page index.
    internal var firstPage: CGFloat { return 0 }

    /// Returns the last fractional page index.
    internal var lastPage:CGFloat {
        guard pageLength > 0 else { return 0 }

        return (sectionLength + flowLayoutLineSpacing) / pageLength - 1
    }

    internal var boundsLength: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? bounds.width : bounds.height
    }

    internal var contentLength: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? contentSize.width : contentSize.height
    }

    internal var currentOffset: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? contentOffset.x : contentOffset.y
    }

    private var isAlignCenter: Bool { presenter?.isAlignCenter ?? false }
    private var isLooping: Bool { presenter?.isLooping ?? false }

    private var contentInsetLeading: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? contentInset.left : contentInset.top
    }

    private var contentInsetTrailing: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? contentInset.right : contentInset.bottom
    }

    private var sectionInsetLeading: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? flowLayoutSectionInset.left : flowLayoutSectionInset.top
    }

    private var sectionInsetTrailing: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? flowLayoutSectionInset.right : flowLayoutSectionInset.bottom
    }

    private var itemLength: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? flowLayoutItemSize.width : flowLayoutItemSize.height
    }

    private var pageLength: CGFloat { itemLength + flowLayoutLineSpacing }
    private var sectionLength: CGFloat { contentLength - (sectionInsetLeading + sectionInsetTrailing) }

    private var baseOffset: CGFloat { contentInsetLeading - sectionInsetLeading }
    private var minOffset: CGFloat { -contentInsetLeading }
    private var maxOffset: CGFloat { contentLength - boundsLength + contentInsetTrailing }

    private var isOverMinOffset: Bool { isAlignCenter ? (currentOffset <= centerInitialOffset) : (currentOffset <= minOffset) }
    private var isOverMaxOffset: Bool { isAlignCenter ? (currentOffset >= centerFinalOffset) : (currentOffset >= maxOffset) }

    private var centerInitialOffset: CGFloat { sectionInsetLeading - (boundsLength - itemLength) / 2 }
    private var centerCurrentOffset: CGFloat { sectionInsetLeading + currentPage.rounded() * (itemLength + flowLayoutLineSpacing) - (boundsLength - itemLength) / 2 }
    private var centerFinalOffset: CGFloat { sectionInsetLeading + lastPage * (itemLength + flowLayoutLineSpacing) - (boundsLength - itemLength) / 2 }

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

    /// Sets the initial content offset for the first item.
    ///
    /// - Behavior:
    ///   - If `isAlignCenter` is true, centers the first item.
    ///   - Otherwise, scrolls to the leading edge (respects content inset).
    /// - Parameter animated: Whether to animate the offset change.
    internal func setInitialOffsetIfNeeded(animated: Bool) {
        if isAlignCenter {
            setContentOffset(value: max(minOffset, centerInitialOffset), animated: animated)
        } else {
            setContentOffset(value: minOffset, animated: animated)
        }
    }

    /// Sets the final content offset for the last item.
    ///
    /// - Behavior:
    ///   - If `isAlignCenter` is true, centers the last item.
    ///   - Otherwise, aligns the last page with the trailing edge.
    /// - Parameter animated: Whether to animate the offset change.
    internal func setFinalOffsetIfNeeded(animated: Bool) {
        if isAlignCenter {
            setContentOffset(value: min(maxOffset, centerFinalOffset), animated: animated)
        } else {
            setContentOffset(value: maxOffset, animated: animated)
        }
    }

    /// Re-centers contentOffset near duplicated edges to maintain infinite scroll.
    internal func remapContentOffsetIfNeeded() {
        guard let segments = presenter?.duplicatedItemCount else { return }

        let lowerBound: CGFloat = {
            let margins = flowLayoutLineSpacing * CGFloat(segments - 1)
            let segmentLength = (sectionLength - margins) / CGFloat(segments)
            return segmentLength + flowLayoutLineSpacing
        }()
        let upperBound = lowerBound * CGFloat(segments - 1)

        guard !isOverMinOffset else {
            let firstOffset: CGFloat = isAlignCenter ? centerInitialOffset : currentOffset
            setContentOffset(
                value: firstOffset + lowerBound,
                animated: false
            )
            return
        }

        var checkOffset = baseOffset + currentOffset
        if isAlignCenter {
            checkOffset += max(0, (boundsLength - itemLength - (contentInsetLeading + contentInsetTrailing)) / 2)
        }

        if checkOffset < lowerBound {
            setContentOffset(
                value: currentOffset + lowerBound,
                animated: false
            )
        } else if checkOffset >= upperBound {
            setContentOffset(
                value: currentOffset - lowerBound,
                animated: false
            )
        }
    }

    /// Computes and snaps the target content offset for paging based on swipe
    /// velocity and the current flow layout, and writes the result into
    /// targetContentOffset.
    ///
    /// - Note: When a user drags beyond the minimum or maximum scrollable range,
    ///         the scroll view will bounce back to the nearest valid offset.
    ///         If your goal is simply to keep items centered, you can often
    ///         achieve it by giving the section insets generous values
    ///         instead of adding extra paging logic.
    ///
    /// - Parameters:
    ///   - velocity: Scrolling velocity in points/second. Used to bias toward
    ///               next/previous page (ceil/floor) on a fast flick.
    ///   - targetContentOffset: A pointer to the target content offset provided
    ///     by UIScrollViewDelegate; this method updates its pointee to the
    ///     computed page-aligned value.
    internal func remapTargetContentOffset(withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let scrollDirection = (collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection else { return }

        var checkOffset: CGFloat = baseOffset
        if isAlignCenter {
            checkOffset += (boundsLength - itemLength) / 2
        }

        let velocityValue = scrollDirection == .horizontal ? velocity.x : velocity.y
        let targetOffset = currentOffset + velocityValue * 60.0
        var targetIndex = (checkOffset + targetOffset) / pageLength

        if velocityValue > 0 {
            targetIndex = ceil(targetIndex)
        } else if velocityValue < 0 {
            targetIndex = floor(targetIndex)
        } else {
            let (maxFloorIndex, lastInterval) = modf(lastPage)
            if targetIndex > maxFloorIndex {
                targetIndex = (targetIndex >= lastInterval / 2 + maxFloorIndex) ? lastPage : maxFloorIndex
            } else {
                targetIndex = round(targetIndex)
            }
        }

        let offset: CGFloat

        if targetIndex >= lastPage {
            offset = maxOffset
        } else if targetIndex <= firstPage {
            offset = minOffset
        } else {
            if isAlignCenter {
                offset = centerInitialOffset + pageLength * targetIndex
            } else {
                offset = minOffset + pageLength * targetIndex
            }
        }

        if scrollDirection == .horizontal {
            targetContentOffset.pointee.x = offset
        } else {
            targetContentOffset.pointee.y = offset
        }
    }

    /// Advances contentOffset by one page in the given direction.
    /// - Parameters:
    ///   - steps: positive to go forward, negative to go backward.
    ///   - animated: Whether the scroll should be animated.
    internal func scrollPages(by steps: Int, animated: Bool) {
        guard steps != 0
        else {
            presenter?.endProgrammaticScrollAnimating()
            return
        }

        guard !(isOverMaxOffset && steps > 0) else {
            if isLooping {
                setInitialOffsetIfNeeded(animated: animated)
            } else {
                presenter?.endProgrammaticScrollAnimating()
            }
            return
        }

        guard !(isOverMinOffset && steps < 0) else {
            if isLooping {
                setFinalOffsetIfNeeded(animated: animated)
            } else {
                presenter?.endProgrammaticScrollAnimating()
            }
            return
        }

        let targetOffset: CGFloat
        if isAlignCenter, currentPage.truncatingRemainder(dividingBy: 1) != 0 {
            targetOffset = centerCurrentOffset + CGFloat(steps) * pageLength
        } else {
            targetOffset = currentOffset + CGFloat(steps) * pageLength
        }

        if targetOffset > maxOffset {
            setFinalOffsetIfNeeded(animated: animated)
        } else if targetOffset < minOffset {
            setInitialOffsetIfNeeded(animated: animated)
        } else {
            if steps > 0 && targetOffset + pageLength / 2 > maxOffset {
                setFinalOffsetIfNeeded(animated: animated)
            } else if steps < 0 && targetOffset - pageLength / 2 < minOffset {
                setInitialOffsetIfNeeded(animated: animated)
            } else {
                setContentOffset(value: targetOffset, animated: animated)
            }
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

    /// Sets the contentOffset to the given value along the current scroll axis.
    ///
    /// - Parameters:
    ///   - value: The offset value to apply on the horizontal or vertical axis.
    ///   - animated: Whether to animate the offset change.
    private func setContentOffset(value: CGFloat, animated: Bool) {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let currentOffset = contentOffset
        if flowLayout.scrollDirection == .horizontal {
            setContentOffset(CGPoint(x: value, y: currentOffset.y), animated: animated)
        } else {
            setContentOffset(CGPoint(x: currentOffset.x, y: value), animated: animated)
        }
    }
}
