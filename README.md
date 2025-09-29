# SSCollectionViewPresenter

🎞️ Super Simple abstraction layer for building `UICollectionView`-based UIs with minimal boilerplate.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%2012-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Motivation

Implementing `UICollectionView` across various screens often involves repetitive and error-prone tasks — registering cells, configuring data sources and delegates, or adapting raw server responses to data models. As these tasks repeat for every screen, development becomes tedious and error-prone, especially when handled inconsistently.

`SSCollectionViewPresenter` eliminates repetitive setup by introducing a structured, pattern-driven approach to managing collection views. The idea was inspired by [`pkh0225/CollectionViewAdapter`](https://github.com/pkh0225/CollectionViewAdapter), which served as a key reference. Following a similar philosophy, this library was developed to promote consistency and reusability by abstracting data into a unified ViewModel — allowing developers to focus more on meaningful UI and interactions, rather than boilerplate.

To deliver ViewModels cleanly, I integrated my earlier [`SendingState`](https://github.com/dSunny90/SendingState) into `SSCollectionViewPresenter`. `SendingState` is the backbone for this goal: the presenter handles presentation solely through type-safe ViewModel binding, while events emitted by lower-level components (cells) flow upward in a single, unidirectional stream. This keeps UI code focused on rendering, and interaction logic predictable and easy to test.

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
- **Automatic cell/header/footer registration** — Using type-safe identifiers. NIB files are detected automatically.
- **RESTful API pagination built-in** — Including `page`, `hasNext`, and seamless next-page requests.
- **Infinite scrolling for banners** — Smooth circular scroll behavior.
- **Auto-rolling support** — Automatically scrolls banners with a customizable interval.
- **Page lifecycle callbacks** — Observe and respond to page-level events like `onPageWillAppear`, `onPageDidAppear`, etc.
- **Granular item CRUD** — Append, insert, update, and delete items by index path or section identifier.
- **Re-exported dependency** — `SendingState` is re-exported, so you can use `Boundable`, `EventForwardingProvider`, and other types without an extra import.

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

## Data Flow

```
  ┌─────────────────────────────────────────────────────────┐
  │                      Data Binding                       │
  │                                                         ▼
ViewModel ──▶ Presenter ──▶ UICollectionView ──▶ Cell / ReusableView
  ▲                                                         │
  │                    Event Forwarding                     │
  │                                                         ▼
  └──── ActionHandler ◀──── EventForwardingProvider ◀───────┘
```

With `SSCollectionViewPresenter`, your data and interaction flow stays clean:
- **ViewModel -> View** — data binding
- **View -> Action** — event forwarding

This enforces unidirectional data flow, helping avoid messy two-way bindings or accidental state mutations.

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

### 3. Define Your ViewModel

```swift
struct BannerCellModel: Boundable {
    var contentData: BannerData?
    var binderType: BannerCell.Type { BannerCell.self }
}
```

### 4. Set Up in Your ViewController

```swift
final class HomeViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.ss.setupPresenter(layoutKind: .flow)

        let banners = [
            BannerData(id: "1", title: "Summer Sale", imgUrl: "https://your.image.url"),
            BannerData(id: "2", title: "Winter Deals", imgUrl: "https://your.image.url")
        ]

        // Option A: Manual construction
        let cellInfos = banners.map { SSCollectionViewModel.CellInfo(BannerCellModel(contentData: $0)) }
        let sectionInfo = SSCollectionViewModel.SectionInfo(items: cellInfos)
        let viewModel = SSCollectionViewModel(sections: [sectionInfo])
        collectionView.ss.setViewModel(with: viewModel)

        // Option B: Builder pattern
        collectionView.ss.buildViewModel { builder in
            builder.section {
                builder.cells(models: banners, viewModel: BannerCellModel())
            }
        }

        collectionView.reloadData()
    }
}
```

---

### Builder Pattern with Header & Footer

The builder supports sections with identifiers, headers, and footers:

```swift
collectionView.ss.buildViewModel { builder in
    builder.section("eventBanner") {
        builder.cell(model: eventBanner, viewModel: EventBannerViewModel())
    }
    builder.section("productList") {
        builder.header(model: headerInfo, viewModel: ProductHeaderViewModel())
        builder.footer(model: footerInfo, viewModel: ProductFooterViewModel())
        builder.cells(models: products, viewModel: ProductViewModel())
    }
}
collectionView.reloadData()
```

### Header & Footer (Reusable Views)

Conform to `SSCollectionReusableViewProtocol`:

```swift
final class ProductHeader: UICollectionReusableView, SSCollectionReusableViewProtocol {
    @IBOutlet weak var titleLabel: UILabel!

    static func size(with input: HeaderData?, constrainedTo parentSize: CGSize?) -> CGSize? {
        CGSize(width: parentSize?.width ?? 0, height: 48)
    }

    var configurer: (ProductHeader, HeaderData) -> Void {
        { view, model in
            view.titleLabel.text = model.title
        }
    }
}

struct ProductHeaderViewModel: Boundable {
    var contentData: HeaderData?
    var binderType: ProductHeader.Type { ProductHeader.self }
}
```

---

### Interaction & Event Handling

**1. Forwarding events from cells**

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
collectionView.ss.onNextRequest { viewModel in
    NetworkingManager.fetchNextPage(current: viewModel.page) { [weak self] result in
        guard let self else { return }
        switch result {
        case .success(let newData):
            var currentViewModel = viewModel
            currentViewModel.append(contentsOf: makeSectionInfos(from: newData))
            currentViewModel.page = newData.page
            currentViewModel.hasNext = newData.hasNext
            self.collectionView.ss.setViewModel(with: currentViewModel)
            self.collectionView.reloadData()
        case .failure(let error):
            print("Failed to load next page:", error)
        }
    }
}
```

#### Using async/await

Since the closure gives you the current `SSCollectionViewModel`, you can bridge straight into structured concurrency:

```swift
collectionView.ss.onNextRequest { [weak self] viewModel in
    guard let self else { return }
    Task { @MainActor in
        do {
            let newData = try await NetworkingManager.fetchNextPage(current: viewModel.page)
            self.collectionView.ss.extendViewModel(
                page: newData.page,
                hasNext: newData.hasNext
            ) { builder in
                builder.section("productList") {
                    builder.cells(models: newData.products, viewModel: ProductViewModel())
                }
            }
            self.collectionView.reloadData()
        } catch {
            print("Failed to load next page:", error)
        }
    }
}
```

#### Using `extendViewModel` for Pagination

Instead of manually merging data, you can use `extendViewModel` to append items to an existing section by its identifier:

```swift
collectionView.ss.onNextRequest { [weak self] viewModel in
    guard let self else { return }
    NetworkingManager.fetchNextPage(current: viewModel.page) { result in
        guard case .success(let newData) = result else { return }

        self.collectionView.ss.extendViewModel(
            page: newData.page,
            hasNext: newData.hasNext
        ) { builder in
            builder.section("productList") {
                builder.cells(models: newData.products, viewModel: ProductViewModel())
            }
        }
        self.collectionView.reloadData()
    }
}
```

`extendViewModel` merges by section identifier — if a section with the same ID exists, new items are appended to it. Otherwise, a new section is added.

---

### Infinite Scroll & Auto-Rolling

Enable infinite scrolling or auto-rolling banners with a single call:

```swift
// Center-aligned paging with infinite scroll and auto-rolling
collectionView.ss.setPagingEnabled(
    isAlignCenter: true,
    isInfinitePage: true,
    isAutoRolling: true,
    autoRollingTimeInterval: 4.0
)
```

All paging parameters:

| Parameter | Default | Description |
|---|---|---|
| `isAlignCenter` | `false` | Snaps the current page to the center of the viewport |
| `isLooping` | `false` | Wraps around when reaching either end |
| `isInfinitePage` | `false` | Enables infinite scrolling by duplicating content |
| `isAutoRolling` | `false` | Automatically scrolls at a fixed interval |
| `autoRollingTimeInterval` | `3.0` | Seconds between auto-scroll transitions |

> **Requirements:** This feature supports only a single section with uniformly sized items. For best results, avoid headers/footers and disable `isPagingEnabled` on the scroll view.

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

### Diffable Data Source

To use the modern diffable data source (iOS 13+), pass `.diffable` when setting up:

```swift
collectionView.ss.setupPresenter(layoutKind: .flow, dataSourceMode: .diffable)

collectionView.ss.buildViewModel { builder in
    builder.section("main") {
        builder.cells(models: items, viewModel: ItemCellModel())
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

### Granular Item Operations

You can manipulate items directly without rebuilding the entire view model:

```swift
// Append
collectionView.ss.appendItem(cellInfo, toSection: 0)
collectionView.ss.appendItems(contentsOf: cellInfos, toSection: 0)
collectionView.ss.appendItemToLastSection(cellInfo)

// Append by section identifier
collectionView.ss.appendItem(cellInfo, firstSectionIdentifier: "productList")

// Insert
collectionView.ss.insertItem(cellInfo, at: IndexPath(item: 2, section: 0))

// Update
collectionView.ss.updateItem(cellInfo, at: IndexPath(item: 0, section: 0))
collectionView.ss.updateItem(cellInfo, atRow: 0, firstSectionIdentifier: "productList")

// Delete
collectionView.ss.deleteItem(at: IndexPath(item: 3, section: 0))
collectionView.ss.deleteAllItems(inSection: 0)
collectionView.ss.deleteAllItems(firstSectionIdentifier: "productList")

// Section operations
collectionView.ss.appendSection(newSection)
collectionView.ss.appendSections(contentsOf: newSections)
```

> After mutating the view model, call `reloadData()` or `applySnapshot(animated:)` to reflect the changes.

---

### ScrollView Delegate Forwarding

If you need to observe scroll events from outside the presenter:

```swift
collectionView.ss.setScrollViewDelegateProxy(self)
```

The presenter will forward `UIScrollViewDelegate` calls to the proxy.

---

## Swift 6 Migration

> **Background.** In [`SendingState`](https://github.com/dSunny90/SendingState), `Boundable` now conforms to `Sendable`.
> Therefore, any ViewModel you bind through `SSCollectionViewPresenter` **must be `Sendable`**.

### What this means for your ViewModels

- **Struct/enum ViewModels (recommended):** Prefer value types so `Sendable` conformance is automatic.
- **Class-based ViewModels:** Either
  - declare `@unchecked Sendable` and guard all mutable state (e.g., `NSLock`, `OSAllocatedUnfairLock`, or move shared state into an `actor`), or
  - refactor to a `struct`/`actor`.

> Keep binding data UI-free. Do not store UIKit objects inside `Sendable` ViewModels; apply UI on `@MainActor` in the view/cell.

### Minimal class example

```swift
public final class MyViewModel: @unchecked Sendable, Boundable {
    private let lock = NSLock()
    private var _contentData: MyModel?
    public var binderType: MyCell.Type { MyCell.self }

    public var contentData: MyModel? {
        get { lock.lock(); defer { lock.unlock() }; return _contentData }
        set { lock.lock(); _contentData = newValue; lock.unlock() }
    }
}
```

### Value type ViewModel

```swift
public struct MyViewModel: Boundable {
    public let contentData: MyModel?
    public var binderType: MyCell.Type { MyCell.self }
}
```

---

## Recommended Setup

- Use with `UICollectionViewFlowLayout` for full feature support (infinite scroll, auto-rolling, center alignment).
- Disable `isPagingEnabled` on the scroll view if you're using custom paging features.
- For business-heavy views, extract logic to an `Interactor`.

## Example Use Cases

- Product listing banners
- Content sliders
- Content feeds using paginated REST APIs
- UI with a lot of reusable cell types
- Implementing a **Journey Map**: Track which banners or pages a user has seen using `onPageWillAppear` and `onPageDidAppear`

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
    .package(url: "https://github.com/dSunny90/SSCollectionViewPresenter", .upToNextMajor(from: "1.1.0"))
]
```
