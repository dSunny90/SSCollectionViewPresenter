//
//  InteractiveCollectionViewCell.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 06.11.2022.
//

import UIKit

/// A protocol for configurable UI units to respond to interaction events.
///
/// Enables handling of selection, highlighting, and display lifecycle events.
/// All methods are guaranteed to be called on the main thread.
@MainActor
public protocol InteractiveCollectionViewCell: InteractiveCollectionReusableView {
    /// Called when the view is highlighted (e.g., during touch-down).
    func didHighlight(with input: Input?)

    /// Called when the view is no longer highlighted (e.g., touch-up).
    func didUnhighlight(with input: Input?)

    /// Called when the view is selected.
    func didSelect(with input: Input?)

    /// Called when the view is deselected.
    func didDeselect(with input: Input?)
}

extension InteractiveCollectionViewCell {
    public func didHighlight(with input: Input?) {}
    public func didUnhighlight(with input: Input?) {}
    public func didSelect(with input: Input?) {}
    public func didDeselect(with input: Input?) {}
}

public protocol SSCollectionViewCellProtocol: UICollectionViewCell, InteractiveCollectionViewCell {}
