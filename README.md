# SSCollectionViewPresenter

🎞️ Super Simple abstraction layer for building `UICollectionView`-based UIs with minimal boilerplate.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%2012-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Motivation

Implementing `UICollectionView` across various screens often involves repetitive, error-prone tasks — registering cells, configuring data sources and delegates, or adapting raw server responses to data models. As these tasks pile up screen after screen, the codebase becomes tedious to maintain, especially when each screen handles things a little differently.

The core issue is a lack of separation between rendering logic and interaction logic. Each screen ends up owning too much — it knows how to display data, how to respond to events, and how to talk to the rest of the app. To address this, SSCollectionViewPresenter introduces a presenter layer that takes full ownership of the data source and delegate responsibilities. The screen simply binds to a ViewModel and reacts to it, with no knowledge of how that state was produced.

To enable clean ViewModel binding, I integrated my earlier [`SendingState`](https://github.com/dSunny90/SendingState) into `SSCollectionViewPresenter`. `SendingState` is the backbone of this approach: the presenter drives the UI entirely through type-safe ViewModel binding, while events emitted by lower-level components (cells) flow upward in a single, unidirectional stream. This keeps UI code focused on rendering and makes interaction logic predictable and easy to test.

## Philosophy

Built with a pragmatic take on Apple's MVC architecture:
- Lightweight business logic can remain in the `UIViewController`.
- For more complex interactions, an `Interactor` can be introduced to separate concerns.
- UI components like `UICollectionViewCell` can forward user interactions (buttons, gestures, toggles) to an `Interactor` or `UIViewController`.

---

## Key Features

- **Boilerplate-free UICollectionView setup** — No need to write custom data sources and delegates repeatedly.
- **Diffable & traditional data source support** — Switch modes based on your needs.
- **Flow layout & compositional layout** — Full support for both layout systems.
- **Automatic cell/header/footer registration** — Uses type-safe identifiers; NIB files are detected automatically.
- **Built-in RESTful API pagination** — Tracks `page` and `hasNext`, with seamless next-page requests.
- **Infinite scrolling for banners** — Smooth circular scroll behavior.
- **Auto-rolling support** — Automatically scrolls banners with a customizable interval.
- **Page lifecycle callbacks** — Observe and respond to page-level events like `onPageWillAppear`, `onPageDidAppear`, etc.
- **Re-exported dependency** — `SendingState` is re-exported, so you can use `Configurable`, `EventForwardingProvider`, and other types without an extra import.

## How It Works

You provide a `ViewModel` containing:
- A list of `SectionInfo`
- Each section has a list of `CellInfo` (and optional header/footer via `ReusableViewInfo`)

Then, simply bind the ViewModel to the presenter. The presenter handles:
- Drawing the correct section/cell
- Registering cells and reusable views
- Managing layout & display logic

You **don't** need to manually implement `UICollectionViewDataSource` anymore.

---

## Usage

### 1. Define Your Model

```swift
struct BannerData: Decodable {
    let id: String
    let title: String
    let imgUrl: String
}
```

### 2. Create a Custom Cell

Conform to `SSCollectionViewCellProtocol`, which inherits from `Configurable` (provided by `SendingState`).

```swift
final class BannerCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!

    static func size(with input: BannerData?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 100, height: 200)
    }

    var configurer: (BannerCell, BannerData) -> Void {
        { view, model in
            view.titleLabel.text = model.title
            view.imgView.loadWebImage(model.imgUrl)
        }
    }
}
```

### 3. Set Up in Your ViewController

```swift
final class HomeViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.ss.setupPresenter()

        let banners = [
            BannerData(id: "1", title: "Summer Sale", imgUrl: "https://your.image.url"),
            BannerData(id: "2", title: "Winter Deals", imgUrl: "https://your.image.url")
        ]

        // Option A: Manual construction
        let sectionInfo = SSCollectionViewModel.SectionInfo()
        for banner in banners {
            sectionInfo.appendCellInfo(banner, cellType: BannerCell.self)
        }
        let viewModel = SSCollectionViewModel(sections: [sectionInfo])
        collectionView.ss.setViewModel(with: viewModel)

        // Option B: Builder pattern
        collectionView.ss.buildViewModel { builder in
            builder.section {
                builder.cells(banners, cellType: BannerCell.self)
            }
        }

        collectionView.reloadData()
    }
}
```

---

### Interaction & Event Handling

**1. Sending events from cells**

If a cell needs to propagate internal events (e.g. button taps) to its parent, refer to the `eventForwarder` usage in [`SendingState`](https://github.com/dSunny90/SendingState).
Cells can conform to `EventForwardingProvider` to expose interactions like `touchUpInside`, `valueChanged`, or gesture recognizers.

**2. Handling delegate events inside cells**

Cells can respond to delegate-level events by implementing optional methods from `SSCollectionViewCellProtocol`:

```swift
final class MyCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    // ...

    func didSelect(with input: MyData?) {
        // Handle selection
    }

    func willDisplay(with input: MyData?) {
        // Called just before the cell appears
    }

    func didEndDisplaying(with input: MyData?) {
        // Called after the cell disappears
    }
}
```

Available lifecycle methods:

| Method | Description |
|---|---|
| `willDisplay(with:)` | Called before the view appears |
| `didEndDisplaying(with:)` | Called after the view disappears |
| `didHighlight(with:)` | Called on touch-down |
| `didUnhighlight(with:)` | Called on touch-up |
| `didSelect(with:)` | Called on selection |
| `didDeselect(with:)` | Called on deselection |

> `willDisplay` and `didEndDisplaying` are available on both cells and reusable views (headers/footers).

---

### Loading Next Page (Pagination)

If your collection view should load more data when the user scrolls near the end, use `onNextRequest`:

```swift
collectionView.ss.onNextRequest { [weak self] viewModel in
    guard let self = self else { return }
    NetworkingManager.fetchNextPage(current: viewModel.page) { result in
        guard case .success(let response) = result else { return }
        self.collectionView.ss.extendViewModel(
            page: response.page,
            hasNext: response.hasNext
        ) { builder in
            builder.section("productList") {
                builder.cells(response.products, cellType: ProductCell.self)
            }
        }
        self.collectionView.reloadData()
    }
}
```

`extendViewModel` merges by section identifier — if a section with the same ID exists, new items are appended to it. Otherwise, a new section is added.

#### Page-Based Data Management with `loadPage`

For typical RESTful APIs that return paginated responses, `loadPage` lets you store each page's sections independently. The presenter merges all stored pages into a single flat list internally — sections with the same identifier across pages are concatenated, while unnamed sections are simply appended.

`loadPage` accepts either an array of `SectionInfo` or a builder closure:

```swift
// Initial load
collectionView.ss.loadPage(0, hasNext: true) { builder in
    builder.section("banner") {
        builder.cells(banners, cellType: BannerCell.self)
    }
    builder.section("productList") {
        builder.cells(products, cellType: ProductCell.self)
    }
}
collectionView.reloadData()
```

Combine it with `onNextRequest` to handle pagination seamlessly:

```swift
collectionView.ss.onNextRequest { [weak self] viewModel in
    guard let self = self else { return }
    NetworkingManager.fetchNextPage(current: viewModel.page + 1) { result in
        guard case .success(let response) = result else { return }
        self.collectionView.ss.loadPage(response.page, hasNext: response.hasNext) { builder in
            builder.section("productList") {
                builder.cells(response.productList, cellType: ProductCell.self)
            }
        }
        self.collectionView.reloadData()
    }
}
```

Because each page is stored separately, you can replace or remove any individual page without affecting the rest:

```swift
// Replace page 2 with fresh data (e.g. after an item edit)
collectionView.ss.loadPage(2, hasNext: true) { builder in
    builder.section("productList") {
        builder.cells(updatedProducts, cellType: ProductCell.self)
    }
}

// Remove a specific page
collectionView.ss.removePage(2)

// Pull-to-refresh: clear everything and start over
var viewModel = collectionView.ss.getViewModel()
viewModel?.removeAllPages()
collectionView.ss.setViewModel(with: viewModel ?? SSCollectionViewModel())
```

You can also query page state directly on the view model:

| Property / Method | Description |
|---|---|
| `page` | The most recently loaded page number |
| `hasNext` | Whether more pages are available |
| `pageCount` | Number of stored pages |
| `hasPageData` | `true` if at least one page is stored |
| `sections(forPage:)` | Returns the sections for a specific page |
| `findPage(forSectionIdentifier:)` | Finds the latest page containing a given section ID |

> **Merge rules:** When multiple pages contain sections with the same `identifier`, their items are merged into one section in page order. Headers and footers from later pages take precedence. Sections without an identifier are never merged — they're always appended as separate sections.

---

### Infinite Scroll & Auto-Rolling

Enable infinite scrolling or auto-rolling banners with a single call:

```swift
// Center-aligned paging with infinite scroll and auto-rolling
collectionView.ss.setPagingEnabled(.init(
    isAlignCenter: true,
    isInfinitePage: true,
    isAutoRolling: true,
    autoRollingTimeInterval: 4.0
))
```

`PagingConfiguration` parameters:

| Parameter | Default | Description |
|---|---|---|
| `isEnabled` | `true` | Enables custom paging (replaces `UIScrollView.isPagingEnabled`) |
| `isAlignCenter` | `false` | Snaps the current page to the center of the viewport |
| `isLooping` | `false` | Wraps around when reaching either end |
| `isInfinitePage` | `false` | Enables infinite scrolling by duplicating content |
| `isAutoRolling` | `false` | Automatically scrolls at a fixed interval |
| `autoRollingTimeInterval` | `3.0` | Seconds between auto-scroll transitions |

> **Requirements:** This feature requires a single section with uniformly-sized items. For best results, avoid headers/footers and disable `isPagingEnabled` on the scroll view.

You can also control paging programmatically:

```swift
collectionView.ss.moveToNextPage()
collectionView.ss.moveToPreviousPage()
```

---

### Page Lifecycle Callbacks

Track which page a user is viewing — useful for analytics, journey maps, or triggering animations:

```swift
collectionView.ss.onPageWillAppear { collectionView, pageIndex in
    print("Page \(pageIndex) is about to appear")
}

collectionView.ss.onPageDidAppear { collectionView, pageIndex in
    print("Page \(pageIndex) appeared")
}

collectionView.ss.onPageWillDisappear { collectionView, pageIndex in
    print("Page \(pageIndex) is about to disappear")
}

collectionView.ss.onPageDidDisappear { collectionView, pageIndex in
    print("Page \(pageIndex) disappeared")
}
```

---

### ScrollView Delegate Forwarding

If you need to observe scroll events from outside the presenter:

```swift
collectionView.ss.setScrollViewDelegateProxy(self)
```

The presenter will forward `UIScrollViewDelegate` calls to the proxy.

---

### Diffable Data Source

To use the modern diffable data source (iOS 13+), pass `.diffable` when setting up:

```swift
collectionView.ss.setupPresenter(dataSourceMode: .diffable)

collectionView.ss.buildViewModel { builder in
    builder.section("main") {
        builder.cells(items, cellType: ItemCell.self)
    }
}

// Use applySnapshot instead of reloadData
collectionView.ss.applySnapshot(animated: true)
```

> When using diffable mode, call `applySnapshot(animated:)` instead of `reloadData()` to apply changes with optional animations.

---

### Compositional Layout

For more advanced layouts, use `.compositional` with `SSCompositionalLayoutSection` (iOS 13+):

```swift
let sections = [
    SSCompositionalLayoutSection(
        direction: .horizontal,
        columns: 1,
        height: 200,
        scrolling: .paging
    ),
    SSCompositionalLayoutSection(
        direction: .vertical,
        columns: 2,
        height: 150
    )
]

let config = SSCollectionViewPresenter.CompositionalLayoutConfig(sections: sections)
collectionView.ss.setupPresenter(layoutKind: .compositional(config))
```

`SSCompositionalLayoutSection` parameters:

| Parameter | Type | Description |
|---|---|---|
| `direction` | `UICollectionView.ScrollDirection` | `.horizontal` or `.vertical` |
| `columns` | `Int` | Number of columns (default: `1`) |
| `itemWidth` | `CGFloat?` | Fixed item width; if `nil`, auto-calculated from columns |
| `height` | `CGFloat` | Item height |
| `scrolling` | `ScrollingBehavior?` | Orthogonal scrolling behavior (`none`, `continuous`, `paging`, etc.) |

---

## Installation

SSCollectionViewPresenter is available via Swift Package Manager.

### Using Xcode:

1. Open your project in Xcode
2. Go to **File > Add Packages...**
3. Enter the URL:
```
https://github.com/dSunny90/SSCollectionViewPresenter
```
4. Select the version and finish

### Using Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/dSunny90/SSCollectionViewPresenter", from: "0.2.4")
]
```
