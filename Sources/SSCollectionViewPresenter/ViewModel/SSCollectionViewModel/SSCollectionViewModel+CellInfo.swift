//
//  SSCollectionViewModel+CellInfo.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 06.05.2021.
//

import UIKit

extension SSCollectionViewModel {
    // MARK: - SSCollectionViewModel.CellInfo
    /// A type-erased container that holds information for a single cell,
    /// used by `SSCollectionViewPresenter` to configure and render cells
    /// in the collection view.
    public final class CellInfo: AnyBindingStore {
        /// Whether the cell is currently highlighted (touch-down state)
        public var isHighlighted: Bool = false
        /// Whether the cell is currently selected
        public var isSelected: Bool = false

        private let _didHighlightBlock: (Any) -> Void
        private let _didUnhighlightBlock: (Any) -> Void
        private let _didSelectBlock: (Any) -> Void
        private let _didDeselectBlock: (Any) -> Void
        private let _willDisplayBlock: (Any) -> Void
        private let _didEndDisplayingBlock: (Any) -> Void

        /// Creates a type-erased wrapper for a cell binding store.
        ///
        /// - Parameter store: The binding store that provides
        ///                    the cell's input state and binder type
        ///                    conforming to `SSCollectionViewCellProtocol`.
        public init<State, Binder>(_ store: BindingStore<State, Binder>)
            where Binder: SSCollectionViewCellProtocol
        {
            _didHighlightBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didHighlight(with: store.state)
            }
            _didUnhighlightBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didUnhighlight(with: store.state)
            }
            _didSelectBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didSelect(with: store.state)
            }
            _didDeselectBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didDeselect(with: store.state)
            }
            _willDisplayBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.willDisplay(with: store.state)
            }
            _didEndDisplayingBlock = { binder in
                guard let cell = binder as? Binder else { return }
                cell.didEndDisplaying(with: store.state)
            }
            super.init(store)
        }

        /// Forwards `collectionView(_:didHighlightItemAt:)`
        /// to the binder using the stored item.
        public func didHighlight(to binder: Any) {
            _didHighlightBlock(binder)
            isHighlighted = true
        }

        /// Forwards `collectionView(_:didUnhighlightItemAt:)`
        /// to the binder using the stored item.
        public func didUnhighlight(to binder: Any) {
            _didUnhighlightBlock(binder)
            isHighlighted = false
        }

        /// Forwards `collectionView(_:didSelectItemAt:)`
        /// to the binder using the stored item.
        public func didSelect(to binder: Any) {
            isSelected = true
            _didSelectBlock(binder)
        }

        /// Forwards `collectionView(_:didDeselectItemAt:)`
        /// to the binder using the stored item.
        public func didDeselect(to binder: Any) {
            isSelected = false
            _didDeselectBlock(binder)
        }

        /// Forwards `collectionView(_:willDisplay:forItemAt:)`
        /// to the binder using the stored item.
        public func willDisplay(to binder: Any) {
            _willDisplayBlock(binder)
        }

        /// Forwards `collectionView(_:didEndDisplaying:forItemAt:)`
        /// to the binder using the stored item.
        public func didEndDisplaying(to binder: Any) {
            _didEndDisplayingBlock(binder)
        }
    }
}
