//
//  SSCollectionReusableViewProtocol.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 05.05.2021.
//

import UIKit

/// A protocol that adds display lifecycle callbacks to a `Configurable`
/// collection reusable view.
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

/// A convenience protocol that combines `UICollectionReusableView` with
/// `InteractiveCollectionReusableView`.
///
/// Adopt this protocol for supplementary views (e.g. headers and footers)
/// that are configured using `Configurable` and respond to display lifecycle
/// events such as `willDisplay` and `didEndDisplaying`.
public protocol SSCollectionReusableViewProtocol: UICollectionReusableView, InteractiveCollectionReusableView {}
