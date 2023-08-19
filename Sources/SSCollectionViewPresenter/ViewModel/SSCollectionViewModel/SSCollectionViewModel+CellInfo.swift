//
//  SSCollectionViewModel+CellInfo.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

extension SSCollectionViewModel {
    // MARK: - SSCollectionViewModel.CellInfo
    /// A type-erased container that holds information for a single cell,
    /// used by `SSCollectionViewPresenter` to configure and render cells
    /// in the collection view.
    ///
    /// - Note:
    ///   - Each `CellInfo` instance encapsulates a cell's data and
    ///     its binding logic, derived from user-defined `Boundable` objects.
    ///   - Internally, this plays a similar role to an `AnyBoundable` type,
    ///     providing type-erasure for different `Boundable` implementations
    ///     while preserving the ability to configure cells generically.
    ///   - `CellInfo` is primarily consumed by the presenter during
    ///     data binding and rendering, and should be created by converting
    ///     user-defined `Boundable` instances into this unified type.
    public struct CellInfo: Hashable {
        /// The underlying content data, type-erased as `Any`.
        public var contentData: Any? { _contentData() }

        /// The expected binder type to which configuration should be applied.
        public var binderType: Any.Type { _binderType }

        /// An optional identifier used to distinguish this boundable instance.
        public var identifier: String? { _identifier() }

        internal let uuid: UUID = UUID()

        private let _contentData: () -> Any?
        private let _binderType: Any.Type

        private let _bindingBlock: (Any) -> Void
        private let _sizeBlock: ((CGSize) -> CGSize)?

        private let _didHighlightBlock: (Any) -> Void
        private let _didUnhighlightBlock: (Any) -> Void
        private let _didSelectBlock: (Any) -> Void
        private let _didDeselectBlock: (Any) -> Void
        private let _willDisplayBlock: (Any) -> Void
        private let _didEndDisplayingBlock: (Any) -> Void

        private let _identifier: () -> String?

        /// Creates a type-erased boundable from a concrete `Boundable`.
        ///
        /// - Parameter boundable: The concrete `Boundable` to wrap.
        public init<T: Boundable>(_ boundable: T)
        where T.Binder: InteractiveCell, T.Binder.Input == T.DataType {
            _contentData = { boundable.contentData }
            _binderType = T.Binder.self
            _bindingBlock = { anyBinder in
                guard let concreteBinder = anyBinder as? T.Binder,
                      let input = boundable.contentData
                else { return }
                concreteBinder.configurer(concreteBinder, input)
            }
            _sizeBlock = { constrainedSize in
                guard let input = boundable.contentData else { return .zero }
                return T.Binder.size(
                    with: input, constrainedTo: constrainedSize
                ) ?? .zero
            }
            _didHighlightBlock = { anyBinder in
                guard let cell = anyBinder as? T.Binder,
                      let input = boundable.contentData
                else { return }
                cell.didHighlight(with: input)
            }
            _didUnhighlightBlock = { anyBinder in
                guard let cell = anyBinder as? T.Binder,
                      let input = boundable.contentData
                else { return }
                cell.didUnhighlight(with: input)
            }
            _didSelectBlock = { anyBinder in
                guard let cell = anyBinder as? T.Binder,
                      let input = boundable.contentData
                else { return }
                cell.didSelect(with: input)
            }
            _didDeselectBlock = { anyBinder in
                guard let cell = anyBinder as? T.Binder,
                      let input = boundable.contentData
                else { return }
                cell.didDeselect(with: input)
            }
            _willDisplayBlock = { anyBinder in
                guard let cell = anyBinder as? T.Binder,
                      let input = boundable.contentData
                else { return }
                cell.willDisplay(with: input)
            }
            _didEndDisplayingBlock = { anyBinder in
                guard let cell = anyBinder as? T.Binder,
                      let input = boundable.contentData
                else { return }
                cell.didEndDisplaying(with: input)
            }
            _identifier = { boundable.identifier }
        }

        /// Applies the configuration to the given binder instance.
        ///
        /// - Parameter binder: An instance that should match `binderType`.
        public func bound(to binder: Any) {
            _bindingBlock(binder)
        }

        public func itemSize(constrainedTo size: CGSize) -> CGSize {
            return _sizeBlock?(size) ?? .zero
        }

        public func didHighlight(to binder: Any) {
            _didHighlightBlock(binder)
        }

        public func didUnhighlight(to binder: Any) {
            _didUnhighlightBlock(binder)
        }

        public func didSelect(to binder: Any) {
            _didSelectBlock(binder)
        }

        public func didDeselect(to binder: Any) {
            _didDeselectBlock(binder)
        }

        public func willDisplay(to binder: Any) {
            _willDisplayBlock(binder)
        }

        public func didEndDisplaying(to binder: Any) {
            _didEndDisplayingBlock(binder)
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
