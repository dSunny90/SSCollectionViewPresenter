//
//  InteractiveCollectionReusableView.swift
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
public protocol InteractiveCollectionReusableView: Configurable {
    /// Called when the view is about to appear.
    func willDisplay(with input: Input?)

    /// Called when the view is no longer visible.
    func didEndDisplaying(with input: Input?)
}

extension InteractiveCollectionReusableView {
    public func willDisplay(with input: Input?) {}
    public func didEndDisplaying(with input: Input?) {}
}

public protocol SSCollectionReusableViewProtocol: UICollectionReusableView, InteractiveCollectionReusableView {}
