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
    /// Example:
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
        public typealias ReusableViewActionClosure = ((Int, UICollectionReusableView, String, Any?) -> Void)
        public typealias CellActionClosure = ((IndexPath, UICollectionViewCell, String, Any?) -> Void)

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

        /// Starts a new section. If `content` is provided, the section is
        /// automatically closed after executing the block.
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

        /// Sets the section inset for the currently open section.
        @discardableResult
        public func sectionInset(_ inset: UIEdgeInsets) -> Self {
            ensureSectionIfNeeded()
            currentSectionInset = inset
            return self
        }

        /// Sets the minimum line spacing for the currently open section.
        @discardableResult
        public func minimumLineSpacing(_ spacing: CGFloat) -> Self {
            ensureSectionIfNeeded()
            currentMinimumLineSpacing = spacing
            return self
        }

        /// Sets the minimum interitem spacing for the currently open section.
        @discardableResult
        public func minimumInteritemSpacing(_ spacing: CGFloat) -> Self {
            ensureSectionIfNeeded()
            currentMinimumInteritemSpacing = spacing
            return self
        }

        /// Sets the grid column count for the currently open section.
        @discardableResult
        public func gridColumnCount(_ count: Int) -> Self {
            ensureSectionIfNeeded()
            currentGridColumnCount = count
            return self
        }

        /// Adds a single cell to the current section.
        public func cell<T, V>(
            _ model: T,
            cellType: V.Type,
            indexTitle: String? = nil,
            actionClosure: CellActionClosure? = nil
        )
            where V: SSCollectionViewCellProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            let cell = CellInfo(BindingStore<T, V>(state: model))
            cell.indexTitle = indexTitle
            cell.actionClosure = actionClosure
            currentItems.append(cell)
        }

        /// Adds multiple cells to the current section.
        public func cells<S: Sequence, V>(
            _ models: S,
            cellType: V.Type,
            indexTitle: ((S.Element) -> String?)? = nil,
            actionClosure: CellActionClosure? = nil
        )
            where V: SSCollectionViewCellProtocol, V.Input == S.Element
        {
            ensureSectionIfNeeded()
            let items = models.map { model -> CellInfo in
                let cell = CellInfo(BindingStore<S.Element, V>(state: model))
                cell.indexTitle = indexTitle?(model)
                cell.actionClosure = actionClosure
                return cell
            }
            currentItems.append(contentsOf: items)
        }

        /// Sets the header of the current section.
        public func header<T, V>(
            _ model: T,
            viewType: V.Type,
            actionClosure: ReusableViewActionClosure? = nil
        )
            where V: SSCollectionReusableViewProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            let header = ReusableViewInfo(BindingStore<T, V>(state: model))
            header.actionClosure = actionClosure
            currentHeader = header
        }

        /// Sets the footer of the current section.
        public func footer<T, V>(
            _ model: T,
            viewType: V.Type,
            actionClosure: ReusableViewActionClosure? = nil
        )
            where V: SSCollectionReusableViewProtocol, V.Input == T
        {
            ensureSectionIfNeeded()
            let footer = ReusableViewInfo(BindingStore<T, V>(state: model))
            footer.actionClosure = actionClosure
            currentFooter = footer
        }

        /// Finalizes and returns the built model.
        public func build(page: Int = 0, hasNext: Bool = false, isIndexTitlesEnabled: Bool = false) -> SSCollectionViewModel {
            closeCurrentSectionIfNeeded()
            return SSCollectionViewModel(sections: sections, page: page, hasNext: hasNext, isIndexTitlesEnabled: isIndexTitlesEnabled)
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
