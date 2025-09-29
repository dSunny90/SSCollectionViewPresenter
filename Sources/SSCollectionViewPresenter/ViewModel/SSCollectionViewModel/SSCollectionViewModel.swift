//
//  SSCollectionViewModel.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

fileprivate typealias SectionInfo = SSCollectionViewModel.SectionInfo

/// A data model that represents the entire content of a collection view,
/// used by `SSCollectionViewPresenter` to render and manage UI states.
///
/// - Note:
///   - The `sections` array holds `SectionInfo` objects, each describing
///     the cells and supplementary views (header, footer) for a section.
///   - This model is UI-agnostic and does not handle layout logic directly.
///     Layout-specific options (e.g., spacing, insets) within `SectionInfo`
///     apply only when using a `UICollectionViewFlowLayout`.
///   - For `UICollectionViewCompositionalLayout`, the layout is defined
///     independently and not influenced by these `SectionInfo` properties.
public struct SSCollectionViewModel: RandomAccessCollection, RangeReplaceableCollection {
    // MARK: - RandomAccessCollection
    public typealias Index = Int
    public typealias Element = SectionInfo

    public var startIndex: Int { sections.startIndex }
    public var endIndex: Int { sections.endIndex }

    // MARK: - Core Contents
    /// The current sections to be displayed in the collection view.
    /// This gets updated whenever new paginated data is fetched.
    internal var sections: [SectionInfo] = []

    /// The current page number for paginated API requests.
    /// Use this when fetching data from a page-based RESTful API
    /// to update your view model.
    public var page: Int = 0

    /// A flag indicating whether there is more data available for pagination.
    /// Set this based on the API response to control whether a next request
    /// should be triggered.
    public var hasNext: Bool = false

    // MARK: - Init.
    public init(sections: [SectionInfo] = [], page: Int = 0, hasNext: Bool = false) {
        self.sections = sections
        self.page = page
        self.hasNext = hasNext
    }

    public init() {
        self.init(sections: [])
    }

    /// Get a section at the specified index.
    public func sectionInfo(at index: Int) -> SectionInfo? {
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    // MARK: - RandomAccessCollection Methods
    public func index(after i: Int) -> Int {
        sections.index(after: i)
    }

    public func index(before i: Int) -> Int {
        sections.index(before: i)
    }

    // MARK: - RangeReplaceableCollection
    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
        where C: Collection, C.Element == SectionInfo {
            sections.replaceSubrange(subrange, with: newElements)
    }

    // MARK: - RandomAccessCollection Subscripts
    public subscript(index: Int) -> SectionInfo {
        get { sections[index] }
        set { sections[index] = newValue }
    }

    // MARK: - Operators Overloading
    public static func + (lhs: SSCollectionViewModel, rhs: SSCollectionViewModel) -> SSCollectionViewModel {
        SSCollectionViewModel(sections: lhs.sections + rhs.sections)
    }

    public static func += (lhs: inout SSCollectionViewModel, rhs: SSCollectionViewModel) {
        lhs.sections += rhs.sections
    }

    public static func + (lhs: SSCollectionViewModel, rhs: SectionInfo) -> SSCollectionViewModel {
        var new = lhs
        new.append(rhs)
        return new
    }

    public static func + (lhs: SSCollectionViewModel, rhs: [SectionInfo]) -> SSCollectionViewModel {
        var new = lhs
        new.append(contentsOf: rhs)
        return new
    }
}
