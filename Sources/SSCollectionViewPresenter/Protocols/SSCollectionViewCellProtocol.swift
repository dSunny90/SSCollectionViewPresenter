//
//  SSCollectionViewCellProtocol.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 05.05.2021.
//

import UIKit

/// A protocol that extends display lifecycle callbacks with interaction
/// events for a collection view cell.
public protocol InteractiveCollectionViewCell: InteractiveCollectionReusableView {
    /// Returns whether the view should be highlighted.
    func shouldHighlight(with input: Input?) -> Bool

    /// Returns whether the view should be selected.
    func shouldSelect(with input: Input?) -> Bool

    /// Returns whether the view should be deselected.
    func shouldDeselect(with input: Input?) -> Bool

    /// Called when the view is highlighted (e.g., on touch down).
    func didHighlight(with input: Input?)

    /// Called when the view is unhighlighted (e.g., on touch up).
    func didUnhighlight(with input: Input?)

    /// Called when the view is selected.
    func didSelect(with input: Input?)

    /// Called when the view is deselected.
    func didDeselect(with input: Input?)
}

extension InteractiveCollectionViewCell {
    public func shouldHighlight(with input: Input?) -> Bool { return true }
    public func shouldSelect(with input: Input?) -> Bool { return true }
    public func shouldDeselect(with input: Input?) -> Bool { return true }
    public func didHighlight(with input: Input?) {}
    public func didUnhighlight(with input: Input?) {}
    public func didSelect(with input: Input?) {}
    public func didDeselect(with input: Input?) {}
}

/// A convenience protocol that combines `UICollectionViewCell` with
/// `InteractiveCollectionViewCell`.
///
/// Adopt this protocol for collection view cells that are configured using
/// `Configurable` and respond to interaction and display lifecycle events
/// (e.g. selection, highlight, willDisplay).
public protocol SSCollectionViewCellProtocol: UICollectionViewCell, InteractiveCollectionViewCell {}
