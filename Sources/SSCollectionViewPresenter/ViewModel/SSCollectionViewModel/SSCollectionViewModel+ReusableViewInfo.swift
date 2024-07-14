//
//  SSCollectionViewModel+ReusableViewInfo.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 06.05.2021.
//

import UIKit

extension SSCollectionViewModel {
    // MARK: - SSCollectionViewModel.ReusableViewInfo
    /// A type-erased container that holds information for a single
    /// reusable view (e.g. header/footer), used by `SSCollectionViewPresenter`
    /// to configure and render reusable views in the collection view.
    public final class ReusableViewInfo: AnyBindingStore, @unchecked Sendable {
        private let _willDisplayBlock: @MainActor (Any) -> Void
        private let _didEndDisplayingBlock: @MainActor (Any) -> Void

        /// Creates a type-erased wrapper for a reusable view binding store.
        ///
        /// - Parameter store: The binding store that provides
        ///                    the reusable view's input state and binder type
        ///                    conforming to `SSCollectionReusableViewProtocol`.
        public init<State, Binder>(_ store: BindingStore<State, Binder>)
            where Binder: SSCollectionReusableViewProtocol
        {
            _willDisplayBlock = { binder in
                guard let view = binder as? Binder else { return }
                view.willDisplay(with: store.state)
            }
            _didEndDisplayingBlock = { binder in
                guard let view = binder as? Binder else { return }
                view.didEndDisplaying(with: store.state)
            }
            super.init(store)
        }

        /// Forwards `collectionView(_:willDisplaySupplementaryView:forElementKind:at:)` to the binder using the stored item.
        @MainActor
        public func willDisplay(to binder: Any) { _willDisplayBlock(binder) }

        /// Forwards `collectionView(_:didEndDisplayingSupplementaryView:forElementOfKind:at:)` to the binder using the stored item.
        @MainActor
        public func didEndDisplaying(to binder: Any) { _didEndDisplayingBlock(binder) }
    }
}
