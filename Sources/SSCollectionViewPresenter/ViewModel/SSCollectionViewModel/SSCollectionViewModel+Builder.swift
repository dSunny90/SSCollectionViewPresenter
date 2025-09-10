//
//  SSCollectionViewModel+Builder.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import Foundation

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
    ///         // builder.cell(model: item, viewModel: ItemCellViewModel())
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
        private var currentSectionID: String = UUID().uuidString
        private var hasOpenSection: Bool = false

        public init() {}

        /// Starts a new section. If `content` is provided, the section is
        /// automatically closed after executing the block.
        @discardableResult
        public func section(_ id: String? = nil, _ content: (() -> Void)? = nil) -> Self {
            closeCurrentSectionIfNeeded()
            currentSectionID = id ?? UUID().uuidString
            currentItems.removeAll(keepingCapacity: true)
            currentHeader = nil
            currentFooter = nil
            hasOpenSection = true

            if let content = content {
                content()
                closeCurrentSectionIfNeeded()
            }
            return self
        }

        /// Adds a single cell to the current section.
        public func cell<T: Boundable>(model: T.DataType, viewModel: T)
            where T.Binder: SSCollectionViewCellProtocol, T.Binder.Input == T.DataType
        {
            ensureSectionIfNeeded()
            var vm = viewModel
            vm.contentData = model
            currentItems.append(CellInfo(vm))
        }

        /// Adds multiple cells to the current section.
        public func cells<T: Boundable, S: Sequence>(models: S, viewModel: T)
            where S.Element == T.DataType, T.Binder: SSCollectionViewCellProtocol, T.Binder.Input == T.DataType
        {
            ensureSectionIfNeeded()
            let items = models.map { m -> CellInfo in
                var vm = viewModel
                vm.contentData = m
                return CellInfo(vm)
            }
            currentItems.append(contentsOf: items)
        }

        /// Sets the header of the current section.
        public func header<T: Boundable>(model: T.DataType, viewModel: T)
            where T.Binder: SSCollectionReusableViewProtocol, T.Binder.Input == T.DataType
        {
            ensureSectionIfNeeded()
            var vm = viewModel
            vm.contentData = model
            currentHeader = ReusableViewInfo(vm)
        }

        /// Sets the footer of the current section.
        public func footer<T: Boundable>(model: T.DataType, viewModel: T)
            where T.Binder: SSCollectionReusableViewProtocol, T.Binder.Input == T.DataType
        {
            ensureSectionIfNeeded()
            var vm = viewModel
            vm.contentData = model
            currentFooter = ReusableViewInfo(vm)
        }

        /// Finalizes and returns the built model.
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
            let section = SectionInfo(
                items: currentItems,
                header: currentHeader,
                footer: currentFooter,
                identifier: currentSectionID
            )
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

