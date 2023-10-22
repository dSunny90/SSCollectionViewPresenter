//
//  ViewModelUnitRepresentable.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 22.10.2023.
//

/// A type that represents a single unit within a section.
///
/// Each unit corresponds to a discrete UI module defined by a shared
/// server-client contract. The `unitType` identifies which module to
/// render, and `unitData` carries the associated payload.
///
/// > Tip: Conforming types are typically defined per screen or API
/// > context (e.g. home, search, category), since each endpoint may
/// > follow its own data contract.
/// >
/// > For the `unitData` payload, two common server shapes are:
/// > - **Nested under a `data` field** — decode `unitData` by switching
/// >   on `unitType` and decoding the inner `data` field into the
/// >   appropriate model.
/// > - **Flat alongside `unitType`** — decode the entire unit payload
/// >   directly into `unitData` without an extra nesting level.
/// >
/// > If two screens share identical server data and UI, the same
/// > conforming type can be reused. When screens share a common
/// > structure but differ in additional rules or layout, prefer
/// > subclassing over duplication — class inheritance keeps the shared
/// > contract in one place while allowing per-screen customization.
/// >
/// > Since the builder receives a closure per unit, repeated closure
/// > definitions can become boilerplate across screens. If that becomes
/// > a maintenance concern, extract common closure logic into a shared
/// > factory to keep each call site focused and consistent.
public protocol ViewModelUnitRepresentable {
    /// A string that identifies the type of UI module to render.
    var unitType: String { get }

    /// The data payload associated with this unit, if any.
    var unitData: Any? { get }
}
