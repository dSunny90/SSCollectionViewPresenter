//
//  UICollectionReusableView+Presenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 05.05.2021.
//

import UIKit

extension UICollectionReusableView {
    /// A closure invoked when the view sends an action.
    ///
    /// - Parameters:
    ///   - actionName: A string identifying the type of action.
    ///   - input: An optional value passed by the caller for the action.
    public typealias ActionClosure = (String, Any?) -> Void

    private struct AssociatedKeys {
        nonisolated(unsafe) static var actionClosure: UInt8 = 0
    }

    /// The closure to handle actions sent from this view.
    ///
    /// Assign this closure to respond to actions triggered within the view
    /// without subclassing or adding a delegate.
    public var actionClosure: ActionClosure? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.actionClosure) as? ActionClosure
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionClosure, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    /// The section index of this view within its collection view.
    ///
    /// Traverses the responder chain to locate the parent `UICollectionView`,
    /// then matches this view against visible supplementary views.
    /// Returns `nil` if the view is not currently visible or has no parent
    /// collection view.
    public var sectionIndex: Int? {
        var responder: UIResponder? = self
        while let r = responder {
            if let collectionView = r as? UICollectionView {
                let kinds = [UICollectionView.elementKindSectionHeader, UICollectionView.elementKindSectionFooter]
                for kind in kinds {
                    let indexPaths = collectionView.indexPathsForVisibleSupplementaryElements(ofKind: kind)
                    for indexPath in indexPaths {
                        let view = collectionView.supplementaryView(forElementKind: kind, at: indexPath)
                        if view === self {
                            return indexPath.section
                        }
                    }
                }
                return nil
            }
            responder = r.next
        }
        return nil
    }
}
