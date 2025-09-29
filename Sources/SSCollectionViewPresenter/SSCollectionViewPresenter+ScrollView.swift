//
//  SSCollectionViewPresenter+ScrollView.swift
//  SSCollectionViewPresenter
//
//  Created by SunSoo Jeon on 31.10.2022.
//

import UIKit

// MARK: - UIScrollViewDelegate

extension SSCollectionViewPresenter: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidScroll?(scrollView)

        guard let collectionView = scrollView as? UICollectionView else { return }

        if isPagingEnabled {
            guard let section = viewModel?.sections.first, section.items.count > 0 else { return }
            let pageIndex = Int(round(collectionView.currentPage))
            let adjustedIndex = pageIndex % section.items.count
            if currentPageIndex != adjustedIndex {
                pageDidDisappearBlock?(collectionView, currentPageIndex)
                currentPageIndex = adjustedIndex
                pageWillAppearBlock?(collectionView, currentPageIndex)
            }
        }
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidZoom?(scrollView)
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewWillBeginDragging?(scrollView)
        guard let collectionView = scrollView as? UICollectionView else { return }

        if isAutoRolling {
            cancelAutoRolling()
        }

        if isPagingEnabled {
            pageWillDisappearBlock?(collectionView, currentPageIndex)
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollViewDelegateProxy?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)

        guard let collectionView = scrollView as? UICollectionView else { return }

        if isPagingEnabled {
            collectionView.remapTargetContentOffset(withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollViewDelegateProxy?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)

        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewWillBeginDecelerating?(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidEndDecelerating?(scrollView)

        guard let collectionView = scrollView as? UICollectionView else { return }

        if isAutoRolling {
            perform(#selector(self.runAutoRolling), with: nil, afterDelay: pagingTimeInterval)
        }

        // After scrolling fully stops, remap offset for infinite scroll once
        if isInfinitePage {
            collectionView.remapContentOffsetIfNeeded()
        }

        if isPagingEnabled {
            pageDidAppearBlock?(collectionView, currentPageIndex)
        }
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidEndScrollingAnimation?(scrollView)

        guard let collectionView = scrollView as? UICollectionView else { return }

        endProgrammaticScrollAnimating()

        // If there are queued page moves, perform them now as a single offset
        let offset = pendingPageOffset
        if offset != 0 {
            pendingPageOffset = 0
            isProgrammaticScrollAnimating = true
            collectionView.scrollPages(by: offset, animated: true)
            return
        }

        // After programmatic animation ends, remap offset for infinite scroll once
        if isInfinitePage {
            collectionView.remapContentOffsetIfNeeded()
        }

        // No more queued moves; schedule auto-rolling and notify page appearance
        if isAutoRolling {
            perform(#selector(self.runAutoRolling), with: nil, afterDelay: pagingTimeInterval)
        }

        if isPagingEnabled {
            pageDidAppearBlock?(collectionView, currentPageIndex)
        }
    }

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollViewDelegateProxy?.viewForZooming?(in: scrollView)
    }

    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollViewDelegateProxy?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollViewDelegateProxy?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return scrollViewDelegateProxy?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidScrollToTop?(scrollView)
    }

    public func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        scrollViewDelegateProxy?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}
