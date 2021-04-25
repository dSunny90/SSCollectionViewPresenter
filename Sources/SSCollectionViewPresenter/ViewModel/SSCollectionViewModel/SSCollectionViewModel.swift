//
//  SSCollectionViewModel.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 25.04.2021.
//

import UIKit

@_exported import SendingState

fileprivate typealias SectionInfo = SSCollectionViewModel.SectionInfo

/// A data model that represents the entire content of a collection view,
/// used by `SSCollectionViewPresenter` to render and manage UI states.
public struct SSCollectionViewModel: RandomAccessCollection, RangeReplaceableCollection {
    // MARK: - RandomAccessCollection

    public typealias Index = Int
    public typealias Element = SectionInfo

    public var startIndex: Int { sections.startIndex }
    public var endIndex: Int { sections.endIndex }

    // MARK: - Core Contents

    /// The current sections to be displayed in the collection view.
    internal var sections: [SectionInfo] = []

    // MARK: - Init.

    public init(sections: [SectionInfo] = []) {
        self.sections = sections
    }

    public init() {
        self.init(sections: [])
    }

    // MARK: - RandomAccessCollection Methods

    public func index(after i: Int) -> Int {
        sections.index(after: i)
    }

    public func index(before i: Int) -> Int {
        sections.index(before: i)
    }

    // MARK: - RangeReplaceableCollection

    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
        where C: Collection, C.Element == SectionInfo {
            sections.replaceSubrange(subrange, with: newElements)
    }

    // MARK: - RandomAccessCollection Subscripts

    public subscript(index: Int) -> SectionInfo {
        get { sections[index] }
        set { sections[index] = newValue }
    }

    /// A view model structure used by `SSCollectionViewPresenter` to configure
    /// and render each section of the collection view.
    public struct SectionInfo: RandomAccessCollection, RangeReplaceableCollection, Hashable {
        private let uuid: UUID = UUID()
        // MARK: - Core Contents

        public var identifier: String?

        internal var items: [AnyBindingStore]
        internal var header: AnyBindingStore?
        internal var footer: AnyBindingStore?

        // MARK: - RandomAccessCollection

        public typealias Index = Int
        public typealias Element = AnyBindingStore

        public var startIndex: Int { items.startIndex }
        public var endIndex: Int { items.endIndex }

        // MARK: - FlowLayout Options

        public var sectionInset: UIEdgeInsets?
        public var minimumLineSpacing: CGFloat?
        public var minimumInteritemSpacing: CGFloat?

        // MARK: - Init.

        public init(
            items: [AnyBindingStore] = [],
            header: AnyBindingStore? = nil,
            footer: AnyBindingStore? = nil,
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

        // MARK: - RandomAccessCollection Methods

        public func index(after i: Int) -> Int {
            items.index(after: i)
        }

        public func index(before i: Int) -> Int {
            items.index(before: i)
        }

        // MARK: - RangeReplaceableCollection

        public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C)
            where C: Collection, C.Element == AnyBindingStore
        {
            items.replaceSubrange(subrange, with: newElements)
        }

        // MARK: - RandomAccessCollection Subscripts

        public subscript(index: Int) -> AnyBindingStore {
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
    }
}
