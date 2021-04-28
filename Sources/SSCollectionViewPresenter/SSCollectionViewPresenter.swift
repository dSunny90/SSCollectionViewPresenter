//
//  SSCollectionViewPresenter.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 24.04.2021.
//

import UIKit

/// Simplifies configuring and managing a `UICollectionView` with a
/// `SSCollectionViewModel`.
///
/// `SSCollectionViewPresenter` bridges your view model with the collection view,
/// automatically handling data source and delegate methods. It provides an
/// easy way to bind cell and supplementary view data with minimal boilerplate.
public final class SSCollectionViewPresenter: NSObject {
    // MARK: - ViewModel

    /// The current view model backing the collection view.
    internal var viewModel: SSCollectionViewModel? {
        didSet {
            guard let viewModel = viewModel, let collectionView = collectionView else { return }
            for section in viewModel.sections {
                for item in section.items {
                    collectionView.registerCell(item.binderType)
                }
                if let header = section.header {
                    collectionView.registerHeader(header.binderType)
                }
                if let footer = section.footer {
                    collectionView.registerFooter(footer.binderType)
                }
            }
        }
    }

    // MARK: - Action Handling

    /// The action handler responsible for dispatching actions.
    internal var actionHandler: AnyActionHandlingProvider?

    // MARK: - Collection View Reference

    /// The collection view being managed by this presenter.
    private weak var collectionView: UICollectionView?

    // MARK: - Initialization

    public init(
        collectionView: UICollectionView,
        actionHandler: ActionHandlingProvider? = nil
    ) {
        self.collectionView = collectionView
        if let actionHandler = actionHandler {
            self.actionHandler = AnyActionHandlingProvider(actionHandler)
        }
        super.init()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerDefaultCell()
        collectionView.registerDefaultReusableViews(
            ofKind: UICollectionView.elementKindSectionHeader
        )
        collectionView.registerDefaultReusableViews(
            ofKind: UICollectionView.elementKindSectionFooter
        )
    }
}

// MARK: - UICollectionViewDataSource

extension SSCollectionViewPresenter: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let viewModel = viewModel else { return 0 }
        return viewModel.sections.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        guard let items = viewModel?[section].items else { return 0 }
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = viewModel?[indexPath.section].items[indexPath.item]
        else { return collectionView.dequeueDefaultCell(for: indexPath) }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: item.binderType),
            for: indexPath
        )

        item.apply(to: cell)

        if let actionHandler = actionHandler,
           let aCell = cell as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aCell)
        }

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        guard let section = viewModel?[indexPath.section]
        else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let item: AnyBindingStore?
        if kind == UICollectionView.elementKindSectionHeader {
            item = section.header
        } else if kind == UICollectionView.elementKindSectionFooter {
            item = section.footer
        } else {
            item = nil
        }

        guard let item = item else { return collectionView.dequeueDefaultSupplementaryView(ofKind: kind, for: indexPath) }

        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: String(describing: item.binderType),
            for: indexPath
        )

        item.apply(to: view)

        if let actionHandler = actionHandler,
           let aView = view as? (UIView & EventSendingProvider)
        {
            actionHandler.attach(to: aView)
        }

        return view
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SSCollectionViewPresenter: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let item = viewModel?[indexPath.section].items[indexPath.item],
              let itemSize = item.size(constrainedTo: collectionView.bounds.size)
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.itemSize
            } else {
                return .zero
            }
        }

        return itemSize
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               insetForSectionAt section: Int) -> UIEdgeInsets {
        guard let sectionInset = viewModel?[section].sectionInsets
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.sectionInset
            } else {
                return .zero
            }
        }

        return sectionInset
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        guard let lineSpacing = viewModel?[section].minimumLineSpacing
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.minimumLineSpacing
            } else {
                return 0
            }
        }

        return lineSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        guard let itemSpacing = viewModel?[section].minimumInteritemSpacing
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.minimumInteritemSpacing
            } else {
                return 0
            }
        }

        return itemSpacing
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let viewSize = viewModel?[section].header?.size(constrainedTo: collectionView.bounds.size)
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.headerReferenceSize
            } else {
                return .zero
            }
        }

        return viewSize
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForFooterInSection section: Int) -> CGSize {
        guard let viewSize = viewModel?[section].footer?.size(constrainedTo: collectionView.bounds.size)
        else {
            if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
                return flowLayout.footerReferenceSize
            } else {
                return .zero
            }
        }

        return viewSize
    }
}
