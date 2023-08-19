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
public struct SSCollectionViewModel {
    /// The current page number for paginated API requests.
    /// Use this when fetching data from a page-based RESTful API
    /// to update your view model.
    public var page: Int = 0

    /// A flag indicating whether there is more data available for pagination.
    /// Set this based on the API response to control whether a next request
    /// should be triggered.
    public var hasNext: Bool = false

    /// The current sections to be displayed in the collection view.
    /// This gets updated whenever new paginated data is fetched.
    internal var sections: [SectionInfo] = []

    public init(sections: [SectionInfo] = [], hasNext: Bool = false, page: Int = 0) {
        self.sections = sections
        self.hasNext = hasNext
        self.page = page
    }

    // MARK: - Section Query
    /// Get the number of sections.
    public func count() -> Int { sections.count }

    /// Get a section at the specified index.
    public func sectionInfo(at index: Int) -> SectionInfo? {
        guard sections.indices.contains(index) else { return nil }
        return sections[index]
    }

    /// Returns the first section whose identifier matches the given string.
    public func filter(
        whereIdentifierIs identifier: String
    ) -> [SectionInfo] {
        return sections.filter { $0.identifier == identifier }
    }

    /// Returns all sections whose identifiers match the given string.
    public func first(
        whereIdentifierIs identifier: String
    ) -> SectionInfo? {
        return sections.first { $0.identifier == identifier }
    }

    /// Returns the index of the first section with the given identifier.
    public func firstIndex(whereIdentifierIs identifier: String) -> Int? {
        return sections.firstIndex { $0.identifier == identifier }
    }

    // MARK: - Section Mutation
    /// Appends a single section to the collection view.
    public mutating func append(_ newSection: SectionInfo) {
        sections.append(newSection)
    }

    /// Appends a collection of sections to the collection view.
    public mutating func append(contentsOf newSections: [SectionInfo]) {
        sections.append(contentsOf: newSections)
    }

    /// Inserts a section at the specified index.
    public mutating func insert(_ newSection: SectionInfo, at index: Int) {
        sections.insert(newSection, at: index)
    }

    /// Removes an section at the given index.
    @discardableResult
    public mutating func remove(at index: Int) -> SectionInfo {
        return sections.remove(at: index)
    }

    /// Removes all items.
    public mutating func removeAll(keepingCapacity: Bool = false) {
        sections.removeAll(keepingCapacity: keepingCapacity)
    }

    /// Removes the first item that matches a given predicate.
    @discardableResult
    public mutating func removeFirst(
        where shouldRemove: (SectionInfo) -> Bool
    ) -> SectionInfo? {
        if let index = sections.firstIndex(where: shouldRemove) {
            return sections.remove(at: index)
        }
        return nil
    }

    /// Replaces item at index with a new boundable.
    public mutating func replace(at index: Int, with newSection: SectionInfo) {
        sections[index] = newSection
    }

    public subscript(index: Int) -> SectionInfo {
        get { sections[index] }
        set { sections[index] = newValue }
    }

}
