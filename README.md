# SSCollectionViewPresenter

🎞️ Super Simple abstraction layer for building `UICollectionView`-based UIs with minimal boilerplate.

[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/) ![Swift](https://img.shields.io/badge/Swift-5.7-orange.svg) ![Platform](https://img.shields.io/badge/platform-iOS%2012-brightgreen) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Motivation

Implementing `UICollectionView` across various screens often involves repetitive and error-prone tasks — registering cells, configuring data sources and delegates, or adapting raw server responses to data models. As these tasks repeat for every screen, development becomes tedious and error-prone, especially when handled inconsistently.

`SSCollectionViewPresenter` eliminates repetitive setup by introducing a structured, pattern-driven approach to managing collection views. The idea was inspired by [`pkh0225/CollectionViewAdapter`](https://github.com/pkh0225/CollectionViewAdapter), which served as a key reference. Following a similar philosophy, this library was developed to promote consistency and reusability by abstracting data into a unified ViewModel—allowing developers to focus more on meaningful UI and interactions, rather than boilerplate.

To deliver ViewModels cleanly, I integrated my earlier [`SendingState`](https://github.com/dSunny90/SendingState) into `SSCollectionViewPresenter`. `SendingState` is the backbone for this goal: the presenter handles presentation solely through type-safe ViewModel binding, while events emitted by lower-level components (cells) flow upward in a single, unidirectional stream. This keeps UI code focused on rendering, and interaction logic predictable and easy to test.

## Philosophy

Built with a pragmatic take on Apple's MVC architecture:
- Lightweight business logic can remain in the `UIViewController`.
- For more complex interactions, an `Interactor` can be introduced to separate concerns.
- UI components like `UICollectionViewCell` can forward user interactions (buttons, gestures, toggles) to an `Interactor` or `UIViewController`.

---

## Key Features

- **Boilerplate-free UICollectionView setup**: No need to write custom data sources and delegates repeatedly.
- **Diffable & traditional data source support**: Switch modes based on your needs.
- **Automatic cell/header/footer registration**: Using type-safe identifiers.
- **RESTful API pagination built-in**: Including `hasNext`, `page`, and seamless next-page requests.
- **Infinite scrolling for banners**: Smooth circular scroll behavior.
- **Auto-rolling support**: Automatically scrolls banners with a customizable interval.
- **Page lifecycle callbacks**: Easily observe and respond to page-level events like `pageWillAppear`, `pageDidAppear`, etc.

While working on SSG.COM, I realized recurring needs for features like pagination, infinite scrolling, and autoplay banners. These were built directly into the presenter to address real-world requirements — especially in shopping or content-heavy UI/UX environments like [SSG.COM](https://apps.apple.com/kr/app/id786135420), where such features are essential to delivering a seamless experience.

## How It Works

You provide a `ViewModel` containing:
- A list of `SectionInfo`
- Each section has a list of `CellInfo`

Then, simply bind the ViewModel to the presenter. The presenter handles:
- Drawing the correct section/cell
- Registering cells, reusable views
- Managing layout & display logic

You **don’t** need to manually implement `UICollectionViewDataSource` anymore.

## Customization

To use custom cells or reusable views:
- Conform to `SSCollectionViewCellProtocol` to configure cells.
- Conform to `SSCollectionReusableViewProtocol` for headers/footers.
- Use `EventForwardingProvider` in cells to emit user interactions.
- Handle forwarded events with `ActionHandlingProvider`.

This separation allows:
- One-way data flow
- Consistent UI behavior
- Clear interaction boundaries between views and business logic

## One-Way Data Flow

With `SSCollectionViewPresenter`, your data and interaction flow stays clean:
- ViewModel -> View (data binding)
- View -> Action (event forwarding)

This enforces unidirectional data flow, helping avoid messy two-way bindings or accidental state mutations.

## Recommended Setup

- Use with `UICollectionViewFlowLayout` for full feature support (infinite scroll, auto-rolling).
- Disable `isPagingEnabled` if you're using auto-rolling or infinite scroll features.
- For business-heavy views, extract logic to an `Interactor`.

## Example Use Cases

- Product listing banners
- Content sliders
- Content feeds using paginated REST APIs
- UI with a lot of reusable cell types 
- Implementing a **Journey Map**: Track which banners or pages a user has seen using `pageWillAppear` and `pageDidAppear` events

---

## Usage

```swift
// 1. Define your model (Server Data)
struct BannerData: Decodable {
    let id: String
    let title: String
    let imgUrl: String
}
// 2. Create your custom UICollectionViewCell
final class BannerCell: UICollectionViewCell, SSCollectionViewCellProtocol {
    static func size(with input: BannerData?, constrainedTo parentSize: CGSize?) -> CGSize? {
        return CGSize(width: parentSize?.width ?? 100, height: parentSize?.height ?? 100)
    }
    var configurer: (BannerCell, BannerData) -> Void {
        { view, model in
            view.titleLabel.text = model.title
            view.imgView.loadWebImage(model.imgUrl)
        }
    }
}
// 3. Define your viewModel
struct BannerCellModel: Boundable {
    var contentData: BannerData?
    var binderType: BannerCell.Type { BannerCell.self }
}
// 4. Setup in your UIViewController
final class HomeViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.ss.setupPresenter(layoutKind: .flow)

        // Provide data
        let banners = [
            BannerData(id: "1", title: "Summer Sale", imgUrl: "http://your.image.url"),
            BannerData(id: "2", title: "Winter Deals", imgUrl: "http://your.image.url")
        ]

        // For more complex or reusable data structures, consider extracting
        // the creation of SectionInfo, CellInfo, and ViewModel into a
        // separate helper method or builder function.
        let cellInfos = banners.map { SSCollectionViewModel.CellInfo(BannerCellModel(contentData: $0)) }
        let sectionInfo = SSCollectionViewModel.SectionInfo(items: cellInfos)
        let viewModel = SSCollectionViewModel(sections: [sectionInfo])

        // If you need load more data (Server Data hasNext == true)
        // viewModel.hasNext = serverData.hasNext

        collectionView.ss.setViewModel(with: viewModel)
        collectionView.reloadData()
    }
}
```

### Interaction & Event Handling

1. Forwarding events from cells
If a cell needs to propagate internal events (e.g. button taps) to its parent, refer to the eventForwarder usage in
 👉 [`SendingState`](https://github.com/dSunny90/SendingState)
Cells can conform to EventForwardingProvider to expose interactions like touchUpInside, valueChanged, or gesture recognizers.
2. Handling delegate events inside cells
When cells need to handle events like `didSelect` or `willDisplay` themselves, simply conform to `SSCollectionViewCellProtocol` and implement the desired methods.

### Loading Next Page (Pagination)

If your collection view should load more data when the user scrolls near the end, use the .nextRequest method to provide a handler:
```swift
collectionView.ss.nextRequest { viewModel in
    NetworkingManager.fetchNextPage(current: viewModel.page) { [weak self] result in
        guard let self = self else { return }
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

### Infinite Scroll & Auto-Rolling

If your layout requires an infinite scroll or auto-rolling banners, you can enable these features with a single method call:
```swift
// Infinite scroll
collectionView.ss.setInfinitePage()
// Auto-Rolling
collectionView.ss.setAutoRolling()
// Custom paging & align center
collectionView.ss.setPagingEnabled(true, isAlignCenter: true)
```

## Swift 6 Migration

> **Background.** In [`SendingState`](https://github.com/dSunny90/SendingState), Boundable now conforms to `Sendable`.  
> Therefore, any ViewModel you bind through `SSCollectionViewPresenter` **must be `Sendable`**.

### What this means for your ViewModels

- Struct/enum ViewModels (recommended): Prefer value types so `Sendable` is automatic.
- Class-based ViewModels: Either
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

## Installation

SSCollectionViewPresenter is available via Swift Package Manager.

### Using Xcode:

1. Open your project in Xcode
2. Go to File > Add Packages…
3. Enter the URL:  
```
https://github.com/dSunny90/SSCollectionViewPresenter
```
4. Select the version and finish

### Using Package.swift:
```swift
dependencies: [
    .package(url: "https://github.com/dSunny90/SSCollectionViewPresenter", from: "1.0.1")
]
```
