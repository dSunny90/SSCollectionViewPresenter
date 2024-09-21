//
//  SSCollectionViewModel+ReusableViewInfo.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

extension SSCollectionViewModel {
    // MARK: - SSCollectionViewModel.ReusableViewInfo
    /// A type-erased container that holds information for reusable views
    /// such as headers or footers, used by `SSCollectionViewPresenter`
    /// when configuring supplementary views in the collection view.
    ///
    /// - Note:
    ///   - `ReusableViewInfo` is designed to represent reusable elements
    ///     (e.g., header or footer) that accompany each section.
    ///   - Similar to `CellInfo`, it encapsulates user-defined
    ///     `Boundable` objects via type-erasure, enabling generic
    ///     configuration without exposing concrete types.
    ///   - It is primarily consumed by the presenter when dequeuing
    ///     and binding supplementary views.
    @MainActor
    public struct ReusableViewInfo: @preconcurrency Hashable, @unchecked Sendable {
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

        private let _willDisplayBlock: (Any) -> Void
        private let _didEndDisplayingBlock: (Any) -> Void

        private let _identifier: () -> String?

        /// Creates a type-erased boundable from a concrete `Boundable`.
        ///
        /// - Parameter boundable: The concrete `Boundable` to wrap.
        public init<T: Boundable>(_ boundable: T)
        where T.Binder: InteractiveReusableView, T.Binder.Input == T.DataType {
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

        public func viewSize(constrainedTo size: CGSize) -> CGSize {
            return _sizeBlock?(size) ?? .zero
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
