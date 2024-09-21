//
//  SSCollectionViewModel+SectionInfo.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

extension SSCollectionViewModel {
    // MARK: - SSCollectionViewModel.SectionInfo
    /// A view model structure used by `SSCollectionViewPresenter` to configure
    /// and render each section of the collection view.
    ///
    /// - Note:
    ///
    ///   The properties under **Layout Options** (e.g., `sectionInsets`,
    ///   `minimumLineSpacing`, `minimumInteritemSpacing`) are
    ///   **only applied when using a `UICollectionViewFlowLayout`**.
    ///
    ///   For `itemSize`, `headerHeight`, and `footerHeight`, the actual sizes
    ///   are determined by calling `static size(with:constrainedTo:)`
    ///   on the corresponding types that conform to `Configurable`.
    ///   These sizes are automatically calculated using the input model
    ///   provided to each cell or supplementary view.
    ///
    ///   If a `UICollectionViewCompositionalLayout` is used, these options will
    ///   **not be applied**, since compositional layouts define their own layout
    ///   behavior and spacing independently.
    ///
    ///   When switching between layout types, ensure that layout-specific
    ///   properties are configured accordingly.
    @MainActor
    public struct SectionInfo: @preconcurrency Hashable, Sendable {
        // MARK: - Core Contents
        internal var items: [CellInfo]
        internal var header: ReusableViewInfo?
        internal var footer: ReusableViewInfo?
        internal var identifier: String?

        // MARK: - FlowLayout Options
        public var sectionInsets: UIEdgeInsets?
        public var minimumLineSpacing: CGFloat?
        public var minimumInteritemSpacing: CGFloat?

        private let uuid: UUID = UUID()

        public init(
            items: [CellInfo] = [],
            header: ReusableViewInfo? = nil,
            footer: ReusableViewInfo? = nil,
            identifier: String? = nil
        ) {
            self.items = items
            self.header = header
            self.footer = footer
            self.identifier = identifier
        }

        // MARK: - Cell Query
        /// Get the number of cells.
        public func count() -> Int { items.count }

        /// Get a cell info at the specified index.
        public func cellInfo(at index: Int) -> CellInfo? {
            guard items.indices.contains(index) else { return nil }
            return items[index]
        }

        /// Get a header info at the specified index.
        public func headerInfo() -> ReusableViewInfo? { header }

        /// Get a header info at the specified index.
        public func footerInfo() -> ReusableViewInfo? { footer }

        /// Returns the first item whose identifier matches the given string.
        public func filter(
            whereIdentifierIs identifier: String
        ) -> [CellInfo] {
            return items.filter { $0.identifier == identifier }
        }

        /// Returns all items whose identifiers match the given string.
        public func first(
            whereIdentifierIs identifier: String
        ) -> CellInfo? {
            return items.first { $0.identifier == identifier }
        }

        /// Returns the index of the first item with the given identifier.
        public func firstIndex(whereIdentifierIs identifier: String) -> Int? {
            return items.firstIndex { $0.identifier == identifier }
        }

        // MARK: - Cell Mutation
        /// Appends a single boundable item to the section.
        public mutating func append<T: Boundable>(_ newItem: T)
        where T.Binder: InteractiveCell, T.Binder.Input == T.DataType {
            items.append(CellInfo(newItem))
        }

        /// Appends a collection of already-erased boundables to the section.
        public mutating func append(
            contentsOf newItems: [CellInfo]
        ) {
            items.append(contentsOf: newItems)
        }

        /// Inserts a boundable at the specified index.
        public mutating func insert<T: Boundable>(_ newItem: T, at index: Int)
        where T.Binder: InteractiveCell, T.Binder.Input == T.DataType {
            items.insert(CellInfo(newItem), at: index)
        }

        /// Removes an item at the given index.
        @discardableResult
        public mutating func remove(
            at index: Int
        ) -> CellInfo {
            return items.remove(at: index)
        }

        /// Removes all items.
        public mutating func removeAll(keepingCapacity: Bool = false) {
            items.removeAll(keepingCapacity: keepingCapacity)
        }

        /// Removes the first item that matches a given predicate.
        @discardableResult
        public mutating func removeFirst(
            where shouldRemove: (CellInfo) -> Bool
        ) -> CellInfo? {
            if let index = items.firstIndex(where: shouldRemove) {
                return items.remove(at: index)
            }
            return nil
        }

        /// Replaces item at index with a new boundable.
        public mutating func replace<T: Boundable>(at index: Int,
                                                   with newItem: T)
        where T.Binder: InteractiveCell, T.Binder.Input == T.DataType {
            items[index] = CellInfo(newItem)
        }

        public subscript(index: Int) -> CellInfo {
            get { items[index] }
            set { items[index] = newValue }
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(uuid)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.uuid == rhs.uuid
        }
    }
}
