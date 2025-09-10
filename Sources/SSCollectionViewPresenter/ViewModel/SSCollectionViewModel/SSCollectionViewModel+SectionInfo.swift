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

public extension SSCollectionViewModel.SectionInfo {
    /// Appends a cell info to the end of the section.
    ///
    /// - Parameters:
    ///   - model: Optional data model to bind to the cell's view model.
    ///   - viewModel: A `Boundable` view model whose `Binder` conforms to
    ///     `SSCollectionViewCellProtocol`.
    mutating func appendCellInfo<T>(model: T.DataType?, viewModel: T)
    where T: Boundable, T.Binder: SSCollectionViewCellProtocol
    {
        var vm = viewModel
        vm.contentData = model
        append(SSCollectionViewModel.CellInfo(vm))
    }

    /// Inserts a cell info at the specified index.
    ///
    /// - Parameters:
    ///   - index: Target index within `startIndex...endIndex`.
    ///   - model: Optional data model to bind to the cell's view model.
    ///   - viewModel: A `Boundable` view model whose `Binder` conforms to
    ///     `SSCollectionViewCellProtocol`.
    ///
    /// - Note: No-op if `index` is outside `startIndex...endIndex`.
    mutating func insertCellInfo<T>(
        at index: Int,
        model: T.DataType?,
        viewModel: T
    ) where T: Boundable, T.Binder: SSCollectionViewCellProtocol {
        guard (startIndex...endIndex).contains(index) else { return }
        var vm = viewModel
        vm.contentData = model
        items.insert(SSCollectionViewModel.CellInfo(vm), at: index)
    }

    /// Updates an existing cell info at the specified index.
    ///
    /// - Parameters:
    ///   - index: The index of the cell to update.
    ///   - model: Optional data model to bind to the cell's view model.
    ///   - viewModel: A `Boundable` view model whose `Binder` conforms to
    ///     `SSCollectionViewCellProtocol`.
    ///
    /// - Note: No-op if `index` is out of bounds.
    mutating func updateCellInfo<T>(
        at index: Int,
        model: T.DataType?,
        viewModel: T
    ) where T: Boundable, T.Binder: SSCollectionViewCellProtocol {
        guard items.indices.contains(index) else { return }
        var vm = viewModel
        vm.contentData = model
        items[index] = SSCollectionViewModel.CellInfo(vm)
    }

    /// Upserts a cell info at the specified index.
    ///
    /// - Behavior:
    ///   - If `index` is within current indices, updates the cell.
    ///   - If `index` equals `endIndex`, appends the cell.
    ///   - Otherwise, performs no operation.
    ///
    /// - Parameters:
    ///   - index: Target index for update or insertion.
    ///   - model: Optional data model to bind to the cell's view model.
    ///   - viewModel: A `Boundable` view model whose `Binder` conforms to
    ///     `SSCollectionViewCellProtocol`.
    mutating func upsertCellInfo<T>(
        at index: Int,
        model: T.DataType?,
        viewModel: T
    ) where T: Boundable, T.Binder: SSCollectionViewCellProtocol {
        if items.indices.contains(index) {
            updateCellInfo(at: index, model: model, viewModel: viewModel)
        } else if index == endIndex {
            appendCellInfo(model: model, viewModel: viewModel)
        } else {
            // Out of range; ignore
            return
        }
    }

    /// Sets the section's header reusable view information.
    ///
    /// - Parameters:
    ///   - model: Optional data model intended for the header view.
    ///   - viewModel: A `Boundable` view model whose `Binder` conforms to
    ///     `SSCollectionReusableViewProtocol`.
    mutating func setHeaderInfo<T>(model: T.DataType?, viewModel: T)
        where T: Boundable, T.Binder: SSCollectionReusableViewProtocol
    {
        var vm = viewModel
        vm.contentData = model
        header = SSCollectionViewModel.ReusableViewInfo(vm)
    }

    /// Sets the section's footer reusable view information.
    ///
    /// - Parameters:
    ///   - model: Optional data model intended for the footer view.
    ///   - viewModel: A `Boundable` view model whose `Binder` conforms to
    ///     `SSCollectionReusableViewProtocol`.
    mutating func setFooterInfo<T>(model: T.DataType?, viewModel: T)
        where T: Boundable, T.Binder: SSCollectionReusableViewProtocol
    {
        var vm = viewModel
        vm.contentData = model
        footer = SSCollectionViewModel.ReusableViewInfo(vm)
    }
}
