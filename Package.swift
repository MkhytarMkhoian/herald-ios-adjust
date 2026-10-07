// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "herald-ios-adjust",
    // Adjust's SDK builds for iOS only, so the tests run in the iOS Simulator, through Xcode.
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "HeraldAdjust", targets: ["HeraldAdjust"])
    ],
    dependencies: [
        .package(url: "https://github.com/MkhytarMkhoian/herald-ios", from: "1.0.0-beta.1"),
        .package(url: "https://github.com/adjust/ios_sdk", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "HeraldAdjust",
            dependencies: [
                .product(name: "HeraldCore", package: "herald-ios"),
                .product(name: "AdjustSdk", package: "ios_sdk"),
            ]
        ),
        .testTarget(
            name: "HeraldAdjustTests",
            dependencies: [
                "HeraldAdjust",
                .product(name: "HeraldTesting", package: "herald-ios"),
            ]
        ),
    ]
)
