//
//  SSCollectionViewModel+SectionInfo.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 06.05.2021.
//

import UIKit

extension SSCollectionViewModel {
    // MARK: - SSCollectionViewModel.SectionInfo
    /// A view model structure used by `SSCollectionViewPresenter` to configure
    /// and render each section of the collection view.
    ///
    /// - Note:
    ///
    ///   The properties under **Layout Options** (e.g., `sectionInset`,
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
    public struct SectionInfo: RandomAccessCollection, RangeReplaceableCollection, Hashable {
        public typealias ReusableViewInfo = SSCollectionViewModel.ReusableViewInfo

        private let uuid: UUID = UUID()
        // MARK: - Core Contents

        public var identifier: String?

        internal var items: [CellInfo]
        internal var header: ReusableViewInfo?
        internal var footer: ReusableViewInfo?

        // MARK: - RandomAccessCollection

        public typealias Index = Int
        public typealias Element = CellInfo

        public var startIndex: Int { items.startIndex }
        public var endIndex: Int { items.endIndex }

        // MARK: - FlowLayout Options

        public var sectionInset: UIEdgeInsets?
        public var minimumLineSpacing: CGFloat?
        public var minimumInteritemSpacing: CGFloat?

        // MARK: - Init.

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

        public init() {
            self.init(items: [])
        }

        /// Get a cell info at the specified index.
        public func cellInfo(at index: Int) -> CellInfo? {
            guard items.indices.contains(index) else { return nil }
            return items[index]
        }

        /// Get a header info at the specified index.
        public func headerInfo() -> ReusableViewInfo? { header }

        /// Get a header info at the specified index.
        public func footerInfo() -> ReusableViewInfo? { footer }

        // MARK: - RandomAccessCollection Methods

        public func index(after i: Int) -> Int {
            items.index(after: i)
        }

        public func index(before i: Int) -> Int {
            items.index(before: i)
        }

        // MARK: - RangeReplaceableCollection

        public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
            where C: Collection, C.Element == CellInfo
        {
            items.replaceSubrange(subrange, with: newElements)
        }

        // MARK: - RandomAccessCollection Subscripts

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

        // MARK: - Operators Overloading
        public static func + (lhs: SectionInfo, rhs: SectionInfo) -> SectionInfo {
            SectionInfo(items: lhs.items + rhs.items)
        }

        public static func += (lhs: inout SectionInfo, rhs: SectionInfo) {
            lhs.items += rhs.items
        }

        public static func + (lhs: SectionInfo, rhs: CellInfo) -> SectionInfo {
            var new = lhs
            new.append(rhs)
            return new
        }

        public static func + (lhs: SectionInfo, rhs: [CellInfo]) -> SectionInfo {
            var new = lhs
            new.append(contentsOf: rhs)
            return new
        }
    }
}

public extension SSCollectionViewModel.SectionInfo {
    // MARK: - Cell/Header/Footer Operations

    /// Appends a cell info to the end of the section.
    ///
    /// - Parameters:
    ///   - model: The data model to bind to the cell.
    ///   - cellType: The cell view type conforming to `SSCollectionViewCellProtocol`.
    mutating func appendCellInfo<T, V>(_ model: T, cellType: V.Type)
        where V: SSCollectionViewCellProtocol, V.Input == T
    {
        append(Element(BindingStore<T, V>(state: model)))
    }

    /// Inserts a cell info at the specified index.
    ///
    /// - Parameters:
    ///   - model: The data model to bind to the cell.
    ///   - cellType: The cell view type conforming to `SSCollectionViewCellProtocol`.
    ///   - index: Target index within `startIndex...endIndex`.
    ///
    /// - Note: No-op if `index` is outside `startIndex...endIndex`.
    mutating func insertCellInfo<T, V>(_ model: T, cellType: V.Type, at index: Int)
        where V: SSCollectionViewCellProtocol, V.Input == T
    {
        guard (startIndex...endIndex).contains(index) else { return }
        items.insert(Element(BindingStore<T, V>(state: model)), at: index)

    }

    /// Updates an existing cell info at the specified index.
    ///
    /// - Parameters:
    ///   - model: The data model to bind to the cell.
    ///   - cellType: The cell view type conforming to `SSCollectionViewCellProtocol`.
    ///   - index: The index of the cell to update.
    mutating func updateCellInfo<T, V>(
        _ model: T,
        cellType: V.Type,
        at index: Int
    ) where V: SSCollectionViewCellProtocol, V.Input == T {
        guard items.indices.contains(index) else { return }
        items[index] = Element(BindingStore<T, V>(state: model))
    }

    /// Upserts a cell info at the specified index.
    ///
    /// - Behavior:
    ///   - If `index` is within current indices, updates the cell.
    ///   - If `index` equals `endIndex`, appends the cell.
    ///   - Otherwise, performs no operation.
    ///
    /// - Parameters:
    ///   - model: The data model to bind to the cell.
    ///   - cellType: The cell view type conforming to `SSCollectionViewCellProtocol`.
    ///   - index: Target index for update or insertion.
    mutating func upsertCellInfo<T, V>(
        _ model: T,
        cellType: V.Type,
        at index: Int
    ) where V: SSCollectionViewCellProtocol, V.Input == T {
        if items.indices.contains(index) {
            updateCellInfo(model, cellType: cellType, at: index)
        } else if index == endIndex {
            appendCellInfo(model, cellType: V.self)
        } else {
            return
        }
    }

    /// Sets the section's header reusable view information.
    ///
    /// - Parameters:
    ///   - model: The data model to provide to the header view.
    ///   - viewType: The header view type conforming to `SSCollectionReusableViewProtocol`.
    mutating func setHeaderInfo<T, V>(_ model: T, viewType: V.Type)
        where V: SSCollectionReusableViewProtocol, V.Input == T
    {
        header = ReusableViewInfo(BindingStore<T, V>(state: model))
    }

    /// Sets the section's footer reusable view information.
    ///
    /// - Parameters:
    ///   - model: The data model to provide to the footer view.
    ///   - viewType: The footer view type conforming to `SSCollectionReusableViewProtocol`.
    mutating func setFooterInfo<T, V>(_ model: T, viewType: V.Type)
        where V: SSCollectionReusableViewProtocol, V.Input == T
    {
        footer = ReusableViewInfo(BindingStore<T, V>(state: model))
    }
}
