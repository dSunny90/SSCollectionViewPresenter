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
