// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SSCollectionViewPresenter",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "SSCollectionViewPresenter",
            targets: ["SSCollectionViewPresenter"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/dSunny90/SendingState.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "SSCollectionViewPresenter",
            dependencies: [
                "SendingState"
            ],
            path: "Sources/SSCollectionViewPresenter"
        ),
        .testTarget(
            name: "SSCollectionViewPresenterTests",
            dependencies: ["SSCollectionViewPresenter"],
            path: "Tests/SSCollectionViewPresenterTests"
        )
    ]
)
