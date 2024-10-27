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
    public struct SectionInfo: RandomAccessCollection, RangeReplaceableCollection, Hashable, Sendable {
        // MARK: - RandomAccessCollection
        public typealias Index = Int
        public typealias Element = CellInfo

        public var startIndex: Int { items.startIndex }
        public var endIndex: Int { items.endIndex }

        // MARK: - Core Contents
        internal var items: [CellInfo]
        internal var header: ReusableViewInfo?
        internal var footer: ReusableViewInfo?
        public var identifier: String?

        // MARK: - FlowLayout Options
        public var sectionInsets: UIEdgeInsets?
        public var minimumLineSpacing: CGFloat?
        public var minimumInteritemSpacing: CGFloat?

        private let uuid: UUID = UUID()

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
