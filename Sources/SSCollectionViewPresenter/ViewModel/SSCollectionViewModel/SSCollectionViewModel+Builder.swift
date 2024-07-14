//
//  SSCollectionViewModel+Builder.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 26.06.2021.
//

import UIKit

extension SSCollectionViewModel {
    // MARK: - SSCollectionViewModel.Builder

    /// A builder for constructing `SSCollectionViewModel` by composing sections,
    /// headers/footers, and cells. Use this to declaratively assemble the data
    /// that will be presented in a `UICollectionView`.
    ///
    /// # Example
    /// ```swift
    /// let builder = SSCollectionViewModel.Builder()
    /// let model = builder
    ///     .section("main") {
    ///         // Add items for the "main" section
    ///         // builder.cell(item, cellType: ItemCell.self)
    ///     }
    ///     .section("secondary")
    ///     .build()
    /// self.collectionView.ss.setViewModel(with: model)
    /// ```
    ///
    /// - Note:
    ///   - This Builder is intended to be used on the main thread only.
    ///   - It is designed specifically to build view models for
    ///     `UICollectionView` usage.
    ///   - There is no internal synchronization (e.g., `NSLock`);
    ///     concurrent access from multiple threads is not supported
    ///     and behavior is undefined.
    ///   - Do not share a single Builder instance across threads.
    public final class Builder {
        private var sections: [SectionInfo] = []

        // Working state for the currently open section
        private var currentItems: [CellInfo] = []
        private var currentHeader: ReusableViewInfo?
        private var currentFooter: ReusableViewInfo?
        private var currentSectionInset: UIEdgeInsets?
        private var currentMinimumLineSpacing: CGFloat?
        private var currentMinimumInteritemSpacing: CGFloat?
        private var currentGridColumnCount: Int?
        private var currentSectionID: String = UUID().uuidString
        private var hasOpenSection: Bool = false

        public init() {}

        /// Starts a new section.
        ///
        /// Any previously open section is closed before the new one begins.
        /// If `content` is provided, the block is executed and the section is
        /// closed automatically upon completion.
        ///
        /// - Parameters:
        ///   - id: An optional identifier for the section. Defaults to a
        ///         randomly generated UUID string.
        ///   - content: An optional block for adding items to this section.
        ///              The section closes automatically after the block returns.
        /// - Returns: The builder, for chaining.
        @discardableResult
        public func section(_ id: String? = nil,
                            _ content: (() -> Void)? = nil) -> Self {
            closeCurrentSectionIfNeeded()
            currentSectionID = id ?? UUID().uuidString
            currentItems.removeAll(keepingCapacity: true)
            currentHeader = nil
            currentFooter = nil
            currentSectionInset = nil
            currentMinimumLineSpacing = nil
            currentMinimumInteritemSpacing = nil
            currentGridColumnCount = nil
            hasOpenSection = true

            if let content = content {
                content()
                closeCurrentSectionIfNeeded()
            }
            return self
        }

        /// Adds multiple sections, with optional per-section and per-unit
        /// configuration.
        ///
        /// Each section is opened in order. `configureSection` runs first,
        /// allowing layout properties such as inset and spacings to be set
        /// before units are added via `configureUnit`.
        ///
        /// When the server and client share a contract that guarantees
        /// section and item ordering, the list can be passed directly
        /// without manual iteration.
        ///
        /// - Parameters:
        ///   - sectionList: The sections to add.
        ///   - configureSection: An optional closure called once per section
        ///                       before its units are added. Receives the
        ///                       section and the builder.
        ///   - configureUnit: A closure called once per unit within each
        ///                    section. Receives the unit and the builder.
        /// - Returns: The builder, for chaining.
        ///
        /// # Example
        /// ```swift
        /// collectionView.ss.buildViewModel { builder in
        ///     builder.sections(
        ///         result.sectionList,
        ///         configureSection: { section, builder in
        ///             guard let sectionId = section.sectionId else { return }
        ///             switch sectionId {
        ///             case "ProductList":
        ///                 builder.sectionInset(.init(top: 20, left: 15, bottom: 20, right: 15))
        ///                 builder.minimumLineSpacing(15)
        ///             case "TripleItems":
        ///                 builder.sectionInset(.init(top: 20, left: 10, bottom: 20, right: 10))
        ///                 builder.minimumLineSpacing(10)
        ///                 builder.minimumInteritemSpacing(1)
        ///             default:
        ///                 builder.sectionInset(.zero)
        ///                 builder.minimumLineSpacing(0)
        ///                 builder.minimumInteritemSpacing(0)
        ///             }
        ///         },
        ///         configureUnit: { unit, builder in
        ///             switch unit.unitType {
        ///             case "SS_TOP_BANNER":
        ///                 guard let banrList = unit.unitData as? [BannerModel] else { return }
        ///                 builder.cell(banrList, cellType: TopBannerCell.self)
        ///             case "SS_PRODUCT_LIST":
        ///                 guard let productList = unit.unitData as? [ProductModel] else { return }
        ///                 builder.cells(productList, cellType: ProductCell.self)
        ///             case "SS_MY_FAVORITES":
        ///                 guard let myFavorites = unit.unitData as? MyFavoritesModel else { return }
        ///                 if let titleInfo = myFavorites.titleInfo {
        ///                     builder.header(titleInfo, viewType: MyFavoriteHeaderView.self)
        ///                 }
        ///                 builder.cells(myFavorites.productList, cellType: ProductCell.self)
        ///             default:
        ///                 break
        ///             }
        ///         }
        ///     )
        /// }
        /// collectionView.reloadData()
        /// ```
        @discardableResult
        public func sections(
            _ sectionList: [any ViewModelSectionRepresentable],
            configureSection: ((_ section: any ViewModelSectionRepresentable, _ builder: Builder) -> Void)? = nil,
            configureUnit: (_ unit: any ViewModelUnitRepresentable, _ builder: Builder) -> Void
        ) -> Self {
            for section in sectionList {
                closeCurrentSectionIfNeeded()
                currentSectionID = section.sectionId ?? UUID().uuidString
                currentItems.removeAll(keepingCapacity: true)
                currentHeader = nil
                currentFooter = nil
                currentSectionInset = nil
                currentMinimumLineSpacing = nil
                currentMinimumInteritemSpacing = nil
                hasOpenSection = true

                // Allow caller to configure insets/spacings for this section
                configureSection?(section, self)
                // Then add units
                for unit in section.units {
                    configureUnit(unit, self)
                }
                closeCurrentSectionIfNeeded()
            }
            return self
        }

        /// Sets the edge inset for the currently open section.
        ///
        /// - Parameter inset: The inset to apply around the section's items.
        /// - Returns: The builder, for chaining.
        @discardableResult
        public func sectionInset(_ inset: UIEdgeInsets) -> Self {
            ensureSectionIfNeeded()
            currentSectionInset = inset
            return self
        }

        /// Sets the minimum line spacing for the currently open section.
        ///
        /// - Parameter spacing: The minimum spacing between successive rows
        ///                      or columns.
        /// - Returns: The builder, for chaining.
        @discardableResult
        public func minimumLineSpacing(_ spacing: CGFloat) -> Self {
            ensureSectionIfNeeded()
            currentMinimumLineSpacing = spacing
            return self
        }

        /// Sets the minimum interitem spacing for the currently open section.
        ///
        /// - Parameter spacing: The minimum spacing between items in the same
        ///                      row or column.
        /// - Returns: The builder, for chaining.
        @discardableResult
        public func minimumInteritemSpacing(_ spacing: CGFloat) -> Self {
            ensureSectionIfNeeded()
            currentMinimumInteritemSpacing = spacing
            return self
        }

        /// Sets the grid column count for the currently open section.
        ///
        /// - Parameter count: The number of columns to use when laying out items.
        ///                    When set to `0`, section insets are ignored and
        ///                    each item fills the full width of the collection
        ///                    view's bounds. When set to a positive value, items
        ///                    are distributed evenly across the row, with their
        ///                    width derived from the available content width
        ///                    after applying section insets and inter-item
        ///                    spacing.
        /// - Returns: The builder, for chaining.
        @discardableResult
        public func gridColumnCount(_ count: Int) -> Self {
            ensureSectionIfNeeded()
            currentGridColumnCount = count
            return self
        }

        /// Adds a single cell to the current section.
        ///
        /// - Parameters:
        ///   - model: The model to bind to the cell.
        ///   - cellType: The cell type that renders `model`.
        public func cell<T, V>(_ model: T, cellType: V.Type)
            where V: SSCollectionViewCellProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            currentItems.append(CellInfo(BindingStore<T, V>(state: model)))
        }

        /// Adds multiple cells to the current section.
        ///
        /// - Parameters:
        ///   - models: A sequence of models to bind, one cell per element.
        ///   - cellType: The cell type that renders each element.
        public func cells<S: Sequence, V>(_ models: S, cellType: V.Type)
            where V: SSCollectionViewCellProtocol, V.Input == S.Element
        {
            ensureSectionIfNeeded()
            let items = models.map { model -> CellInfo in
                CellInfo(BindingStore<S.Element, V>(state: model))
            }
            currentItems.append(contentsOf: items)
        }

        /// Sets the header view for the currently open section.
        ///
        /// - Parameters:
        ///   - model: The model to bind to the header view.
        ///   - viewType: The reusable view type that renders `model`.
        public func header<T, V>(_ model: T, viewType: V.Type)
            where V: SSCollectionReusableViewProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            currentHeader = ReusableViewInfo(BindingStore<T, V>(state: model))
        }

        /// Sets the footer view for the currently open section.
        ///
        /// - Parameters:
        ///   - model: The model to bind to the footer view.
        ///   - viewType: The reusable view type that renders `model`.
        public func footer<T, V>(_ model: T, viewType: V.Type)
            where V: SSCollectionReusableViewProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            currentFooter = ReusableViewInfo(BindingStore<T, V>(state: model))
        }

        /// Finalizes all open sections and returns the built view model.
        ///
        /// - Parameters:
        ///   - page: The current page index. Defaults to `0`.
        ///   - hasNext: Whether more pages are available. Defaults to `false`.
        /// - Returns: A fully constructed `SSCollectionViewModel`.
        public func build(page: Int = 0, hasNext: Bool = false) -> SSCollectionViewModel {
            closeCurrentSectionIfNeeded()
            return SSCollectionViewModel(sections: sections, page: page, hasNext: hasNext)
        }

        // MARK: - Private helpers

        private func ensureSectionIfNeeded() {
            if !hasOpenSection {
                // Start an anonymous section implicitly if none is open
                _ = section()
            }
        }

        private func closeCurrentSectionIfNeeded() {
            guard hasOpenSection else { return }
            var section = SectionInfo(
                items: currentItems,
                header: currentHeader,
                footer: currentFooter,
                identifier: currentSectionID
            )
            section.sectionInset = currentSectionInset
            section.minimumLineSpacing = currentMinimumLineSpacing
            section.minimumInteritemSpacing = currentMinimumInteritemSpacing
            section.gridColumnCount = currentGridColumnCount
            sections.append(section)
            // Reset working state
            currentItems.removeAll(keepingCapacity: true)
            currentHeader = nil
            currentFooter = nil
            currentSectionID = UUID().uuidString
            hasOpenSection = false
        }
    }
}
