// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SSCollectionViewPresenter",
    platforms: [
        .iOS(.v12)
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
            from: "1.0.1"
        )
    ],
    targets: [
        .target(
            name: "SSCollectionViewPresenter",
            dependencies: [
                "SendingState"
            ]
        ),
        .testTarget(
            name: "SSCollectionViewPresenterTests",
            dependencies: ["SSCollectionViewPresenter"]
        )
    ]
)
