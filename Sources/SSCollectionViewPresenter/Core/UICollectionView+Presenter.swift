//
//  UICollectionView+Presenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 25.04.2021.
//

import UIKit

extension UICollectionView {
    private struct AssociatedKeys {
        static var registeredCellIdentifiers: UInt8 = 0
        static var registeredHeaderIdentifiers: UInt8 = 0
        static var registeredFooterIdentifiers: UInt8 = 0
        static var presenter: UInt8 = 0
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

    private var contentInsetLeading: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? contentInset.left : contentInset.top
    }

    private var contentInsetTrailing: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? contentInset.right : contentInset.bottom
    }

    private var itemLength: CGFloat {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return 0 }
        return flowLayout.scrollDirection == .horizontal ? flowLayoutItemSize.width : flowLayoutItemSize.height
    }

    private var pageLength: CGFloat { itemLength + flowLayoutLineSpacing }

    private var minOffset: CGFloat { -contentInsetLeading }
    private var maxOffset: CGFloat { contentLength - boundsLength + contentInsetTrailing }

    public func registerDefaultCell() {
        register(UICollectionViewCell.self, forCellWithReuseIdentifier: String(describing: UICollectionViewCell.self))
    }

    public func registerDefaultReusableViews(ofKind kind: String) {
        register(UICollectionReusableView.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: UICollectionReusableView.self))
    }

    public func registerHeader(_ classType: Any.Type, reusableIdentifier: String? = nil, bundle: Bundle? = nil) {
        guard let headerType = classType as? UICollectionReusableView.Type else { return }

        let identifier: String
        if let reusableIdentifier = reusableIdentifier {
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
        if let reusableIdentifier = reusableIdentifier {
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
        if let reusableIdentifier = reusableIdentifier {
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
            withReuseIdentifier: String(describing: UICollectionReusableView.self),
            for: indexPath
        )
    }

    /// Advances contentOffset by one page in the given direction.
    /// - Parameters:
    ///   - steps: positive to go forward, negative to go backward.
    ///   - animated: Whether the scroll should be animated.
    internal func scrollPages(by steps: Int, animated: Bool) {
        guard steps != 0,
              !(currentOffset >= maxOffset && steps > 0),
              !(currentOffset <= minOffset && steps < 0)
        else {
            presenter?.endProgrammaticScrollAnimating()
            return
        }

        let targetOffset: CGFloat = currentOffset + CGFloat(steps) * pageLength

        if targetOffset > maxOffset {
            setContentOffset(value: maxOffset, animated: animated)
        } else if targetOffset < minOffset {
            setContentOffset(value: minOffset, animated: animated)
        } else {
            if steps > 0 && targetOffset + pageLength / 2 > maxOffset {
                setContentOffset(value: maxOffset, animated: animated)
            } else if steps < 0 && targetOffset - pageLength / 2 < minOffset {
                setContentOffset(value: minOffset, animated: animated)
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
