# SSCollectionViewPresenter

🎞️ Super Simple abstraction layer for building `UICollectionView`-based UIs with minimal boilerplate.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%2012-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Motivation

Implementing `UICollectionView` across various screens often involves repetitive, error-prone tasks — registering cells, configuring data sources and delegates, or adapting raw server responses to data models. As these tasks pile up screen after screen, the codebase becomes tedious to maintain, especially when each screen handles things a little differently.

The core issue is a lack of separation between rendering logic and interaction logic. Each screen ends up owning too much — it knows how to display data, how to respond to events, and how to talk to the rest of the app.

The design of this library was heavily inspired by [`pkh0225/CollectionViewAdapter`](https://github.com/pkh0225/CollectionViewAdapter), which solved exactly these problems in a way that felt immediately practical. Introducing a ViewModel as the single source of truth eliminated the data synchronization issues that tend to creep in when view controllers manage collection state directly. Having the adapter take full ownership of `UICollectionViewDataSource` and `UICollectionViewDelegate` meant that individual screens no longer needed to reimplement the same boilerplate — they simply bind to a ViewModel and react. And seeing real-world e-commerce features baked into the library made it clear just how much repetitive work a well-designed abstraction can eliminate in production codebases.

SSCollectionViewPresenter follows that same philosophy, while integrating [`SendingState`](https://github.com/dSunny90/SendingState) as its backbone. The presenter drives the UI through type-safe ViewModel binding, and events emitted by cells flow upward through a shared event channel — keeping UI code focused on rendering and interaction logic easy to trace.

## Philosophy

SSCollectionViewPresenter is built on a pragmatic take on Apple's MVC architecture:
- Lightweight business logic can remain in the `UIViewController`.
- For more complex interactions, an `Interactor` can be introduced to separate concerns.
- UI components like `UICollectionViewCell` can forward user interactions (buttons, gestures, toggles) to an `Interactor` or `UIViewController`.

---

## How It Works

You provide a `ViewModel` containing:
- A list of `SectionInfo`
- Each section has a list of `CellInfo` (and optional header/footer via `ReusableViewInfo`)

Then, simply bind the ViewModel to the presenter. The presenter handles:
- Drawing the correct section/cell
- Registering cells and reusable views
- Managing layout & display logic

There's no need to implement `UICollectionViewDataSource` manually.

---

## Key Features

<details>
<summary><b>Boilerplate-free UICollectionView setup</b></summary>

No need to write custom data sources and delegates repeatedly. The presenter takes full ownership of `UICollectionViewDataSource` and `UICollectionViewDelegate` — screens simply bind to a ViewModel and react.
</details>

<details>
<summary><b>Automatic cell/header/footer registration</b></summary>

Cells and reusable views are registered automatically using type-safe identifiers. NIB files are detected and loaded without any extra configuration.
</details>

<details>
<summary><b>Section layout control</b></summary>

Each section can carry its own insets, line spacing, interitem spacing, and column count — configurable either through the builder API or via direct assignment on `SectionInfo`.
</details>

<details>
<summary><b>Built-in RESTful API pagination</b></summary>

Tracks `page` and `hasNext` out of the box. Supports both append-only pagination via `extendViewModel` and structured page management via `loadPage` — including per-page replacement and removal.
</details>

<details>
<summary><b>Server-driven UI composition</b></summary>

Conforms to `ViewModelSectionRepresentable` and `ViewModelUnitRepresentable` to compose the UI based on a shared server-client contract. Section and item ordering is determined by the server response — no hardcoded layout decisions on the client side.
</details>

<details>
<summary><b>Infinite scrolling & auto-rolling</b></summary>

Smooth circular scroll behavior for banner carousels, with optional center-snapping and configurable auto-roll intervals.
</details>

<details>
<summary><b>Page lifecycle callbacks</b></summary>

Observe and respond to page-level events: `onPageWillAppear`, `onPageDidAppear`, `onPageWillDisappear`, `onPageDidDisappear`.
</details>

<details>
<summary><b>Drag & Drop reordering</b></summary>

Supports long-press drag reordering within the collection view. On iPad, external drag & drop is also supported — items can be dragged into or out of other apps using `NSItemProvider` and UTType-based filtering.
</details>

<details>
<summary><b>Diffable & traditional data source support</b></summary>

Switch between `UICollectionViewDiffableDataSource` and the traditional data source with a single parameter at setup time.
</details>

<details>
<summary><b>Flow layout & compositional layout</b></summary>

Full support for both `UICollectionViewFlowLayout` and `UICollectionViewCompositionalLayout`.
</details>

<details>
<summary><b>Re-exported dependency</b></summary>

`SendingState` is re-exported, so you can use `Configurable`, `EventForwardingProvider`, and other types without an extra import.
</details>

---

## Quick Start

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

## Guides

### Section Layout Options

Each section can carry its own layout properties — insets, spacing, and column count — either via direct assignment on `SectionInfo` or through the builder API.

**Using the builder (recommended):**

```swift
collectionView.ss.buildViewModel { builder in
    builder.section("productList") {
        builder.sectionInset(UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16))
        builder.minimumLineSpacing(10)
        builder.minimumInteritemSpacing(16)
        builder.gridColumnCount(2)
        builder.cells(products, cellType: ProductCell.self)
    }
}
```

**Using direct assignment:**

```swift
let section = SSCollectionViewModel.SectionInfo()
section.sectionInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
section.minimumLineSpacing = 10
section.minimumInteritemSpacing = 16
section.gridColumnCount = 2
```

Available layout properties:

| Property | Type | Description |
|---|---|---|
| `sectionInset` | `UIEdgeInsets?` | Padding around the section's items |
| `minimumLineSpacing` | `CGFloat?` | Minimum spacing between successive rows or columns |
| `minimumInteritemSpacing` | `CGFloat?` | Minimum spacing between items in the same row or column |
| `gridColumnCount` | `Int?` | Number of columns. `0` ignores section insets and stretches each item to full width. A positive value distributes items evenly across the row. |

---

### Cell Interaction & Event Handling

#### Simple actions with `actionClosure`

For straightforward interactions — a tap, a toggle — attach an `actionClosure` directly in the builder. The closure receives an `action` name and an optional `input` payload.

```swift
// Cell
builder.cells(products, cellType: ProductCell.self) { indexPath, cell, action, input in
    switch action {
    case "addToCart":
        addToCart(at: indexPath)
    default:
        break
    }
}

// Header / Footer
builder.header(headerData, viewType: SectionHeaderView.self) { section, view, action, input in
    switch action {
    case "more":
        showMore(for: section)
    default:
        break
    }
}
```

#### Complex actions with `EventForwarder` (SendingState)

When a cell or view emits multiple event types, carries typed payloads, or needs to share a single event channel across sections, conform to `EventForwardingProvider` from `SendingState` instead.

```swift
final class ProductCell: UICollectionViewCell, SSCollectionViewCellProtocol, EventForwardingProvider {
    // UI
    @IBOutlet weak var cartButton: UIButton!
    @IBOutlet weak var clipButton: UIButton!
    @IBOutlet weak var lensButton: UIButton!
    @IBOutlet weak var productDetailButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    // ...

    var configurer: (ProductCell, ProductModel) -> Void {
        { view, model in
            // configuration code
        }
    }

    var eventForwarder: EventForwardable {
        SenderGroup {
            EventForwarder(cartButton) { sender, ctx in
                ctx.control(.touchUpInside) { (state: ProductModel) in
                    [TestAction.cart(state.productId)]
                }
            }
            EventForwarder(clipButton) { sender, ctx in
                ctx.control(.touchUpInside) (state: ProductModel) {
                    [TestAction.clip(state.productId)]
                }
            }
            EventForwarder(lensButton) { sender, ctx in
                ctx.control(.touchUpInside) (state: ProductModel) {
                    [TestAction.aiSearch(state.productId)]
                }
            }
            EventForwarder(productDetailButton) { sender, ctx in
                ctx.control(.touchUpInside) (state: ProductModel) {
                    [TestAction.goProductDetail(state.productId)]
                }
            }
            EventForwarder(refreshButton) { sender, ctx in
                ctx.control(.touchUpInside) { [TestAction.refresh(sender.tag)] }
            }
        }
    }
}
```

Observe events at the view-controller level through the presenter's shared event channel.

> For full `EventForwardingProvider` usage, refer to the [`SendingState`](https://github.com/dSunny90/SendingState) documentation.

---

#### Handling delegate events inside cells

Cells can respond to delegate-level events by implementing optional methods from `SSCollectionViewCellProtocol`:

```swift
final class MyCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    // ...

    func didSelect(with input: MyModel?) {
        // Handle selection
    }

    func willDisplay(with input: MyModel?) {
        // Called just before the cell appears
    }

    func didEndDisplaying(with input: MyModel?) {
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

### Reconfiguring Items, Headers, and Footers

`reconfigureItem(_:at:)`, `reconfigureHeader(_:at:)`, and `reconfigureFooter(_:at:)` replace the underlying state (model) of a visible view and re-invoke its `configurer` in place — no full reload needed. Use this whenever only the data of an existing view has changed.

```swift
// Update a cell's state
let updated = ProductModel(id: "00000011", title: "Test Product", price: 30)
collectionView.ss.reconfigureItem(updated, at: indexPath)

// Update a header / footer
collectionView.ss.reconfigureHeader(SectionHeaderData(title: "New Event"), at: 0)
collectionView.ss.reconfigureFooter(FooterData(text: "More Events"), at: 0)
```

---

### Collapse & Expand Sections

`toggleSection(_:completion:)` flips the `isCollapsed` flag of the given section and triggers a data source update. The `completion` closure delivers the new collapsed state — use it to push updated state into any header or footer whose appearance depends on it (a chevron, a label, etc.).

```swift
collectionView.ss.toggleSection(sectionIndex) { [weak self] collapsed in
    guard let self = self else { return }
    let updated = SectionHeaderData(title: "Products", isExpanded: !collapsed)
    self.collectionView.ss.reconfigureHeader(updated, at: sectionIndex)
}
```

#### Triggering from an `actionClosure`

The `section` parameter passed into a header or footer `actionClosure` is the section index itself, so it can be forwarded directly to `toggleSection`:

```swift
builder.header(headerData, viewType: SectionHeaderView.self) { [weak self] section, view, action, input in
    guard let self = self else { return }
    switch action {
    case "toggle":
        guard let state = input as? SectionHeaderData else { return }
        self.collectionView.ss.toggleSection(section) { collapsed in            
            let updated = SectionHeaderData(title: state.title, isExpanded: !collapsed)
            self.collectionView.ss.reconfigureHeader(updated, at: section)
        }
    default:
        break
    }
}
```

#### Triggering from an `EventForwarder`

When using `EventForwardingProvider`, the handler receives no index by default. The view must embed its own position in the forwarded payload so the handler can pass it to `toggleSection`.

- **Headers / footers** — include `sectionIndex`
- **Cells** — include `indexPath`

```swift
// Header view — embed sectionIndex in the payload
final class SectionHeaderView: UICollectionReusableView, EventForwardingProvider {
    @IBOutlet weak var filterButton: UIButton!
    @IBOutlet weak var sortButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var collapseButton: UIButton!

    var configurer: (SectionHeaderView, SectionHeaderModel) -> Void {
        { view, model in
            view.titleLabel.text = model.title
            view.collapseButton.setImage(UIImage(named: "chevron_down"), for: .normal)
            view.collapseButton.setImage(UIImage(named: "chevron_right"), for: .selected)
            view.collapseButton.isSelected = model.isExpanded ? false : true 
        }
    }

    var eventForwarder: EventForwardable {
        SenderGroup {
            EventForwarder(filterButton) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.filter]
                }
            }
            EventForwarder(sortButton) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.sort]
                }
            }
            EventForwarder(searchButton) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.search]
                }
            }
            EventForwarder(closeButton) { sender, ctx in
                ctx.control(.touchUpInside) {
                    [TestAction.close]
                }
            }
            EventForwarder(collapseButton) { sender, ctx in
                ctx.control(.touchUpInside) { [weak self] in
                    guard let self, let state = self.ss.state() else { return [TestAction]() }
                    return [TestAction.toggle(self.sectionIndex, state)]
                }
            }
        }
    }
}

// Action handler (view controller or interactor)
final class TestStoreViewController: UIViewController, ActionHandlingProvider {
    @IBOutlet weak var collectionView: UICollectionView!

    // ...

    func handle(action: TestAction) {
        switch action {
        case .toggle(let sectionIndex):
            collectionView.ss.toggleSection(sectionIndex, state) { [weak self] collapsed in
                guard let self = self else { return }
                let newState = SectionHeaderModel(title: state.title, isExpanded: !collapsed)
                self.collectionView.ss.reconfigureHeader(newState, at: sectionIndex)
            }
        default:
            break
        }
    }
}
```
---

### Loading Next Page (Pagination)

`extendViewModel` is useful for simple append-only pagination. For more structured control — such as replacing or removing individual pages — use `loadPage` instead.

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

For typical RESTful APIs that return paginated responses, `loadPage` lets you **store** each page's sections **independently**. The presenter merges all stored pages into a single flat list internally — sections with the same identifier across pages are concatenated, while unnamed sections are simply appended.

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

### Server-Driven UI Composition

This pattern was born out of hands-on experience developing module units for `Template stores` at [SSG.COM](https://www.ssg.com). In that system, each page is composed of a server-defined list of sections — called templates — and each template contains an ordered set of UI modules called units. The server owns both the structure and the ordering of the page; the client simply renders whatever it receives, without hardcoding any layout decisions into the view controller. Working within that contract at production scale made the value of a clean, protocol-driven abstraction immediately obvious — and that experience shaped the design of this feature directly.

SSCollectionViewPresenter formalizes this pattern through two protocols:

- **`ViewModelSectionRepresentable`** — represents a single section returned by the server, carrying an optional `sectionId` and an ordered list of units.
- **`ViewModelUnitRepresentable`** — represents a single UI module within a section, identified by a `unitType` string and an associated `unitData` payload.

When the server and client share a contract that guarantees section and item ordering, the response can be passed directly to the builder without manual iteration:

```swift
collectionView.ss.buildViewModel { builder in
    builder.sections(
        result.sectionList,
        configureSection: { section, builder in
            guard let sectionId = section.sectionId else { return }
            switch sectionId {
            case "ProductList":
                builder.sectionInset(.init(top: 20, left: 15, bottom: 20, right: 15))
                builder.minimumLineSpacing(15)
            case "TripleItems":
                builder.sectionInset(.init(top: 20, left: 10, bottom: 20, right: 10))
                builder.minimumLineSpacing(10)
                builder.minimumInteritemSpacing(1)
            default:
                builder.sectionInset(.zero)
                builder.minimumLineSpacing(0)
                builder.minimumInteritemSpacing(0)
            }
        },
        configureUnit: { unit, builder in
            switch unit.unitType {
            case "SS_TOP_BANNER":
                guard let bannerList = unit.unitData as? [BannerModel] else { return }
                builder.cell(bannerList, cellType: TopBannerCell.self)
            case "SS_PRODUCT_LIST":
                guard let productList = unit.unitData as? [ProductModel] else { return }
                builder.cells(productList, cellType: ProductCell.self)
            case "SS_MY_FAVORITES":
                guard let myFavorites = unit.unitData as? MyFavoritesModel else { return }
                if let titleInfo = myFavorites.titleInfo {
                    builder.header(titleInfo, viewType: MyFavoriteHeaderView.self)
                }
                builder.cells(myFavorites.productList, cellType: ProductCell.self)
            default:
                break
            }
        }
    )
}
collectionView.reloadData()
```

`configureSection` runs first for each section — allowing layout properties to be applied before `configureUnit` adds the cells. Both closures receive the builder, so the full layout API remains available at every stage.

> **Tip — conforming to the protocols:**
> Define one conforming type per screen or API context, since each endpoint typically follows its own data contract. If two screens share the same structure but differ in layout rules, prefer subclassing over duplication. If `configureUnit` closures start to look repetitive across screens, extract the shared logic into a factory.
>
> If the server doesn't provide section identifiers and instead returns a nested array of units, decode the response as `[[any ViewModelUnitRepresentable]]` and initialize a conforming type per inner array — setting `sectionId` to `nil` or a derived index value.

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

> **`isInfinitePage` vs `isLooping`:** Both create a wrap-around effect, but they differ in feel. `isInfinitePage` duplicates content to produce seamless, continuous scrolling — ideal for banners where the transition should feel uninterrupted. `isLooping` snaps back to the first page explicitly, which can feel cleaner when the jump is intentional. Choose based on the UX you're after.

> **Requirements (flow layout):** This feature requires a single section with uniformly-sized items. For best results, avoid headers/footers and disable `isPagingEnabled` on the scroll view.

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

### Drag & Drop Reordering

Enable reordering with a single call:

```swift
collectionView.ss.setReorderEnabled(true)
```

To restrict which items can be dragged:

```swift
collectionView.ss.onCanDragItem { cellInfo in
    // Return false to prevent dragging that item
    return cellInfo.identifier != "pinned"
}
```

Observe reorder events before and after they apply:

```swift
collectionView.ss.onWillReorder { items in
    print("About to move: \(items.map { $0.indexPath })")
}

collectionView.ss.onDidReorder { items, destination in
    print("Moved to: \(destination)")
}
```

To customize the drag preview:

```swift
// Custom view
collectionView.ss.setDragPreviewProvider { cellInfo in
    let view = MyPreviewView()
    view.configure(with: cellInfo)
    return view
}

// Custom parameters (e.g. corner radius, shadow)
collectionView.ss.onDragPreviewParameters { indexPath in
    let params = UIDragPreviewParameters()
    params.visiblePath = UIBezierPath(roundedRect: .init(x: 0, y: 0, width: 120, height: 120), cornerRadius: 8)
    return params
}
```

#### External Drag & Drop (iPad)

On iPad, items can be dragged into or out of other apps. Supply an `NSItemProvider` for outgoing drags and register a handler for incoming drops:

```swift
// Outgoing — provide a payload for external drops
collectionView.ss.setDragItemProvider { cell, cellInfo in
    guard let text = cellInfo.data as? String else { return nil }
    return NSItemProvider(object: text as NSString)
}

// Incoming — specify accepted types and handle the drop
collectionView.ss.setAcceptedExternalDropTypeIdentifiers(
    [UTType.plainText.identifier]
)

collectionView.ss.onExternalDrop { value, indexPath in
    guard let text = value as? String else { return nil }
    return SSCollectionViewModel.CellInfo(data: text, cellType: MyCell.self)
}
```

---

## Advanced Setup

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
    .package(url: "https://github.com/dSunny90/SSCollectionViewPresenter", from: "1.0.0")
]
```
