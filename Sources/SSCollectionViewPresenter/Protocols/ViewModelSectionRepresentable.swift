//
//  ViewModelSectionRepresentable.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 22.10.2023.
//

/// A type that represents a single section in a server-driven layout.
///
/// Conform to this protocol when the server and client share a contract
/// that defines how sections and their units are structured. The ordering
/// of sections and units in the response can be passed directly to the
/// collection view builder without manual iteration.
///
/// > Tip: If the server does not provide section identifiers and instead
/// > returns a nested array of units, decode the response as
/// > `[[any ViewModelUnitRepresentable]]` and initialize a conforming
/// > type for each inner array — passing it as `units` and setting
/// > `sectionId` to `nil` or a derived index value.
public protocol ViewModelSectionRepresentable {
    /// An optional identifier for this section.
    var sectionId: String? { get }

    /// The ordered list of units belonging to this section.
    var units: [any ViewModelUnitRepresentable] { get }
}
